import XCTest
@testable import UsageMonitorCore

final class SummaryTextBuilderTests: XCTestCase {
    func testBuildsCompactSummaryForCompleteSnapshot() throws {
        let snapshot = DashboardSnapshot(
            subscription: SubscriptionSnapshot(
                planName: "GLM Coding Max",
                status: "ACTIVE",
                nextRenewal: Date(timeIntervalSince1970: 1_715_000_000)
            ),
            quotas: ClassifiedQuotaSnapshot(
                fiveHourQuota: FiveHourQuota(
                    limit: 1000,
                    used: 270,
                    remaining: 730,
                    percentage: 27,
                    nextResetTime: nil,
                    usageDetails: [],
                    rawMetadata: [:]
                ),
                weeklyQuota: WeeklyQuota(
                    limit: 5000,
                    used: 650,
                    remaining: 4350,
                    percentage: 13,
                    nextResetTime: nil,
                    usageDetails: [],
                    rawMetadata: [:]
                ),
                mcpMonthlyQuota: MCPMonthlyQuota(
                    limit: 4000,
                    used: 1828,
                    remaining: 2172,
                    percentage: 45.7,
                    nextResetTime: nil,
                    usageDetails: [],
                    rawMetadata: [:]
                ),
                unmatchedEntries: [],
                diagnostics: []
            ),
            refreshedAt: Date(timeIntervalSince1970: 1_715_001_111)
        )

        XCTAssertEqual(
            SummaryTextBuilder.makeSummary(
                from: snapshot,
                options: SummaryDisplayOptions(showFiveHour: true, showWeekly: true, showMCP: true)
            ),
            "5h 27% | W 13% | MCP 1,828/4,000"
        )
    }

    func testBuildsGracefulSummaryWhenOnlyPartialDataExists() throws {
        let snapshot = DashboardSnapshot(
            subscription: nil,
            quotas: ClassifiedQuotaSnapshot(
                fiveHourQuota: nil,
                weeklyQuota: WeeklyQuota(
                    limit: 5000,
                    used: 1000,
                    remaining: 4000,
                    percentage: 20,
                    nextResetTime: nil,
                    usageDetails: [],
                    rawMetadata: [:]
                ),
                mcpMonthlyQuota: nil,
                unmatchedEntries: [],
                diagnostics: []
            ),
            refreshedAt: .now
        )

        XCTAssertEqual(
            SummaryTextBuilder.makeSummary(
                from: snapshot,
                options: SummaryDisplayOptions(showFiveHour: true, showWeekly: true, showMCP: true)
            ),
            "W 20%"
        )
    }

    func testSkipsUnavailableTokenBucketsInSummaryWhenOnlyPercentageIsMissingOrZeroCounts() throws {
        let snapshot = DashboardSnapshot(
            subscription: nil,
            quotas: ClassifiedQuotaSnapshot(
                fiveHourQuota: FiveHourQuota(
                    limit: 0,
                    used: 0,
                    remaining: 0,
                    percentage: 0,
                    nextResetTime: nil,
                    usageDetails: [],
                    rawMetadata: [:]
                ),
                weeklyQuota: WeeklyQuota(
                    limit: 0,
                    used: 0,
                    remaining: 0,
                    percentage: 18,
                    nextResetTime: nil,
                    usageDetails: [],
                    rawMetadata: [:]
                ),
                mcpMonthlyQuota: MCPMonthlyQuota(
                    limit: 1000,
                    used: 106,
                    remaining: 894,
                    percentage: 10,
                    nextResetTime: nil,
                    usageDetails: [],
                    rawMetadata: [:]
                ),
                unmatchedEntries: [],
                diagnostics: []
            ),
            refreshedAt: .now
        )

        XCTAssertEqual(
            SummaryTextBuilder.makeSummary(
                from: snapshot,
                options: SummaryDisplayOptions(showFiveHour: true, showWeekly: true, showMCP: true)
            ),
            "W 18% | MCP 106/1,000"
        )
    }

    func testCanFilterSummaryToSelectedBucketsOnly() throws {
        let snapshot = DashboardSnapshot(
            subscription: nil,
            quotas: ClassifiedQuotaSnapshot(
                fiveHourQuota: FiveHourQuota(
                    limit: 1000,
                    used: 270,
                    remaining: 730,
                    percentage: 27,
                    nextResetTime: nil,
                    usageDetails: [],
                    rawMetadata: [:]
                ),
                weeklyQuota: WeeklyQuota(
                    limit: 5000,
                    used: 650,
                    remaining: 4350,
                    percentage: 13,
                    nextResetTime: nil,
                    usageDetails: [],
                    rawMetadata: [:]
                ),
                mcpMonthlyQuota: MCPMonthlyQuota(
                    limit: 4000,
                    used: 1828,
                    remaining: 2172,
                    percentage: 45.7,
                    nextResetTime: nil,
                    usageDetails: [],
                    rawMetadata: [:]
                ),
                unmatchedEntries: [],
                diagnostics: []
            ),
            refreshedAt: .now
        )

        XCTAssertEqual(
            SummaryTextBuilder.makeSummary(
                from: snapshot,
                options: SummaryDisplayOptions(showFiveHour: false, showWeekly: true, showMCP: false)
            ),
            "W 13%"
        )
    }
}
