import Foundation

public struct MCPToolUsageDetail: Codable, Equatable, Sendable {
    public let tool: String
    public let used: Double

    public init(tool: String, used: Double) {
        self.tool = tool
        self.used = used
    }
}

public struct QuotaLimitEntry: Decodable, Equatable, Sendable {
    public let type: String
    public let unit: Int
    public let number: Int
    public let limit: Double
    public let used: Double
    public let remaining: Double?
    public let percentage: Double?
    public let nextResetTime: Date?
    public let usageDetails: [MCPToolUsageDetail]?
    public let metadata: [String: String]

    enum CodingKeys: String, CodingKey {
        case type
        case unit
        case number
        case limit
        case currentValue
        case totalLimit
        case used
        case usage
        case remaining
        case available
        case percentage
        case nextResetTime
        case usageDetails
    }

    public init(
        type: String,
        unit: Int,
        number: Int,
        limit: Double,
        used: Double,
        remaining: Double?,
        percentage: Double?,
        nextResetTime: Date?,
        usageDetails: [MCPToolUsageDetail]?,
        metadata: [String: String]
    ) {
        self.type = type
        self.unit = unit
        self.number = number
        self.limit = limit
        self.used = used
        self.remaining = remaining
        self.percentage = percentage
        self.nextResetTime = nextResetTime
        self.usageDetails = usageDetails
        self.metadata = metadata
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "UNKNOWN"
        unit = try container.decodeLossyInt(forKey: .unit) ?? 0
        number = try container.decodeLossyInt(forKey: .number) ?? 0
        let providerTotal = try container.decodeLossyDouble(forKeys: [.usage, .limit, .totalLimit])
        let providerUsed = try container.decodeLossyDouble(forKeys: [.currentValue, .used])
        limit = providerTotal ?? 0
        used = providerUsed ?? 0
        remaining = try container.decodeLossyDouble(forKeys: [.remaining, .available])
        percentage = try container.decodeLossyDouble(forKeys: [.percentage])
        nextResetTime = try container.decodeFlexibleDateIfPresent(forKey: .nextResetTime)
        usageDetails = try container.decodeIfPresent([UsageDetailTransport].self, forKey: .usageDetails)?.map {
            MCPToolUsageDetail(tool: $0.modelCode ?? $0.tool ?? "unknown", used: $0.usage ?? 0)
        }

        var metadata: [String: String] = [
            "type": type,
            "unit": String(unit),
            "number": String(number),
            "limit": QuotaFormatter.rawNumber(limit),
            "used": QuotaFormatter.rawNumber(used)
        ]
        if let remaining {
            metadata["remaining"] = QuotaFormatter.rawNumber(remaining)
        }
        if let percentage {
            metadata["percentage"] = QuotaFormatter.rawNumber(percentage)
        }
        self.metadata = metadata
    }
}

public struct UsageDetailTransport: Decodable, Sendable {
    public let modelCode: String?
    public let tool: String?
    public let usage: Double?
}

public protocol QuotaSnapshotProtocol: Equatable, Sendable {
    var limit: Double { get }
    var used: Double { get }
    var remaining: Double { get }
    var percentage: Double { get }
    var nextResetTime: Date? { get }
    var usageDetails: [MCPToolUsageDetail] { get }
    var rawMetadata: [String: String] { get }
}

public struct FiveHourQuota: QuotaSnapshotProtocol {
    public let limit: Double
    public let used: Double
    public let remaining: Double
    public let percentage: Double
    public let nextResetTime: Date?
    public let usageDetails: [MCPToolUsageDetail]
    public let rawMetadata: [String: String]

    public init(limit: Double, used: Double, remaining: Double, percentage: Double, nextResetTime: Date?, usageDetails: [MCPToolUsageDetail], rawMetadata: [String: String]) {
        self.limit = limit
        self.used = used
        self.remaining = remaining
        self.percentage = percentage
        self.nextResetTime = nextResetTime
        self.usageDetails = usageDetails
        self.rawMetadata = rawMetadata
    }
}

public struct WeeklyQuota: QuotaSnapshotProtocol {
    public let limit: Double
    public let used: Double
    public let remaining: Double
    public let percentage: Double
    public let nextResetTime: Date?
    public let usageDetails: [MCPToolUsageDetail]
    public let rawMetadata: [String: String]

    public init(limit: Double, used: Double, remaining: Double, percentage: Double, nextResetTime: Date?, usageDetails: [MCPToolUsageDetail], rawMetadata: [String: String]) {
        self.limit = limit
        self.used = used
        self.remaining = remaining
        self.percentage = percentage
        self.nextResetTime = nextResetTime
        self.usageDetails = usageDetails
        self.rawMetadata = rawMetadata
    }
}

public struct MCPMonthlyQuota: QuotaSnapshotProtocol {
    public let limit: Double
    public let used: Double
    public let remaining: Double
    public let percentage: Double
    public let nextResetTime: Date?
    public let usageDetails: [MCPToolUsageDetail]
    public let rawMetadata: [String: String]

    public init(limit: Double, used: Double, remaining: Double, percentage: Double, nextResetTime: Date?, usageDetails: [MCPToolUsageDetail], rawMetadata: [String: String]) {
        self.limit = limit
        self.used = used
        self.remaining = remaining
        self.percentage = percentage
        self.nextResetTime = nextResetTime
        self.usageDetails = usageDetails
        self.rawMetadata = rawMetadata
    }
}

public enum QuotaBucket: String, Equatable, Sendable {
    case fiveHour
    case weekly
    case mcpMonthly
    case unmatched
}

public struct QuotaClassificationDiagnostic: Equatable, Sendable {
    public let bucket: QuotaBucket
    public let entrySummary: String
    public let metadata: [String: String]

    public init(bucket: QuotaBucket, entrySummary: String, metadata: [String: String]) {
        self.bucket = bucket
        self.entrySummary = entrySummary
        self.metadata = metadata
    }
}

public struct ClassifiedQuotaSnapshot: Equatable, Sendable {
    public let fiveHourQuota: FiveHourQuota?
    public let weeklyQuota: WeeklyQuota?
    public let mcpMonthlyQuota: MCPMonthlyQuota?
    public let unmatchedEntries: [QuotaLimitEntry]
    public let diagnostics: [QuotaClassificationDiagnostic]

    public init(
        fiveHourQuota: FiveHourQuota?,
        weeklyQuota: WeeklyQuota?,
        mcpMonthlyQuota: MCPMonthlyQuota?,
        unmatchedEntries: [QuotaLimitEntry],
        diagnostics: [QuotaClassificationDiagnostic]
    ) {
        self.fiveHourQuota = fiveHourQuota
        self.weeklyQuota = weeklyQuota
        self.mcpMonthlyQuota = mcpMonthlyQuota
        self.unmatchedEntries = unmatchedEntries
        self.diagnostics = diagnostics
    }
}

public struct DashboardSnapshot: Equatable, Sendable {
    public let subscription: SubscriptionSnapshot?
    public let quotas: ClassifiedQuotaSnapshot
    public let refreshedAt: Date

    public init(subscription: SubscriptionSnapshot?, quotas: ClassifiedQuotaSnapshot, refreshedAt: Date) {
        self.subscription = subscription
        self.quotas = quotas
        self.refreshedAt = refreshedAt
    }
}
