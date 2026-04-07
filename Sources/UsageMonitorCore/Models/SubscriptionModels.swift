import Foundation

public struct SubscriptionTransportItem: Decodable, Sendable {
    public let productName: String?
    public let status: String?
    public let nextRenewTime: Date?
    public let isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case productName
        case status
        case nextRenewTime
        case isActive
    }

    public init(productName: String?, status: String?, nextRenewTime: Date?, isActive: Bool?) {
        self.productName = productName
        self.status = status
        self.nextRenewTime = nextRenewTime
        self.isActive = isActive
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        productName = try container.decodeIfPresent(String.self, forKey: .productName)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        nextRenewTime = try container.decodeFlexibleDateIfPresent(forKey: .nextRenewTime)
    }
}

public struct SubscriptionSnapshot: Equatable, Sendable {
    public let planName: String
    public let status: String?
    public let nextRenewal: Date?

    public init(planName: String, status: String?, nextRenewal: Date?) {
        self.planName = planName
        self.status = status
        self.nextRenewal = nextRenewal
    }
}
