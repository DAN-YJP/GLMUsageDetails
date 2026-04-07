import Foundation

public enum DateFormatting {
    public static func string(from date: Date?, language: AppLanguage) -> String {
        guard let date else { return AppStrings.unavailable(language: language) }
        return formatter(for: language).string(from: date)
    }

    public static func string(from date: Date?) -> String {
        string(from: date, language: .english)
    }

    private static func formatter(for language: AppLanguage) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }
}
