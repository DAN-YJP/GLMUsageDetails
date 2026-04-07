import Foundation

public enum QuotaFormatter {
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private static let rawFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    private static let costFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    public static func format(_ value: Double) -> String {
        numberFormatter.string(from: NSNumber(value: value)) ?? rawNumber(value)
    }

    public static func percentage(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    public static func fraction(used: Double, total: Double) -> String {
        "\(format(used))/\(format(total))"
    }

    public static func rawNumber(_ value: Double) -> String {
        rawFormatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    // MARK: - Billing Formatters

    public static func tokenCount(_ tokens: Int) -> String {
        if tokens >= 1_000_000 {
            let value = Double(tokens) / 1_000_000.0
            return String(format: "%.1fM", value)
        } else if tokens >= 1_000 {
            let value = Double(tokens) / 1_000.0
            return String(format: "%.1fK", value)
        }
        return "\(tokens)"
    }

    public static func callCount(_ count: Int) -> String {
        numberFormatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }

    public static func cost(_ value: Double) -> String {
        let formatted = costFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.4f", value)
        return "\(formatted) CNY"
    }

    public static func growthRate(_ rate: Double) -> String {
        let sign = rate >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", rate))%"
    }
}
