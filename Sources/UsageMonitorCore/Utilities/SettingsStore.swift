import Foundation

public protocol SettingsStoreProtocol: AnyObject, ConfigurationProviding, Sendable {
    var baseURLString: String { get set }
    var refreshInterval: TimeInterval { get set }
    var showCompactSummary: Bool { get set }
    var selectedLanguage: AppLanguage { get set }
    var showFiveHourSummary: Bool { get set }
    var showWeeklySummary: Bool { get set }
    var showMCPSummary: Bool { get set }
    var launchAtLoginEnabled: Bool { get set }
    var themePreference: AppTheme { get set }
    var showFiveHourQuota: Bool { get set }
    var showWeeklyQuota: Bool { get set }
    var showMCPQuota: Bool { get set }
    var showBillingStats: Bool { get set }
    func resetToDefaults()
}

public final class UserDefaultsSettingsStore: SettingsStoreProtocol, @unchecked Sendable {
    private enum Keys {
        static let baseURLString = "baseURLString"
        static let refreshInterval = "refreshInterval"
        static let showCompactSummary = "showCompactSummary"
        static let selectedLanguage = "selectedLanguage"
        static let showFiveHourSummary = "showFiveHourSummary"
        static let showWeeklySummary = "showWeeklySummary"
        static let showMCPSummary = "showMCPSummary"
        static let launchAtLoginEnabled = "launchAtLoginEnabled"
        static let themePreference = "themePreference"
        static let showFiveHourQuota = "showFiveHourQuota"
        static let showWeeklyQuota = "showWeeklyQuota"
        static let showMCPQuota = "showMCPQuota"
        static let showBillingStats = "showBillingStats"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        applyDefaultsIfNeeded()
    }

    public func resetToDefaults() {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleIdentifier)
        } else if let suiteName = defaultsSuiteName() {
            defaults.removePersistentDomain(forName: suiteName)
        } else {
            for key in [
                Keys.baseURLString,
                Keys.refreshInterval,
                Keys.showCompactSummary,
                Keys.selectedLanguage,
                Keys.showFiveHourSummary,
                Keys.showWeeklySummary,
                Keys.showMCPSummary,
                Keys.launchAtLoginEnabled,
                Keys.themePreference,
                Keys.showFiveHourQuota,
                Keys.showWeeklyQuota,
                Keys.showMCPQuota,
                Keys.showBillingStats
            ] {
                defaults.removeObject(forKey: key)
            }
        }
        applyDefaultsIfNeeded()
    }

    private func applyDefaultsIfNeeded() {
        if defaults.object(forKey: Keys.baseURLString) == nil {
            defaults.set("https://api.z.ai", forKey: Keys.baseURLString)
        }
        if defaults.object(forKey: Keys.refreshInterval) == nil {
            defaults.set(300.0, forKey: Keys.refreshInterval)
        }
        if defaults.object(forKey: Keys.showCompactSummary) == nil {
            defaults.set(true, forKey: Keys.showCompactSummary)
        }
        if defaults.object(forKey: Keys.selectedLanguage) == nil {
            defaults.set(AppLanguage.simplifiedChinese.rawValue, forKey: Keys.selectedLanguage)
        }
        if defaults.object(forKey: Keys.showFiveHourSummary) == nil {
            defaults.set(true, forKey: Keys.showFiveHourSummary)
        }
        if defaults.object(forKey: Keys.showWeeklySummary) == nil {
            defaults.set(true, forKey: Keys.showWeeklySummary)
        }
        if defaults.object(forKey: Keys.showMCPSummary) == nil {
            defaults.set(true, forKey: Keys.showMCPSummary)
        }
        if defaults.object(forKey: Keys.themePreference) == nil {
            defaults.set(AppTheme.system.rawValue, forKey: Keys.themePreference)
        }
        if defaults.object(forKey: Keys.showFiveHourQuota) == nil {
            defaults.set(true, forKey: Keys.showFiveHourQuota)
        }
        if defaults.object(forKey: Keys.showWeeklyQuota) == nil {
            defaults.set(true, forKey: Keys.showWeeklyQuota)
        }
        if defaults.object(forKey: Keys.showMCPQuota) == nil {
            defaults.set(true, forKey: Keys.showMCPQuota)
        }
        if defaults.object(forKey: Keys.showBillingStats) == nil {
            defaults.set(true, forKey: Keys.showBillingStats)
        }
    }

    private func defaultsSuiteName() -> String? {
        defaults.dictionaryRepresentation().keys.contains("AppleLanguages") ? nil : Bundle.main.bundleIdentifier
    }

    public var baseURLString: String {
        get { defaults.string(forKey: Keys.baseURLString) ?? "https://api.z.ai" }
        set { defaults.set(newValue, forKey: Keys.baseURLString) }
    }

    public var refreshInterval: TimeInterval {
        get { defaults.double(forKey: Keys.refreshInterval) }
        set { defaults.set(newValue, forKey: Keys.refreshInterval) }
    }

    public var showCompactSummary: Bool {
        get { defaults.bool(forKey: Keys.showCompactSummary) }
        set { defaults.set(newValue, forKey: Keys.showCompactSummary) }
    }

    public var selectedLanguage: AppLanguage {
        get { AppLanguage(rawValue: defaults.string(forKey: Keys.selectedLanguage) ?? AppLanguage.english.rawValue) ?? .english }
        set { defaults.set(newValue.rawValue, forKey: Keys.selectedLanguage) }
    }

    public var showFiveHourSummary: Bool {
        get { defaults.bool(forKey: Keys.showFiveHourSummary) }
        set { defaults.set(newValue, forKey: Keys.showFiveHourSummary) }
    }

    public var showWeeklySummary: Bool {
        get { defaults.bool(forKey: Keys.showWeeklySummary) }
        set { defaults.set(newValue, forKey: Keys.showWeeklySummary) }
    }

    public var showMCPSummary: Bool {
        get { defaults.bool(forKey: Keys.showMCPSummary) }
        set { defaults.set(newValue, forKey: Keys.showMCPSummary) }
    }

    public var launchAtLoginEnabled: Bool {
        get { defaults.bool(forKey: Keys.launchAtLoginEnabled) }
        set { defaults.set(newValue, forKey: Keys.launchAtLoginEnabled) }
    }

    public var themePreference: AppTheme {
        get { AppTheme(rawValue: defaults.string(forKey: Keys.themePreference) ?? AppTheme.system.rawValue) ?? .system }
        set { defaults.set(newValue.rawValue, forKey: Keys.themePreference) }
    }

    public var showFiveHourQuota: Bool {
        get { defaults.bool(forKey: Keys.showFiveHourQuota) }
        set { defaults.set(newValue, forKey: Keys.showFiveHourQuota) }
    }

    public var showWeeklyQuota: Bool {
        get { defaults.bool(forKey: Keys.showWeeklyQuota) }
        set { defaults.set(newValue, forKey: Keys.showWeeklyQuota) }
    }

    public var showMCPQuota: Bool {
        get { defaults.bool(forKey: Keys.showMCPQuota) }
        set { defaults.set(newValue, forKey: Keys.showMCPQuota) }
    }

    public var showBillingStats: Bool {
        get { defaults.bool(forKey: Keys.showBillingStats) }
        set { defaults.set(newValue, forKey: Keys.showBillingStats) }
    }

    public func currentConfiguration() throws -> APIConfiguration {
        APIConfiguration(baseURLString: baseURLString)
    }
}

public extension SettingsStoreProtocol {
    var summaryDisplayOptions: SummaryDisplayOptions {
        SummaryDisplayOptions(
            showFiveHour: showFiveHourSummary,
            showWeekly: showWeeklySummary,
            showMCP: showMCPSummary
        )
    }
}
