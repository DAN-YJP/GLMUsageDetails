import Foundation

// MARK: - Time Window

public enum TimeWindow: Int, CaseIterable, Sendable, Comparable {
    case fiveHour = 5
    case oneDay = 24
    case oneWeek = 168
    case oneMonth = 720

    public var label: String {
        switch self {
        case .fiveHour: return "5h"
        case .oneDay: return "1d"
        case .oneWeek: return "1w"
        case .oneMonth: return "1m"
        }
    }

    public static func < (lhs: TimeWindow, rhs: TimeWindow) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Usage Window Stats

public struct UsageWindowStats: Equatable, Sendable {
    public let window: TimeWindow
    public let callCount: Int
    public let tokenUsage: Int
    public let totalCost: Double
    public let growthRate: Double?

    public init(window: TimeWindow, callCount: Int, tokenUsage: Int, totalCost: Double, growthRate: Double? = nil) {
        self.window = window
        self.callCount = callCount
        self.tokenUsage = tokenUsage
        self.totalCost = totalCost
        self.growthRate = growthRate
    }

    public static let empty = UsageWindowStats(window: .fiveHour, callCount: 0, tokenUsage: 0, totalCost: 0)
}

// MARK: - Sync State

public enum SyncStage: String, Sendable, Equatable {
    case idle
    case clearing
    case fetching
    case saving
    case completed
    case failed
}

public struct SyncState: Equatable, Sendable {
    public var isSyncing: Bool
    public var stage: SyncStage
    public var progress: Double
    public var lastSyncTime: Date?
    public var lastSyncCount: Int
    public var lastError: String?
    public var totalBillsInDB: Int
    public var latestTransactionTime: Date?
    public var currentBillingMonth: String?
    public var fetchedCount: Int
    public var expectedTotal: Int?

    public init(
        isSyncing: Bool = false,
        stage: SyncStage = .idle,
        progress: Double = 0,
        lastSyncTime: Date? = nil,
        lastSyncCount: Int = 0,
        lastError: String? = nil,
        totalBillsInDB: Int = 0,
        latestTransactionTime: Date? = nil,
        currentBillingMonth: String? = nil,
        fetchedCount: Int = 0,
        expectedTotal: Int? = nil
    ) {
        self.isSyncing = isSyncing
        self.stage = stage
        self.progress = progress
        self.lastSyncTime = lastSyncTime
        self.lastSyncCount = lastSyncCount
        self.lastError = lastError
        self.totalBillsInDB = totalBillsInDB
        self.latestTransactionTime = latestTransactionTime
        self.currentBillingMonth = currentBillingMonth
        self.fetchedCount = fetchedCount
        self.expectedTotal = expectedTotal
    }

    public static let idle = SyncState()
}

// MARK: - Membership Tier

public struct MembershipTierInfo: Equatable, Sendable {
    public let tierName: String
    public let callLimit: Int
    public let periodHours: Int

    public init(tierName: String, callLimit: Int, periodHours: Int) {
        self.tierName = tierName
        self.callLimit = callLimit
        self.periodHours = periodHours
    }
}

// MARK: - Billing Stats Snapshot

public struct BillingStatsSnapshot: Equatable, Sendable {
    public let membershipTier: String
    public let fiveHour: UsageWindowStats
    public let oneDay: UsageWindowStats
    public let oneWeek: UsageWindowStats
    public let oneMonth: UsageWindowStats
    public let syncState: SyncState

    public init(
        membershipTier: String,
        fiveHour: UsageWindowStats,
        oneDay: UsageWindowStats,
        oneWeek: UsageWindowStats,
        oneMonth: UsageWindowStats,
        syncState: SyncState
    ) {
        self.membershipTier = membershipTier
        self.fiveHour = fiveHour
        self.oneDay = oneDay
        self.oneWeek = oneWeek
        self.oneMonth = oneMonth
        self.syncState = syncState
    }
}

// GRDB record types (ExpenseBillRecord, SyncHistoryGRDBRecord, MembershipTierLimitRecord)
// are defined in UsageLedgerStore.swift

// MARK: - Usage Detail (weekly / monthly)

/// Type alias kept for backward compatibility during transition.
public typealias WeeklyDetailSnapshot = UsageDetailSnapshot

public struct TokenBreakdown: Sendable, Equatable {
    public let inputTokens: Int
    public let outputTokens: Int
    public let cacheHitTokens: Int

    public init(inputTokens: Int, outputTokens: Int, cacheHitTokens: Int) {
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheHitTokens = cacheHitTokens
    }

    public static let zero = TokenBreakdown(inputTokens: 0, outputTokens: 0, cacheHitTokens: 0)
}

public struct UsageDetailSnapshot: Sendable {
    public let totalCalls: Int
    public let totalTokens: Int
    public let totalCost: Double
    public let dailyBreakdown: [DailyUsageRecord]
    public let hourlyBreakdown: [HourlyUsageRecord]
    public let productBreakdown: [ProductUsageRecord]
    public let tokenBreakdown: TokenBreakdown

    public init(totalCalls: Int, totalTokens: Int, totalCost: Double, dailyBreakdown: [DailyUsageRecord], hourlyBreakdown: [HourlyUsageRecord] = [], productBreakdown: [ProductUsageRecord], tokenBreakdown: TokenBreakdown = .zero) {
        self.totalCalls = totalCalls
        self.totalTokens = totalTokens
        self.totalCost = totalCost
        self.dailyBreakdown = dailyBreakdown
        self.hourlyBreakdown = hourlyBreakdown
        self.productBreakdown = productBreakdown
        self.tokenBreakdown = tokenBreakdown
    }
}

public struct DailyUsageRecord: Identifiable, Sendable {
    public let id: String
    public let day: String
    public let calls: Int
    public let tokens: Int
    public let cost: Double

    public init(day: String, calls: Int, tokens: Int, cost: Double) {
        self.id = day
        self.day = day
        self.calls = calls
        self.tokens = tokens
        self.cost = cost
    }
}

public struct HourlyUsageRecord: Identifiable, Sendable {
    public let id: String
    public let hour: String  // "2026-04-07 14:00"
    public let calls: Int
    public let tokens: Int
    public let cost: Double

    public init(hour: String, calls: Int, tokens: Int, cost: Double) {
        self.id = hour
        self.hour = hour
        self.calls = calls
        self.tokens = tokens
        self.cost = cost
    }
}

public struct ProductUsageRecord: Identifiable, Sendable {
    public let id: String
    public let product: String
    public let calls: Int
    public let tokens: Int

    public init(product: String, calls: Int, tokens: Int) {
        self.id = product
        self.product = product
        self.calls = calls
        self.tokens = tokens
    }
}
