import Foundation

public enum QuotaPercentageSeverity: Equatable, Sendable {
    case good
    case warning
    case danger
}

public enum QuotaPercentageStyling {
    public static func severity(for percentage: Double) -> QuotaPercentageSeverity {
        if percentage >= 95 {
            return .danger
        }
        if percentage > 80 {
            return .warning
        }
        return .good
    }
}
