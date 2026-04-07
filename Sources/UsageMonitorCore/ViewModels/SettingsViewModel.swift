import Foundation

public enum KeyValidationState: Equatable {
    case idle
    case validating
    case valid
    case invalid(String)

    var isIdle: Bool { self == .idle }
    var isValidating: Bool { self == .validating }
    var isValid: Bool { if case .valid = self { return true }; return false }
    var message: String? {
        switch self {
        case .idle: return nil
        case .validating: return nil
        case .valid: return nil
        case .invalid(let msg): return msg
        }
    }
}

@MainActor
public final class SettingsViewModel: ObservableObject {
    @Published public var apiKey: String
    @Published public var refreshInterval: Double
    @Published public var showCompactSummary: Bool
    @Published public var selectedLanguage: AppLanguage
    @Published public var showFiveHourSummary: Bool
    @Published public var showWeeklySummary: Bool
    @Published public var showMCPSummary: Bool
    @Published public var launchAtLoginEnabled: Bool
    @Published public var themePreference: AppTheme
    @Published public var showFiveHourQuota: Bool
    @Published public var showWeeklyQuota: Bool
    @Published public var showMCPQuota: Bool
    @Published public var showBillingStats: Bool
    @Published public private(set) var feedbackMessage: String?
    @Published public private(set) var isTestingConnection = false
    @Published public var keyValidationState: KeyValidationState = .idle
    public let defaultBaseURLString: String

    private let settingsStore: SettingsStoreProtocol
    private let apiKeyStore: APIKeyProviding
    private let connectionTester: ConnectionTestingService
    private let logger: Logging
    public var onClearBillingData: (() async -> Void)?

    public init(
        settingsStore: SettingsStoreProtocol,
        apiKeyStore: APIKeyProviding,
        connectionTester: ConnectionTestingService,
        logger: Logging = AppLogger(),
        onClearBillingData: (() async -> Void)? = nil
    ) {
        self.settingsStore = settingsStore
        self.apiKeyStore = apiKeyStore
        self.connectionTester = connectionTester
        self.logger = logger
        self.onClearBillingData = onClearBillingData
        self.defaultBaseURLString = settingsStore.baseURLString.isEmpty ? "https://api.z.ai" : settingsStore.baseURLString
        self.refreshInterval = settingsStore.refreshInterval
        self.showCompactSummary = settingsStore.showCompactSummary
        self.selectedLanguage = settingsStore.selectedLanguage
        self.showFiveHourSummary = settingsStore.showFiveHourSummary
        self.showWeeklySummary = settingsStore.showWeeklySummary
        self.showMCPSummary = settingsStore.showMCPSummary
        self.launchAtLoginEnabled = settingsStore.launchAtLoginEnabled
        self.themePreference = settingsStore.themePreference
        self.showFiveHourQuota = settingsStore.showFiveHourQuota
        self.showWeeklyQuota = settingsStore.showWeeklyQuota
        self.showMCPQuota = settingsStore.showMCPQuota
        self.showBillingStats = settingsStore.showBillingStats
        self.apiKey = (try? apiKeyStore.loadAPIKey()) ?? ""
    }

    public func save() {
        do {
            try persistSettings()
            feedbackMessage = AppStrings.settingsSaved(language: selectedLanguage)
        } catch {
            logger.error(error.localizedDescription)
            feedbackMessage = error.localizedDescription
        }
    }

    public func testConnection() async {
        isTestingConnection = true
        defer { isTestingConnection = false }

        do {
            try persistSettings()
            let config = APIConfiguration(baseURLString: defaultBaseURLString)
            try await connectionTester.testConnection(configuration: config, apiKey: apiKey)
            feedbackMessage = AppStrings.connectionSuccessful(language: selectedLanguage)
        } catch {
            logger.error(error.localizedDescription)
            feedbackMessage = error.localizedDescription
        }
    }

    public func clearAPIKey() {
        apiKey = ""
        keyValidationState = .idle
    }

    /// Clears the API key and all local data. Called after user confirms the alert.
    public func clearAPIKeyAndLocalData() async {
        apiKey = ""
        keyValidationState = .idle
        await clearLocalData()
    }

    public func clearFeedback() {
        feedbackMessage = nil
        keyValidationState = .idle
    }

    public func validateKey() async {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            keyValidationState = .invalid(AppStrings.keyEmpty(language: selectedLanguage))
            return
        }

        keyValidationState = .validating
        do {
            try persistSettings()
            let config = APIConfiguration(baseURLString: defaultBaseURLString)
            try await connectionTester.testConnection(configuration: config, apiKey: key)
            keyValidationState = .valid
        } catch {
            logger.error("Key validation failed: \(error.localizedDescription)")
            keyValidationState = .invalid(error.localizedDescription)
        }
    }

    public func clearLocalData() async {
        do {
            settingsStore.resetToDefaults()
            try apiKeyStore.saveAPIKey(nil)
            await onClearBillingData?()
            reloadFromStores()
            feedbackMessage = AppStrings.localDataCleared(language: selectedLanguage)
        } catch {
            logger.error(error.localizedDescription)
            feedbackMessage = error.localizedDescription
        }
    }

    public func saveSilently() {
        do {
            try persistSettings()
        } catch {
            logger.error(error.localizedDescription)
        }
    }

    private func persistSettings() throws {
        settingsStore.baseURLString = defaultBaseURLString
        settingsStore.refreshInterval = refreshInterval
        settingsStore.showCompactSummary = showCompactSummary
        settingsStore.selectedLanguage = selectedLanguage
        settingsStore.showFiveHourSummary = showFiveHourSummary
        settingsStore.showWeeklySummary = showWeeklySummary
        settingsStore.showMCPSummary = showMCPSummary
        settingsStore.launchAtLoginEnabled = launchAtLoginEnabled
        settingsStore.themePreference = themePreference
        settingsStore.showFiveHourQuota = showFiveHourQuota
        settingsStore.showWeeklyQuota = showWeeklyQuota
        settingsStore.showMCPQuota = showMCPQuota
        settingsStore.showBillingStats = showBillingStats

        try apiKeyStore.saveAPIKey(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : apiKey)
    }

    private func reloadFromStores() {
        refreshInterval = settingsStore.refreshInterval
        showCompactSummary = settingsStore.showCompactSummary
        selectedLanguage = settingsStore.selectedLanguage
        showFiveHourSummary = settingsStore.showFiveHourSummary
        showWeeklySummary = settingsStore.showWeeklySummary
        showMCPSummary = settingsStore.showMCPSummary
        launchAtLoginEnabled = settingsStore.launchAtLoginEnabled
        themePreference = settingsStore.themePreference
        showFiveHourQuota = settingsStore.showFiveHourQuota
        showWeeklyQuota = settingsStore.showWeeklyQuota
        showMCPQuota = settingsStore.showMCPQuota
        showBillingStats = settingsStore.showBillingStats
        apiKey = (try? apiKeyStore.loadAPIKey()) ?? ""
    }
}
