import Foundation
import GRDB

// MARK: - GRDB Record Types

struct ExpenseBillRecord: Codable, Sendable, Identifiable {
    var id: String
    var billingNo: String
    var transactionTime: String
    var modelCode: String?
    var modelProductName: String?
    var tokenResourceName: String?
    var apiUsage: Int
    var deductUsage: Int
    var tokenType: String?
    var costPrice: Double
    var timeWindowStart: String?
    var timeWindowEnd: String?
    var rawJson: String?
    var createdAt: String
}

extension ExpenseBillRecord: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "expense_bill"

    func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["billing_no"] = billingNo
        container["transaction_time"] = transactionTime
        container["model_code"] = modelCode
        container["model_product_name"] = modelProductName
        container["token_resource_name"] = tokenResourceName
        container["api_usage"] = apiUsage
        container["deduct_usage"] = deductUsage
        container["token_type"] = tokenType
        container["cost_price"] = costPrice
        container["time_window_start"] = timeWindowStart
        container["time_window_end"] = timeWindowEnd
        container["raw_json"] = rawJson
        container["created_at"] = createdAt
    }

    init(row: Row) {
        id = row["id"]
        billingNo = row["billing_no"]
        transactionTime = row["transaction_time"]
        modelCode = row["model_code"]
        modelProductName = row["model_product_name"]
        tokenResourceName = row["token_resource_name"]
        apiUsage = row["api_usage"]
        deductUsage = row["deduct_usage"]
        tokenType = row["token_type"]
        costPrice = row["cost_price"]
        timeWindowStart = row["time_window_start"]
        timeWindowEnd = row["time_window_end"]
        rawJson = row["raw_json"]
        createdAt = row["created_at"]
    }
}

struct SyncHistoryGRDBRecord: Codable, Sendable {
    var id: Int64?
    var syncType: String
    var billingMonth: String
    var syncTime: String
    var status: String
    var syncedCount: Int
    var failedCount: Int
    var totalCount: Int
    var message: String?
    var durationSeconds: Int
}

extension SyncHistoryGRDBRecord: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "sync_history"

    func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["sync_type"] = syncType
        container["billing_month"] = billingMonth
        container["sync_time"] = syncTime
        container["status"] = status
        container["synced_count"] = syncedCount
        container["failed_count"] = failedCount
        container["total_count"] = totalCount
        container["message"] = message
        container["duration_seconds"] = durationSeconds
    }

    init(row: Row) {
        id = row["id"]
        syncType = row["sync_type"]
        billingMonth = row["billing_month"]
        syncTime = row["sync_time"]
        status = row["status"]
        syncedCount = row["synced_count"]
        failedCount = row["failed_count"]
        totalCount = row["total_count"]
        message = row["message"]
        durationSeconds = row["duration_seconds"]
    }
}

struct MembershipTierLimitRecord: Codable, Sendable {
    var id: Int64?
    var tierName: String
    var periodHours: Int
    var callLimit: Int
}

extension MembershipTierLimitRecord: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "membership_tier_limit"

    func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["tier_name"] = tierName
        container["period_hours"] = periodHours
        container["call_limit"] = callLimit
    }

    init(row: Row) {
        id = row["id"]
        tierName = row["tier_name"]
        periodHours = row["period_hours"]
        callLimit = row["call_limit"]
    }
}

// MARK: - UsageLedgerStore

public actor UsageLedgerStore {
    private let dbQueue: DatabaseQueue
    private let logger: Logging

    public init(logger: Logging = AppLogger()) throws {
        self.logger = logger
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundleId = Bundle.main.bundleIdentifier ?? "com.yyh.UsageMonitorApp"
        let dbDirectory = appSupport.appendingPathComponent(bundleId, isDirectory: true)

        try fileManager.createDirectory(at: dbDirectory, withIntermediateDirectories: true)
        let dbURL = dbDirectory.appendingPathComponent("usage_ledger.sqlite")
        dbQueue = try DatabaseQueue(path: dbURL.path)
        try Self.performMigration(dbQueue: dbQueue)
    }

    public init(inMemory logger: Logging = AppLogger()) throws {
        self.logger = logger
        dbQueue = try DatabaseQueue()
        try Self.performMigration(dbQueue: dbQueue)
    }

    // MARK: - Schema Migration

    private static func performMigration(dbQueue: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()
        migrator.eraseDatabaseOnSchemaChange = true

        migrator.registerMigration("v1_create_expense_bill") { db in
            try db.create(table: "expense_bill") { t in
                t.column("id", .text).primaryKey()
                t.column("billing_no", .text).notNull().unique()
                t.column("transaction_time", .text).notNull()
                t.column("model_code", .text)
                t.column("model_product_name", .text)
                t.column("token_resource_name", .text)
                t.column("api_usage", .integer).notNull().defaults(to: 0)
                t.column("deduct_usage", .integer).notNull().defaults(to: 0)
                t.column("token_type", .text)
                t.column("cost_price", .double).notNull().defaults(to: 0)
                t.column("time_window_start", .text)
                t.column("time_window_end", .text)
                t.column("raw_json", .text)
                t.column("created_at", .text).notNull().defaults(to: "datetime('now','localtime')")
            }
            try db.create(index: "idx_bill_transaction_time", on: "expense_bill", columns: ["transaction_time"])
            try db.create(index: "idx_bill_billing_no", on: "expense_bill", columns: ["billing_no"], options: .unique)
        }

        migrator.registerMigration("v1_create_sync_history") { db in
            try db.create(table: "sync_history") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("sync_type", .text).notNull()
                t.column("billing_month", .text).notNull()
                t.column("sync_time", .text).notNull().defaults(to: "datetime('now','localtime')")
                t.column("status", .text).notNull()
                t.column("synced_count", .integer).notNull().defaults(to: 0)
                t.column("failed_count", .integer).notNull().defaults(to: 0)
                t.column("total_count", .integer).notNull().defaults(to: 0)
                t.column("message", .text)
                t.column("duration_seconds", .integer).notNull().defaults(to: 0)
            }
        }

        migrator.registerMigration("v1_create_membership_tier") { db in
            try db.create(table: "membership_tier_limit") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("tier_name", .text).notNull().unique()
                t.column("period_hours", .integer).notNull().defaults(to: 5)
                t.column("call_limit", .integer).notNull()
            }
            let tiers: [(String, Int, Int)] = [
                ("GLM Coding Lite", 5, 2400),
                ("GLM Coding Pro", 5, 12000),
                ("GLM Coding Max", 5, 48000)
            ]
            for (name, hours, limit) in tiers {
                var record = MembershipTierLimitRecord(id: nil, tierName: name, periodHours: hours, callLimit: limit)
                try record.insert(db)
            }
        }

        try migrator.migrate(dbQueue)
    }

    // MARK: - Write Operations

    func insertBill(_ record: ExpenseBillRecord) throws -> Bool {
        try dbQueue.write { db in
            var mutable = record
            try mutable.insert(db)
            return true
        }
    }

    func insertBills(_ records: [ExpenseBillRecord]) throws -> (synced: Int, skipped: Int) {
        var synced = 0
        var skipped = 0
        try dbQueue.write { db in
            for record in records {
                var mutable = record
                do {
                    try mutable.insert(db)
                    synced += 1
                } catch let error as DatabaseError where error.resultCode == .SQLITE_CONSTRAINT {
                    skipped += 1
                }
            }
        }
        return (synced, skipped)
    }

    public func deleteAllBills() throws -> Int {
        try dbQueue.write { db in
            let count = try ExpenseBillRecord.fetchCount(db)
            try ExpenseBillRecord.deleteAll(db)
            return count
        }
    }

    func insertSyncHistory(_ record: SyncHistoryGRDBRecord) throws {
        try dbQueue.write { db in
            var mutable = record
            try mutable.insert(db)
        }
    }

    // MARK: - Query Operations

    func totalBillCount() throws -> Int {
        try dbQueue.read { db in
            try ExpenseBillRecord.fetchCount(db)
        }
    }

    func hasBillsInMonth(_ billingMonth: String) throws -> Bool {
        let startDate = "\(billingMonth)-01 00:00:00"
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        f.locale = Locale(identifier: "en_US_POSIX")
        guard let date = f.date(from: billingMonth) else { return false }
        guard let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: date) else { return false }
        let endDate = Self.dateFormatter.string(from: nextMonth)

        return try dbQueue.read { db in
            let count = try Int.fetchOne(db, sql: """
                SELECT COUNT(*) FROM expense_bill
                WHERE transaction_time >= ? AND transaction_time < ?
                """, arguments: [startDate, endDate])
            return (count ?? 0) > 0
        }
    }

    func latestTransactionTime() throws -> String? {
        try dbQueue.read { db in
            try String.fetchOne(db, sql: """
                SELECT transaction_time FROM expense_bill WHERE transaction_time IS NOT NULL ORDER BY transaction_time DESC LIMIT 1
                """)
        }
    }

    func currentMembershipTier() throws -> String? {
        try dbQueue.read { db in
            try String.fetchOne(db, sql: """
                SELECT token_resource_name FROM expense_bill
                WHERE token_resource_name IS NOT NULL
                ORDER BY transaction_time DESC LIMIT 1
                """)
        }
    }

    func recentApiUsage(hours: Int) throws -> Int {
        let timeStr = timeString(hoursAgo: hours)
        return try dbQueue.read { db in
            let result = try Int.fetchOne(db, sql: """
                SELECT COALESCE(SUM(api_usage), 0) FROM expense_bill WHERE transaction_time >= ?
                """, arguments: [timeStr])
            return result ?? 0
        }
    }

    func recentDeductUsage(hours: Int) throws -> Int {
        let timeStr = timeString(hoursAgo: hours)
        return try dbQueue.read { db in
            let result = try Int.fetchOne(db, sql: """
                SELECT COALESCE(SUM(deduct_usage), 0) FROM expense_bill WHERE transaction_time >= ?
                """, arguments: [timeStr])
            return result ?? 0
        }
    }

    func recentTotalCost(hours: Int) throws -> Double {
        let timeStr = timeString(hoursAgo: hours)
        return try dbQueue.read { db in
            let result = try Double.fetchOne(db, sql: """
                SELECT COALESCE(SUM(cost_price / 1000.0 * deduct_usage), 0) FROM expense_bill WHERE transaction_time >= ?
                """, arguments: [timeStr])
            return result ?? 0
        }
    }

    func usageByTimeRange(startTime: String, endTime: String) throws -> (callCount: Int, tokenUsage: Int, totalCost: Double) {
        try dbQueue.read { db in
            let calls = try Int.fetchOne(db, sql: """
                SELECT COALESCE(SUM(api_usage), 0) FROM expense_bill WHERE transaction_time >= ? AND transaction_time < ?
                """, arguments: [startTime, endTime]) ?? 0

            let tokens = try Int.fetchOne(db, sql: """
                SELECT COALESCE(SUM(deduct_usage), 0) FROM expense_bill WHERE transaction_time >= ? AND transaction_time < ?
                """, arguments: [startTime, endTime]) ?? 0

            let cost = try Double.fetchOne(db, sql: """
                SELECT COALESCE(SUM(cost_price / 1000.0 * deduct_usage), 0) FROM expense_bill WHERE transaction_time >= ? AND transaction_time < ?
                """, arguments: [startTime, endTime]) ?? 0

            return (calls, tokens, cost)
        }
    }

    func hourlyGrowthRate() throws -> Double {
        let now = Date()
        let currentHourStart = now.startOfHour
        let previousHourStart = currentHourStart.addingTimeInterval(-3600)
        let previousHourEnd = currentHourStart.addingTimeInterval(-0.001)

        let currentUsage = try recentDeductUsage(from: currentHourStart)
        let previousUsage = try deductUsageByRange(start: previousHourStart, end: previousHourEnd)

        if previousUsage > 0 {
            return Double(currentUsage - previousUsage) / Double(previousUsage) * 100.0
        } else if currentUsage > 0 {
            return 100.0
        }
        return 0
    }

    func getMembershipLimit(tierName: String) throws -> MembershipTierLimitRecord? {
        try dbQueue.read { db in
            let all = try MembershipTierLimitRecord.fetchAll(db)
                .sorted { $0.callLimit < $1.callLimit }

            for record in all where tierName == record.tierName {
                return record
            }
            for record in all where tierName.contains(record.tierName) {
                return record
            }
            return all.first { $0.tierName == "GLM Coding Pro" } ?? all.first
        }
    }

    // MARK: - Breakdown Queries

    func tokenBreakdown(startTime: String, endTime: String) throws -> TokenBreakdown {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT
                    token_type,
                    COALESCE(SUM(deduct_usage), 0) AS tokens
                FROM expense_bill
                WHERE transaction_time >= ? AND transaction_time < ?
                GROUP BY token_type
                """, arguments: [startTime, endTime])

            var input: Int = 0
            var output: Int = 0
            var cacheHit: Int = 0
            for row in rows {
                let tokenType: String = row["token_type"] ?? ""
                let tokens: Int = row["tokens"] ?? 0
                if tokenType.contains("输入") {
                    input += tokens
                } else if tokenType.contains("输出") {
                    output += tokens
                } else if tokenType.contains("缓存") {
                    cacheHit += tokens
                }
            }
            return TokenBreakdown(inputTokens: input, outputTokens: output, cacheHitTokens: cacheHit)
        }
    }

    func hourlyUsageBreakdown(startTime: String, endTime: String) throws -> [HourlyUsageRecord] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT
                    strftime('%Y-%m-%d %H:00', transaction_time) AS hour,
                    COALESCE(SUM(api_usage), 0) AS calls,
                    COALESCE(SUM(deduct_usage), 0) AS tokens,
                    COALESCE(SUM(cost_price / 1000.0 * deduct_usage), 0) AS cost
                FROM expense_bill
                WHERE transaction_time >= ? AND transaction_time < ?
                GROUP BY hour
                ORDER BY hour
                """, arguments: [startTime, endTime])

            return rows.map { row in
                HourlyUsageRecord(
                    hour: row["hour"] ?? "",
                    calls: row["calls"] ?? 0,
                    tokens: row["tokens"] ?? 0,
                    cost: row["cost"] ?? 0
                )
            }
        }
    }

    func dailyUsageBreakdown(startTime: String, endTime: String) throws -> [DailyUsageRecord] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT
                    DATE(transaction_time) AS day,
                    COALESCE(SUM(api_usage), 0) AS calls,
                    COALESCE(SUM(deduct_usage), 0) AS tokens,
                    COALESCE(SUM(cost_price / 1000.0 * deduct_usage), 0) AS cost
                FROM expense_bill
                WHERE transaction_time >= ? AND transaction_time < ?
                GROUP BY DATE(transaction_time)
                ORDER BY day
                """, arguments: [startTime, endTime])

            return rows.map { row in
                DailyUsageRecord(
                    day: row["day"] ?? "",
                    calls: row["calls"] ?? 0,
                    tokens: row["tokens"] ?? 0,
                    cost: row["cost"] ?? 0
                )
            }
        }
    }

    func productBreakdown(startTime: String, endTime: String) throws -> [ProductUsageRecord] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT
                    COALESCE(model_product_name, 'Unknown') AS product,
                    COALESCE(SUM(api_usage), 0) AS calls,
                    COALESCE(SUM(deduct_usage), 0) AS tokens
                FROM expense_bill
                WHERE transaction_time >= ? AND transaction_time < ?
                GROUP BY product
                ORDER BY tokens DESC
                """, arguments: [startTime, endTime])

            return rows.map { row in
                ProductUsageRecord(
                    product: row["product"] ?? "Unknown",
                    calls: row["calls"] ?? 0,
                    tokens: row["tokens"] ?? 0
                )
            }
        }
    }

    // MARK: - Private Helpers

    private func timeString(hoursAgo: Int) -> String {
        let date = Date().addingTimeInterval(-Double(hoursAgo * 3600))
        return Self.dateFormatter.string(from: date)
    }

    private func recentDeductUsage(from startDate: Date) throws -> Int {
        let timeStr = Self.dateFormatter.string(from: startDate)
        return try dbQueue.read { db in
            try Int.fetchOne(db, sql: """
                SELECT COALESCE(SUM(deduct_usage), 0) FROM expense_bill WHERE transaction_time >= ?
                """, arguments: [timeStr]) ?? 0
        }
    }

    private func deductUsageByRange(start: Date, end: Date) throws -> Int {
        let startStr = Self.dateFormatter.string(from: start)
        let endStr = Self.dateFormatter.string(from: end)
        return try dbQueue.read { db in
            try Int.fetchOne(db, sql: """
                SELECT COALESCE(SUM(deduct_usage), 0) FROM expense_bill WHERE transaction_time >= ? AND transaction_time < ?
                """, arguments: [startStr, endStr]) ?? 0
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}

// MARK: - Date Extension

extension Date {
    var startOfHour: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: self)
        return calendar.date(from: components) ?? self
    }
}
