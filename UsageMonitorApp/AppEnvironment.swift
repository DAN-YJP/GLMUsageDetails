import AppKit
import Combine
import Foundation
import UsageMonitorCore

@MainActor
final class AppEnvironment {
    let settingsStore: UserDefaultsSettingsStore
    let apiKeyStore: LocalObfuscatedAPIKeyStore
    let apiClient: UsageMonitorAPIClient
    let dashboardViewModel: DashboardViewModel
    let settingsViewModel: SettingsViewModel
    let logger: AppLogger
    var closeDashboardHandler: (() -> Void)?
    var openSettingsHandler: (() -> Void)?
    var openWeeklyDetailHandler: ((TimeWindow) -> Void)?

    init() {
        let settingsStore = UserDefaultsSettingsStore()
        let apiKeyStore = LocalObfuscatedAPIKeyStore()
        let logger = AppLogger(isEnabled: true)
        let apiClient = UsageMonitorAPIClient(
            configurationProvider: settingsStore,
            apiKeyProvider: apiKeyStore,
            headerBuilder: BearerAuthorizationHeaderBuilder(),
            logger: logger
        )

        self.settingsStore = settingsStore
        self.apiKeyStore = apiKeyStore
        self.apiClient = apiClient
        self.dashboardViewModel = DashboardViewModel(
            dashboardService: apiClient,
            settingsStore: settingsStore,
            logger: logger
        )
        self.settingsViewModel = SettingsViewModel(
            settingsStore: settingsStore,
            apiKeyStore: apiKeyStore,
            connectionTester: apiClient,
            logger: logger
        )
        self.logger = logger

        configureBillingServices()
    }

    private func configureBillingServices() {
        do {
            let ledgerStore = try UsageLedgerStore(logger: logger)
            let billingAPIClient = BillingAPIClient(
                apiKeyProvider: apiKeyStore,
                logger: logger
            )
            let syncService = BillingSyncService(
                apiClient: billingAPIClient,
                ledgerStore: ledgerStore,
                logger: logger
            )
            let aggregationService = UsageAggregationService(ledgerStore: ledgerStore)
            dashboardViewModel.configureBillingServices(
                syncService: syncService,
                aggregationService: aggregationService
            )
            settingsViewModel.onClearBillingData = { [weak self] in
                guard let self else { return }
                do {
                    // Cancel any in-flight billing sync before clearing data
                    await self.dashboardViewModel.cancelBillingSync()
                    let count = try await ledgerStore.deleteAllBills()
                    self.logger.debug("Cleared \(count) billing records")
                    await self.dashboardViewModel.refresh()
                } catch {
                    self.logger.error("Failed to clear billing data: \(error.localizedDescription)")
                }
            }
        } catch {
            logger.error("Failed to initialize billing services: \(error.localizedDescription)")
        }
    }

    func performInitialRefreshIfPossible() {
        dashboardViewModel.configureAutoRefresh()
        dashboardViewModel.applySummaryVisibility()

        if let apiKey = try? apiKeyStore.loadAPIKey(), !apiKey.isEmpty {
            Task { await dashboardViewModel.refresh() }
        } else {
            openSettings()
        }
    }

    func openSettings() {
        closeDashboardHandler?()
        let openSettingsHandler = openSettingsHandler
        Task { @MainActor in
            openSettingsHandler?()
        }
    }

    func openWeeklyDetail(for window: TimeWindow) {
        closeDashboardHandler?()
        let handler = openWeeklyDetailHandler
        Task { @MainActor in
            handler?(window)
        }
    }

    func copyDebugInfo(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func refreshNow() {
        Task { await dashboardViewModel.refresh() }
    }

    func syncSettingsChanges() {
        dashboardViewModel.configureAutoRefresh()
        dashboardViewModel.applySummaryVisibility()
        applyAppearance(settingsStore.themePreference)
    }

    func saveSettingsAndRefresh() {
        settingsViewModel.save()
        syncSettingsChanges()
        // Cancel in-flight billing sync on settings save (covers API key change)
        Task {
            await dashboardViewModel.cancelBillingSync()
            await dashboardViewModel.refresh()
        }
    }

    func persistSettingsWithoutFeedback() {
        settingsViewModel.saveSilently()
        syncSettingsChanges()
    }

    func clearLocalData() {
        syncSettingsChanges()
        dashboardViewModel.resetDashboard()
        applyAppearance(settingsStore.themePreference)
        Task { await dashboardViewModel.refresh() }
    }

    private func applyAppearance(_ theme: AppTheme) {
        switch theme {
        case .system: NSApp.appearance = nil
        case .light: NSApp.appearance = NSAppearance(named: .aqua)
        case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
}
