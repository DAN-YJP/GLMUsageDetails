import Foundation

public enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case english
    case simplifiedChinese

    public var settingsLabel: String {
        switch self {
        case .english:
            return "English"
        case .simplifiedChinese:
            return "简体中文"
        }
    }

    public var locale: Locale {
        switch self {
        case .english:
            return Locale(identifier: "en_US_POSIX")
        case .simplifiedChinese:
            return Locale(identifier: "zh_CN")
        }
    }
}

public enum AppTheme: String, CaseIterable, Codable, Sendable {
    case system
    case light
    case dark

    public var settingsLabel: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}
