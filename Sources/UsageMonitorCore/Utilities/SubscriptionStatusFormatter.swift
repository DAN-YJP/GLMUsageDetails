import Foundation

public enum SubscriptionStatusFormatter {
    public static func displayText(for rawStatus: String?) -> String {
        guard let normalized = normalizedStatus(from: rawStatus) else {
            return "Unavailable"
        }

        switch normalized {
        case "VALID", "ACTIVE":
            return "Active"
        case "EXPIRED":
            return "Expired"
        case "CANCELLED":
            return "Cancelled"
        case "PAST_DUE":
            return "Past Due"
        default:
            return normalized
                .replacingOccurrences(of: "_", with: " ")
                .localizedCapitalized
        }
    }

    private static func normalizedStatus(from rawStatus: String?) -> String? {
        guard let trimmed = rawStatus?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }

        return trimmed.uppercased()
    }
}
