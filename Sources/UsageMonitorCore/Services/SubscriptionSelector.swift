import Foundation

public enum SubscriptionSelector {
    public static func selectMostRelevant(from items: [SubscriptionTransportItem]) -> SubscriptionSnapshot? {
        guard !items.isEmpty else { return nil }

        let active = items.first {
            if $0.isActive == true { return true }
            let status = $0.status?.uppercased() ?? ""
            return status.contains("ACTIVE") || status.contains("CURRENT")
        }

        let chosen = active ?? items.first
        guard let chosen, let planName = chosen.productName, !planName.isEmpty else {
            return nil
        }

        return SubscriptionSnapshot(
            planName: planName,
            status: chosen.status,
            nextRenewal: chosen.nextRenewTime
        )
    }
}
