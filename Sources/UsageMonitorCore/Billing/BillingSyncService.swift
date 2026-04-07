import Foundation
import GRDB

public protocol BillingSyncServiceProtocol: Sendable {
    func fullSync(billingMonth: String) async throws -> SyncResult
    func incrementalSync(billingMonth: String) async throws -> SyncResult
    func autoSync(billingMonth: String) async throws -> SyncResult
    func currentSyncState() -> SyncState
}

public struct SyncResult: Equatable, Sendable {
    public let success: Bool
    public let total: Int
    public let synced: Int
    public let skipped: Int
    public let failed: Int
    public let durationSeconds: Int
    public let error: String?

    public init(success: Bool, total: Int = 0, synced: Int = 0, skipped: Int = 0, failed: Int = 0, durationSeconds: Int = 0, error: String? = nil) {
        self.success = success
        self.total = total
        self.synced = synced
        self.skipped = skipped
        self.failed = failed
        self.durationSeconds = durationSeconds
        self.error = error
    }
}

public final class BillingSyncService: BillingSyncServiceProtocol, @unchecked Sendable {
    private let apiClient: BillingAPIClientProtocol
    private let ledgerStore: UsageLedgerStore
    private let logger: Logging
    private let dateFormatter: DateFormatter
    private let lock = NSLock()

    /// Called on the sync service's thread whenever sync state changes.
    /// The receiver should dispatch to MainActor as needed.
    public var onSyncStateChange: (@Sendable (SyncState) -> Void)?

    private var _syncState: SyncState = SyncState(
        isSyncing: false,
        stage: .idle,
        progress: 0,
        lastSyncTime: nil,
        lastSyncCount: 0,
        lastError: nil,
        totalBillsInDB: 0,
        latestTransactionTime: nil
    )

    /// Thread-safe check whether a sync is currently running.
    private var isSyncing: Bool {
        lock.withLock { _syncState.isSyncing }
    }

    /// Thread-safe set of syncing flag.
    private func setSyncing(_ value: Bool) {
        lock.withLock { _syncState.isSyncing = value }
    }

    public init(
        apiClient: BillingAPIClientProtocol,
        ledgerStore: UsageLedgerStore,
        logger: Logging = AppLogger()
    ) {
        self.apiClient = apiClient
        self.ledgerStore = ledgerStore
        self.logger = logger
        self.dateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd HH:mm:ss"
            f.locale = Locale(identifier: "en_US_POSIX")
            return f
        }()
    }

    public func fullSync(billingMonth: String) async throws -> SyncResult {
        guard !isSyncing else {
            throw UsageMonitorError.apiError("Sync already in progress")
        }

        setSyncing(true)
        updateSyncState { $0.stage = .clearing; $0.progress = 0; $0.currentBillingMonth = billingMonth }
        let startTime = Date()

        do {
            let deletedCount = try await ledgerStore.deleteAllBills()
            logger.debug("Cleared \(deletedCount) existing bills")

            updateSyncState { $0.stage = .fetching; $0.progress = 0.1; $0.fetchedCount = 0; $0.expectedTotal = nil }
            let bills = try await fetchAllBillsWithProgress(billingMonth: billingMonth, pageSize: 100)

            if bills.isEmpty {
                updateSyncState { $0.stage = .completed; $0.progress = 1.0; $0.isSyncing = false; $0.lastError = nil; $0.currentBillingMonth = nil; $0.fetchedCount = 0; $0.expectedTotal = nil }
                try await recordSyncHistory(syncType: "full", billingMonth: billingMonth, status: "success", synced: 0, failed: 0, total: 0, duration: Date().timeIntervalSince(startTime), message: "No data")
                return SyncResult(success: true, total: 0)
            }

            updateSyncState { $0.stage = .saving; $0.progress = 0.5 }
            let records = bills.map { transformToRecord($0) }
            let (synced, skipped) = try await ledgerStore.insertBills(records)

            let duration = Date().timeIntervalSince(startTime)
            let totalCount = try await ledgerStore.totalBillCount()
            let latestTx = try await ledgerStore.latestTransactionTime()

            updateSyncState {
                $0.stage = .completed
                $0.progress = 1.0
                $0.isSyncing = false
                $0.lastSyncTime = Date()
                $0.lastSyncCount = synced
                $0.totalBillsInDB = totalCount
                $0.latestTransactionTime = Self.parseDate(latestTx)
                $0.lastError = nil
                $0.currentBillingMonth = nil
                $0.fetchedCount = 0
                $0.expectedTotal = nil
            }

            try await recordSyncHistory(syncType: "full", billingMonth: billingMonth, status: "success", synced: synced, failed: 0, total: bills.count, duration: duration)

            return SyncResult(success: true, total: bills.count, synced: synced, skipped: skipped, durationSeconds: Int(duration))
        } catch let error as DatabaseError where error.resultCode == .SQLITE_CONSTRAINT {
            logger.debug("Billing sync: constraint skipped during full sync (expected)")
            if let count = try? await ledgerStore.totalBillCount() {
                _syncState.totalBillsInDB = count
            }
            updateSyncState { $0.stage = .completed; $0.progress = 1.0; $0.isSyncing = false; $0.lastSyncTime = Date(); $0.lastError = nil; $0.currentBillingMonth = nil }
            return SyncResult(success: true, total: 0, skipped: 0)
        } catch {
            updateSyncState { $0.stage = .failed; $0.isSyncing = false; $0.lastError = error.localizedDescription; $0.currentBillingMonth = nil }
            throw error
        }
    }

    public func incrementalSync(billingMonth: String) async throws -> SyncResult {
        guard !isSyncing else {
            throw UsageMonitorError.apiError("Sync already in progress")
        }

        guard let latestTime = try await ledgerStore.latestTransactionTime() else {
            return try await fullSync(billingMonth: billingMonth)
        }

        setSyncing(true)
        updateSyncState { $0.stage = .fetching; $0.progress = 0.1; $0.currentBillingMonth = billingMonth; $0.fetchedCount = 0; $0.expectedTotal = nil }
        let startTime = Date()

        do {
            guard let latestDate = Self.parseDate(latestTime) else {
                return try await fullSync(billingMonth: billingMonth)
            }
            var newBills: [BillRow] = []
            var pageNum = 1
            let pageSize = 100
            var fetchedSoFar = 0
            var shouldStop = false

            while !shouldStop {
                let envelope = try await apiClient.fetchBills(billingMonth: billingMonth, pageNum: pageNum, pageSize: pageSize)
                guard let rows = envelope.rows, !rows.isEmpty else { break }

                if pageNum == 1, let total = envelope.total {
                    updateSyncState { $0.expectedTotal = total }
                }
                fetchedSoFar += rows.count
                updateSyncState { $0.fetchedCount = fetchedSoFar }

                for row in rows {
                    let parsedTime = BillRow.extractTransactionTime(billingNo: row.billingNo, customerId: row.customerId)
                    guard let parsedTime else { continue }

                    if parsedTime <= latestDate {
                        shouldStop = true
                        continue
                    }
                    if !shouldStop {
                        newBills.append(row)
                    }
                }

                if !shouldStop && rows.count == pageSize {
                    pageNum += 1
                } else {
                    break
                }
            }

            if newBills.isEmpty {
                let totalCount = try await ledgerStore.totalBillCount()
                updateSyncState { $0.stage = .completed; $0.progress = 1.0; $0.isSyncing = false; $0.lastSyncTime = Date(); $0.totalBillsInDB = totalCount; $0.lastError = nil; $0.currentBillingMonth = nil }
                try await recordSyncHistory(syncType: "incremental", billingMonth: billingMonth, status: "success", synced: 0, failed: 0, total: 0, duration: Date().timeIntervalSince(startTime), message: "No new data")
                return SyncResult(success: true, total: 0)
            }

            let records = newBills.map { transformToRecord($0) }
            let (synced, skipped) = try await ledgerStore.insertBills(records)

            let duration = Date().timeIntervalSince(startTime)
            let totalCount = try await ledgerStore.totalBillCount()
            let latestTx = try await ledgerStore.latestTransactionTime()

            updateSyncState {
                $0.stage = .completed
                $0.progress = 1.0
                $0.isSyncing = false
                $0.lastSyncTime = Date()
                $0.lastSyncCount = synced
                $0.totalBillsInDB = totalCount
                $0.latestTransactionTime = Self.parseDate(latestTx)
                $0.lastError = nil
                $0.currentBillingMonth = nil
            }

            try await recordSyncHistory(syncType: "incremental", billingMonth: billingMonth, status: "success", synced: synced, failed: 0, total: newBills.count, duration: duration)

            return SyncResult(success: true, total: newBills.count, synced: synced, skipped: skipped, durationSeconds: Int(duration))
        } catch let error as DatabaseError where error.resultCode == .SQLITE_CONSTRAINT {
            logger.debug("Billing sync: constraint skipped during incremental sync")
            let totalCount = try await ledgerStore.totalBillCount()
            updateSyncState { $0.stage = .completed; $0.progress = 1.0; $0.isSyncing = false; $0.lastSyncTime = Date(); $0.totalBillsInDB = totalCount; $0.lastError = nil; $0.currentBillingMonth = nil }
            return SyncResult(success: true, total: 0, skipped: 0)
        } catch {
            updateSyncState { $0.stage = .failed; $0.isSyncing = false; $0.lastError = error.localizedDescription; $0.currentBillingMonth = nil }
            try? await recordSyncHistory(syncType: "incremental", billingMonth: billingMonth, status: "failed", synced: 0, failed: 0, total: 0, duration: Date().timeIntervalSince(startTime), message: error.localizedDescription)
            throw error
        }
    }

    public func autoSync(billingMonth: String) async throws -> SyncResult {
        let billCount = try await ledgerStore.totalBillCount()

        // Current month: full sync if empty, incremental if has data
        let currentResult: SyncResult
        if billCount == 0 {
            currentResult = try await fullSync(billingMonth: billingMonth)
        } else {
            currentResult = try await incrementalSync(billingMonth: billingMonth)
        }

        // Previous month: only fetch if DB has no records for that month
        let prevMonth = Self.previousMonth(billingMonth: billingMonth)
        guard prevMonth != billingMonth else { return currentResult }

        let hasPrevData = (try? await ledgerStore.hasBillsInMonth(prevMonth)) ?? false
        if !hasPrevData {
            let prevResult = try await syncMonthDedupOnly(billingMonth: prevMonth)
            return SyncResult(
                success: currentResult.success && prevResult.success,
                total: currentResult.total + prevResult.total,
                synced: currentResult.synced + prevResult.synced,
                skipped: currentResult.skipped + prevResult.skipped,
                failed: currentResult.failed + prevResult.failed,
                durationSeconds: currentResult.durationSeconds + prevResult.durationSeconds
            )
        }

        return currentResult
    }

    /// Fetch all bills for a month and insert with dedup (UNIQUE constraint on billing_no).
    /// Does NOT clear the DB and does NOT depend on global latestTransactionTime.
    private func syncMonthDedupOnly(billingMonth: String) async throws -> SyncResult {
        setSyncing(true)
        let startTime = Date()

        do {
            updateSyncState { $0.stage = .fetching; $0.progress = 0.3; $0.currentBillingMonth = billingMonth; $0.fetchedCount = 0; $0.expectedTotal = nil }
            let bills = try await fetchAllBillsWithProgress(billingMonth: billingMonth, pageSize: 100)

            if bills.isEmpty {
                return SyncResult(success: true, total: 0, durationSeconds: Int(Date().timeIntervalSince(startTime)))
            }

            updateSyncState { $0.stage = .saving; $0.progress = 0.6 }
            let records = bills.map { transformToRecord($0) }
            let (synced, skipped) = try await ledgerStore.insertBills(records)

            let duration = Date().timeIntervalSince(startTime)
            let totalCount = try await ledgerStore.totalBillCount()

            updateSyncState {
                $0.stage = .completed
                $0.progress = 1.0
                $0.isSyncing = false
                $0.totalBillsInDB = totalCount
                $0.lastError = nil
                $0.currentBillingMonth = nil
                $0.fetchedCount = 0
                $0.expectedTotal = nil
            }

            try await recordSyncHistory(
                syncType: "dedup", billingMonth: billingMonth,
                status: "success", synced: synced, failed: 0,
                total: bills.count, duration: duration
            )

            return SyncResult(
                success: true, total: bills.count, synced: synced,
                skipped: skipped, durationSeconds: Int(duration)
            )
        } catch {
            updateSyncState { $0.stage = .failed; $0.isSyncing = false; $0.lastError = error.localizedDescription; $0.currentBillingMonth = nil }
            try? await recordSyncHistory(
                syncType: "dedup", billingMonth: billingMonth,
                status: "failed", synced: 0, failed: 0,
                total: 0, duration: Date().timeIntervalSince(startTime),
                message: error.localizedDescription
            )
            throw error
        }
    }

    public func currentSyncState() -> SyncState {
        _syncState
    }

    // MARK: - Private

    /// Paginated bill fetch that updates syncState.fetchedCount / expectedTotal after each page.
    private func fetchAllBillsWithProgress(billingMonth: String, pageSize: Int) async throws -> [BillRow] {
        var allRows: [BillRow] = []
        var pageNum = 1
        var seenBillingNos = Set<String>()
        var fetchedSoFar = 0

        while true {
            let envelope = try await apiClient.fetchBills(billingMonth: billingMonth, pageNum: pageNum, pageSize: pageSize)
            guard let rows = envelope.rows, !rows.isEmpty else { break }

            // Set expected total from first page
            if pageNum == 1, let total = envelope.total {
                updateSyncState { $0.expectedTotal = total }
            }

            for row in rows {
                if let billingNo = row.billingNo, !billingNo.isEmpty {
                    guard seenBillingNos.insert(billingNo).inserted else { continue }
                }
                allRows.append(row)
            }

            fetchedSoFar += rows.count
            updateSyncState { $0.fetchedCount = fetchedSoFar }

            if let total = envelope.total, fetchedSoFar >= total {
                break
            }
            if rows.count < pageSize {
                break
            }
            pageNum += 1
            try await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000...2_000_000_000))
        }

        return allRows
    }

    private func transformToRecord(_ row: BillRow) -> ExpenseBillRecord {
        let transactionDate = BillRow.extractTransactionTime(billingNo: row.billingNo, customerId: row.customerId)
        let transactionTimeStr = transactionDate.map { dateFormatter.string(from: $0) } ?? ""
        let (twStart, twEnd) = BillRow.splitTimeWindow(row.timeWindow)
        let now = dateFormatter.string(from: Date())

        return ExpenseBillRecord(
            id: UUID().uuidString,
            billingNo: row.billingNo ?? "",
            transactionTime: transactionTimeStr,
            modelCode: row.modelCode,
            modelProductName: row.modelProductName,
            tokenResourceName: row.tokenResourceName,
            apiUsage: row.apiUsage ?? 0,
            deductUsage: row.deductUsage ?? 0,
            tokenType: row.tokenType,
            costPrice: row.costPrice ?? 0,
            timeWindowStart: twStart,
            timeWindowEnd: twEnd,
            rawJson: nil,
            createdAt: now
        )
    }

    private func recordSyncHistory(
        syncType: String,
        billingMonth: String,
        status: String,
        synced: Int,
        failed: Int,
        total: Int,
        duration: TimeInterval,
        message: String? = nil
    ) async throws {
        let now = dateFormatter.string(from: Date())
        let record = SyncHistoryGRDBRecord(
            id: nil,
            syncType: syncType,
            billingMonth: billingMonth,
            syncTime: now,
            status: status,
            syncedCount: synced,
            failedCount: failed,
            totalCount: total,
            message: message,
            durationSeconds: Int(duration)
        )
        try await ledgerStore.insertSyncHistory(record)
    }

    private func updateSyncState(_ update: (inout SyncState) -> Void) {
        lock.lock()
        update(&_syncState)
        let state = _syncState
        lock.unlock()
        onSyncStateChange?(state)
    }

    private static func parseDate(_ string: String?) -> Date? {
        guard let string else { return nil }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.date(from: string)
    }

    private static func previousMonth(billingMonth: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        f.locale = Locale(identifier: "en_US_POSIX")
        guard let date = f.date(from: billingMonth) else { return billingMonth }
        let prev = Calendar.current.date(byAdding: .month, value: -1, to: date) ?? date
        return f.string(from: prev)
    }
}
