import Combine
import Foundation

public struct DashboardHeaderMetadataItem: Equatable, Sendable {
    public let title: String
    public let value: String
    public let symbolName: String

    public init(title: String, value: String, symbolName: String) {
        self.title = title
        self.value = value
        self.symbolName = symbolName
    }
}

public struct QuotaCardDisplayModel: Identifiable, Equatable, Sendable {
    public let id: String
    public let language: AppLanguage
    public let title: String
    public let usedText: String
    public let totalText: String
    public let remainingText: String
    public let percentageText: String
    public let percentageSeverity: QuotaPercentageSeverity
    public let resetText: String
    public let progress: Double
    public let usageDetails: [MCPToolUsageDetail]
    public let statusText: String?

    public init(id: String, language: AppLanguage, title: String, usedText: String, totalText: String, remainingText: String, percentageText: String, percentageSeverity: QuotaPercentageSeverity, resetText: String, progress: Double, usageDetails: [MCPToolUsageDetail], statusText: String?) {
        self.id = id
        self.language = language
        self.title = title
        self.usedText = usedText
        self.totalText = totalText
        self.remainingText = remainingText
        self.percentageText = percentageText
        self.percentageSeverity = percentageSeverity
        self.resetText = resetText
        self.progress = progress
        self.usageDetails = usageDetails
        self.statusText = statusText
    }
}

@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public private(set) var snapshot: DashboardSnapshot?
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var lastRefreshTimeText = AppStrings.never(language: .english)
    @Published public private(set) var menuBarSummaryText = ""
    @Published public private(set) var billingStats: BillingStatsSnapshot?
    @Published public private(set) var syncState: SyncState = .idle
    @Published public private(set) var showFiveHourQuota: Bool
    @Published public private(set) var showWeeklyQuota: Bool
    @Published public private(set) var showMCPQuota: Bool
    @Published public private(set) var showBillingStats: Bool

    private let dashboardService: DashboardServicing
    private let settingsStore: SettingsStoreProtocol
    private let logger: Logging
    private var billingSyncService: BillingSyncServiceProtocol?
    private var aggregationService: UsageAggregationServiceProtocol?
    private var billingCoordinator: BillingSyncCoordinator?
    private var timer: Timer?
    private var refreshTask: Task<Void, Never>?

    public init(
        dashboardService: DashboardServicing,
        settingsStore: SettingsStoreProtocol,
        logger: Logging = AppLogger()
    ) {
        self.dashboardService = dashboardService
        self.settingsStore = settingsStore
        self.logger = logger
        self.showFiveHourQuota = settingsStore.showFiveHourQuota
        self.showWeeklyQuota = settingsStore.showWeeklyQuota
        self.showMCPQuota = settingsStore.showMCPQuota
        self.showBillingStats = settingsStore.showBillingStats
    }

    public func configureBillingServices(
        syncService: BillingSyncServiceProtocol,
        aggregationService: UsageAggregationServiceProtocol
    ) {
        self.billingSyncService = syncService
        self.aggregationService = aggregationService
        self.billingCoordinator = BillingSyncCoordinator()

        if let concrete = syncService as? BillingSyncService {
            concrete.onSyncStateChange = { [weak self] state in
                Task { @MainActor [weak self] in
                    self?.syncState = state
                    // Reload billing stats when sync finishes so UI reflects fresh data
                    if state.stage == .completed || state.stage == .failed {
                        await self?.reloadBillingStats()
                    }
                }
            }
        }
    }

    /// Cancels any in-flight billing sync. Call when API key changes.
    public func cancelBillingSync() async {
        await billingCoordinator?.cancelAndReset()
    }

    /// Reset all dashboard data to empty state. Call before refresh after clearing local data.
    public func resetDashboard() {
        snapshot = nil
        billingStats = nil
        errorMessage = nil
        syncState = .idle
    }

    /// Reload billing stats from the aggregation service and update UI.
    private func reloadBillingStats() async {
        let stats = await Self.loadBillingStats(
            aggregationService: aggregationService,
            syncService: billingSyncService
        )
        billingStats = stats
        refreshPresentationTexts()
    }

    public func refresh() async {
        guard refreshTask == nil else { return }

        isLoading = true
        errorMessage = nil
        let task = Task { [dashboardService, billingSyncService, aggregationService, logger, billingCoordinator] in
            do {
                // 1. Quota refresh — this is what the user sees immediately
                let snapshot = try await dashboardService.refreshDashboard()

                // 2. Billing sync — single-flight via coordinator.
                //    If a sync is already running, this awaits it (no duplicate).
                //    Failure here should NOT block the dashboard or show an error.
                //    UI update is handled by onSyncStateChange callback.
                if let billingCoordinator, let billingSyncService {
                    Task { [billingCoordinator, billingSyncService, logger] in
                        do {
                            _ = try await billingCoordinator.sync {
                                try await Self.performBillingSync(syncService: billingSyncService)
                            }
                        } catch is CancellationError {
                            logger.debug("Billing sync cancelled (API key changed)")
                        } catch {
                            logger.debug("Background billing sync error: \(error.localizedDescription)")
                        }
                    }
                }

                // 3. Update UI with quota results immediately
                let stats = await Self.loadBillingStats(
                    aggregationService: aggregationService,
                    syncService: billingSyncService
                )

                await MainActor.run {
                    self.snapshot = snapshot
                    if let stats { self.billingStats = stats }
                    self.refreshPresentationTexts()
                    self.isLoading = false
                    self.refreshTask = nil
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.refreshPresentationTexts()
                    self.isLoading = false
                    self.refreshTask = nil
                }
                logger.error(error.localizedDescription)
            }
        }
        refreshTask = task
        await task.value
    }

    private static func performBillingSync(
        syncService: BillingSyncServiceProtocol
    ) async throws -> SyncResult {
        let billingMonth = currentBillingMonth()
        return try await syncService.autoSync(billingMonth: billingMonth)
    }

    private static func loadBillingStats(
        aggregationService: UsageAggregationServiceProtocol?,
        syncService: BillingSyncServiceProtocol?
    ) async -> BillingStatsSnapshot? {
        guard let aggregationService else { return nil }
        do {
            let allStats = try await aggregationService.allWindowStats()
            let tier = try await aggregationService.currentMembershipTier()
            let state = syncService?.currentSyncState() ?? .idle

            return BillingStatsSnapshot(
                membershipTier: tier ?? "Unknown",
                fiveHour: allStats.first { $0.window == .fiveHour } ?? .empty,
                oneDay: allStats.first { $0.window == .oneDay } ?? .empty,
                oneWeek: allStats.first { $0.window == .oneWeek } ?? .empty,
                oneMonth: allStats.first { $0.window == .oneMonth } ?? .empty,
                syncState: state
            )
        } catch {
            return nil
        }
    }

    private static func currentBillingMonth() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }

    public func loadWeeklyDetail() async throws -> UsageDetailSnapshot {
        try await loadDetail(for: .oneWeek)
    }

    public func loadDetail(for window: TimeWindow) async throws -> UsageDetailSnapshot {
        guard let aggregationService else {
            throw NSError(domain: "DashboardViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Billing services not configured"])
        }
        return try await aggregationService.detail(for: window)
    }

    public func configureAutoRefresh() {
        timer?.invalidate()
        let interval = max(settingsStore.refreshInterval, 30)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { await self?.refresh() }
        }
    }

    public func applySummaryVisibility() {
        showFiveHourQuota = settingsStore.showFiveHourQuota
        showWeeklyQuota = settingsStore.showWeeklyQuota
        showMCPQuota = settingsStore.showMCPQuota
        showBillingStats = settingsStore.showBillingStats
        refreshPresentationTexts()
    }

    public var planNameText: String {
        snapshot?.subscription?.planName ?? AppStrings.noSubscription(language: currentLanguage)
    }

    public var currentLanguage: AppLanguage {
        settingsStore.selectedLanguage
    }

    public var subscriptionStatusText: String {
        SubscriptionStatusFormatter.displayText(for: snapshot?.subscription?.status)
    }

    public var renewalText: String {
        DateFormatting.string(from: snapshot?.subscription?.nextRenewal, language: currentLanguage)
    }

    public var headerMetadataItems: [DashboardHeaderMetadataItem] {
        [
            DashboardHeaderMetadataItem(
                title: AppStrings.nextRenewal(language: currentLanguage),
                value: renewalText,
                symbolName: "arrow.clockwise.circle"
            ),
            DashboardHeaderMetadataItem(
                title: AppStrings.lastRefresh(language: currentLanguage),
                value: lastRefreshTimeText,
                symbolName: "clock"
            )
        ]
    }

    public var quotaCards: [QuotaCardDisplayModel] {
        [
            cardDisplay(
                id: "five-hour",
                title: AppStrings.fiveHourUsage(language: currentLanguage),
                quota: snapshot?.quotas.fiveHourQuota,
                missing: "5-hour quota not available"
            ),
            cardDisplay(
                id: "weekly",
                title: AppStrings.weeklyUsage(language: currentLanguage),
                quota: snapshot?.quotas.weeklyQuota,
                missing: "Weekly quota not available"
            ),
            cardDisplay(
                id: "mcp-monthly",
                title: AppStrings.mcpMonthlyUsage(language: currentLanguage),
                quota: snapshot?.quotas.mcpMonthlyQuota,
                missing: "MCP monthly quota not available"
            )
        ]
    }

    public var visibleQuotaCards: [QuotaCardDisplayModel] {
        quotaCards.filter { card in
            switch card.id {
            case "five-hour": return showFiveHourQuota
            case "weekly": return showWeeklyQuota
            case "mcp-monthly": return showMCPQuota
            default: return true
            }
        }
    }

    public func copyDebugInfo() -> String {
        let diagnostics = snapshot?.quotas.diagnostics.map {
            let metadata = $0.metadata
                .sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: ", ")
            return metadata.isEmpty ? "\($0.bucket.rawValue): \($0.entrySummary)" : "\($0.bucket.rawValue): \($0.entrySummary) [\(metadata)]"
        }.joined(separator: "\n") ?? "No quota diagnostics"

        let billingSection: String
        if let billing = billingStats {
            billingSection = """
            Billing Tier: \(billing.membershipTier)
            Sync: \(syncState.stage.rawValue), Bills: \(syncState.totalBillsInDB)
            5h: \(billing.fiveHour.callCount) calls, \(billing.fiveHour.tokenUsage) tokens, \(String(format: "%.4f", billing.fiveHour.totalCost)) CNY
            1d: \(billing.oneDay.callCount) calls, \(billing.oneDay.tokenUsage) tokens
            1w: \(billing.oneWeek.callCount) calls, \(billing.oneWeek.tokenUsage) tokens
            1m: \(billing.oneMonth.callCount) calls, \(billing.oneMonth.tokenUsage) tokens
            """
        } else {
            billingSection = "Billing: Not configured"
        }

        return """
        Host: \(settingsStore.baseURLString)
        Plan: \(snapshot?.subscription?.planName ?? "Unavailable")
        Refreshed: \(lastRefreshTimeText)
        Error: \(errorMessage ?? "None")
        Summary: \(menuBarSummaryText)
        Diagnostics:
        \(diagnostics)
        \(billingSection)
        """
    }

    private func cardDisplay<T: QuotaSnapshotProtocol>(id: String, title: String, quota: T?, missing: String) -> QuotaCardDisplayModel {
        guard let quota else {
            return QuotaCardDisplayModel(
                id: id,
                language: currentLanguage,
                title: title,
                usedText: "--",
                totalText: "--",
                remainingText: "--",
                percentageText: "--",
                percentageSeverity: .good,
                resetText: AppStrings.unavailable(language: currentLanguage),
                progress: 0,
                usageDetails: [],
                statusText: missing
            )
        }

        return QuotaCardDisplayModel(
            id: id,
            language: currentLanguage,
            title: title,
                usedText: countText(for: quota.used),
                totalText: countText(for: quota.limit),
                remainingText: countText(for: quota.remaining),
                percentageText: QuotaFormatter.percentage(quota.percentage),
                percentageSeverity: QuotaPercentageStyling.severity(for: quota.percentage),
                resetText: DateFormatting.string(from: quota.nextResetTime, language: currentLanguage),
                progress: min(max(quota.percentage / 100, 0), 1),
                usageDetails: quota.usageDetails,
                statusText: nil
        )
    }

    private func countText(for value: Double) -> String {
        value > 0 ? QuotaFormatter.format(value) : "--"
    }

    private func refreshPresentationTexts() {
        lastRefreshTimeText = snapshot.map { DateFormatting.string(from: $0.refreshedAt, language: currentLanguage) } ?? AppStrings.never(language: currentLanguage)
        menuBarSummaryText = settingsStore.showCompactSummary ? SummaryTextBuilder.makeSummary(from: snapshot, options: settingsStore.summaryDisplayOptions) : ""
    }
}
