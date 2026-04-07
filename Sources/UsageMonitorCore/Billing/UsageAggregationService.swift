import Foundation

public protocol UsageAggregationServiceProtocol: Sendable {
    func allWindowStats() async throws -> [UsageWindowStats]
    func stats(for window: TimeWindow) async throws -> UsageWindowStats
    func currentMembershipTier() async throws -> String?
    func callLimitForCurrentTier() async throws -> MembershipLimitInfo
    func weeklyDetail() async throws -> UsageDetailSnapshot
    func detail(for window: TimeWindow) async throws -> UsageDetailSnapshot
}

public struct MembershipLimitInfo: Equatable, Sendable {
    public let tierName: String
    public let periodHours: Int
    public let callLimit: Int
    public let used: Int

    public init(tierName: String, periodHours: Int, callLimit: Int, used: Int) {
        self.tierName = tierName
        self.periodHours = periodHours
        self.callLimit = callLimit
        self.used = used
    }

    public var remaining: Int { max(callLimit - used, 0) }
    public var percentage: Double { callLimit > 0 ? min(Double(used) / Double(callLimit) * 100, 100) : 0 }
}

public final class UsageAggregationService: UsageAggregationServiceProtocol, Sendable {
    private let ledgerStore: UsageLedgerStore

    public init(ledgerStore: UsageLedgerStore) {
        self.ledgerStore = ledgerStore
    }

    public func allWindowStats() async throws -> [UsageWindowStats] {
        var results: [UsageWindowStats] = []
        for window in TimeWindow.allCases {
            let stats = try await self.stats(for: window)
            results.append(stats)
        }
        return results
    }

    public func stats(for window: TimeWindow) async throws -> UsageWindowStats {
        let (startTime, endTime) = Self.timeRange(for: window)
        let usage = try await ledgerStore.usageByTimeRange(startTime: startTime, endTime: endTime)

        let growthRate: Double?
        if window == .fiveHour {
            growthRate = try? await ledgerStore.hourlyGrowthRate()
        } else {
            growthRate = nil
        }

        return UsageWindowStats(
            window: window,
            callCount: usage.callCount,
            tokenUsage: usage.tokenUsage,
            totalCost: usage.totalCost,
            growthRate: growthRate
        )
    }

    private static func timeRange(for window: TimeWindow) -> (start: String, end: String) {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let end = formatter.string(from: now)

        let startDate: Date
        switch window {
        case .fiveHour:
            startDate = now.addingTimeInterval(-5 * 3600)
        case .oneDay:
            startDate = now.addingTimeInterval(-24 * 3600)
        case .oneWeek:
            startDate = now.addingTimeInterval(-7 * 86400)
        case .oneMonth:
            startDate = now.addingTimeInterval(-30 * 86400)
        }

        let start = formatter.string(from: startDate)
        return (start, end)
    }

    public func currentMembershipTier() async throws -> String? {
        try await ledgerStore.currentMembershipTier()
    }

    public func callLimitForCurrentTier() async throws -> MembershipLimitInfo {
        let tierName = (try? await ledgerStore.currentMembershipTier()) ?? "GLM Coding Pro"
        let limitRecord = try? await ledgerStore.getMembershipLimit(tierName: tierName)
        let used = (try? await ledgerStore.recentApiUsage(hours: limitRecord?.periodHours ?? 5)) ?? 0

        return MembershipLimitInfo(
            tierName: limitRecord?.tierName ?? tierName,
            periodHours: limitRecord?.periodHours ?? 5,
            callLimit: limitRecord?.callLimit ?? 12000,
            used: used
        )
    }

    public func weeklyDetail() async throws -> UsageDetailSnapshot {
        try await detail(for: .oneWeek)
    }

    public func detail(for window: TimeWindow) async throws -> UsageDetailSnapshot {
        let (startTime, endTime) = Self.timeRange(for: window)

        switch window {
        case .fiveHour, .oneDay:
            async let hourly = ledgerStore.hourlyUsageBreakdown(startTime: startTime, endTime: endTime)
            async let products = ledgerStore.productBreakdown(startTime: startTime, endTime: endTime)
            async let tokens = ledgerStore.tokenBreakdown(startTime: startTime, endTime: endTime)

            let hourlyData = try await hourly
            let productData = try await products
            let tokenData = try await tokens

            let totalCalls = hourlyData.reduce(0) { $0 + $1.calls }
            let totalTokens = hourlyData.reduce(0) { $0 + $1.tokens }
            let totalCost = hourlyData.reduce(0) { $0 + $1.cost }

            return UsageDetailSnapshot(
                totalCalls: totalCalls,
                totalTokens: totalTokens,
                totalCost: totalCost,
                dailyBreakdown: [],
                hourlyBreakdown: hourlyData,
                productBreakdown: productData,
                tokenBreakdown: tokenData
            )

        case .oneWeek, .oneMonth:
            async let daily = ledgerStore.dailyUsageBreakdown(startTime: startTime, endTime: endTime)
            async let products = ledgerStore.productBreakdown(startTime: startTime, endTime: endTime)
            async let tokens = ledgerStore.tokenBreakdown(startTime: startTime, endTime: endTime)

            let dailyData = try await daily
            let productData = try await products
            let tokenData = try await tokens

            let totalCalls = dailyData.reduce(0) { $0 + $1.calls }
            let totalTokens = dailyData.reduce(0) { $0 + $1.tokens }
            let totalCost = dailyData.reduce(0) { $0 + $1.cost }

            return UsageDetailSnapshot(
                totalCalls: totalCalls,
                totalTokens: totalTokens,
                totalCost: totalCost,
                dailyBreakdown: dailyData,
                productBreakdown: productData,
                tokenBreakdown: tokenData
            )
        }
    }
}
