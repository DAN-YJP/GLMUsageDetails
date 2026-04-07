import XCTest
@testable import UsageMonitorCore

@MainActor
final class DashboardViewModelTests: XCTestCase {
    func testKeepsLastSuccessfulSnapshotOnRefreshFailure() async throws {
        let firstSnapshot = DashboardSnapshot(
            subscription: SubscriptionSnapshot(planName: "GLM Coding Max", status: "ACTIVE", nextRenewal: nil),
            quotas: ClassifiedQuotaSnapshot(
                fiveHourQuota: FiveHourQuota(limit: 1000, used: 200, remaining: 800, percentage: 20, nextResetTime: nil, usageDetails: [], rawMetadata: [:]),
                weeklyQuota: nil,
                mcpMonthlyQuota: nil,
                unmatchedEntries: [],
                diagnostics: []
            ),
            refreshedAt: .now
        )

        let service = MockDashboardService(results: [
            .success(firstSnapshot),
            .failure(UsageMonitorError.networkFailure(URLError(.notConnectedToInternet)))
        ])

        let viewModel = DashboardViewModel(
            dashboardService: service,
            settingsStore: InMemorySettingsStore(),
            logger: TestLogger()
        )

        await viewModel.refresh()
        XCTAssertEqual(viewModel.snapshot?.subscription?.planName, "GLM Coding Max")

        await viewModel.refresh()
        XCTAssertEqual(viewModel.snapshot?.subscription?.planName, "GLM Coding Max")
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testDisplaysUnavailableAbsoluteCountsWhenProviderOnlyReturnsPercentages() async throws {
        let snapshot = DashboardSnapshot(
            subscription: SubscriptionSnapshot(planName: "GLM Coding Pro", status: "VALID", nextRenewal: nil),
            quotas: ClassifiedQuotaSnapshot(
                fiveHourQuota: FiveHourQuota(limit: 0, used: 0, remaining: 0, percentage: 0, nextResetTime: nil, usageDetails: [], rawMetadata: [:]),
                weeklyQuota: WeeklyQuota(limit: 0, used: 0, remaining: 0, percentage: 18, nextResetTime: nil, usageDetails: [], rawMetadata: [:]),
                mcpMonthlyQuota: MCPMonthlyQuota(limit: 1000, used: 106, remaining: 894, percentage: 10, nextResetTime: nil, usageDetails: [], rawMetadata: [:]),
                unmatchedEntries: [],
                diagnostics: []
            ),
            refreshedAt: .now
        )

        let service = MockDashboardService(results: [.success(snapshot)])
        let viewModel = DashboardViewModel(
            dashboardService: service,
            settingsStore: InMemorySettingsStore(),
            logger: TestLogger()
        )

        await viewModel.refresh()

        XCTAssertEqual(viewModel.quotaCards[0].usedText, "--")
        XCTAssertEqual(viewModel.quotaCards[0].totalText, "--")
        XCTAssertNil(viewModel.quotaCards[0].statusText)
        XCTAssertEqual(viewModel.quotaCards[1].remainingText, "--")
        XCTAssertEqual(viewModel.quotaCards[1].percentageText, "18%")
        XCTAssertNil(viewModel.quotaCards[1].statusText)
        XCTAssertEqual(viewModel.quotaCards[2].usedText, "106")
        XCTAssertEqual(viewModel.menuBarSummaryText, "W 18% | MCP 106/1,000")
    }

    func testShowsUsedWhenProviderOnlyReturnsUsedWithoutTotalOrRemaining() async throws {
        let snapshot = DashboardSnapshot(
            subscription: SubscriptionSnapshot(planName: "GLM Coding Pro", status: "VALID", nextRenewal: nil),
            quotas: ClassifiedQuotaSnapshot(
                fiveHourQuota: FiveHourQuota(limit: 0, used: 123_456, remaining: 0, percentage: 12, nextResetTime: nil, usageDetails: [], rawMetadata: [:]),
                weeklyQuota: nil,
                mcpMonthlyQuota: nil,
                unmatchedEntries: [],
                diagnostics: []
            ),
            refreshedAt: .now
        )

        let service = MockDashboardService(results: [.success(snapshot)])
        let viewModel = DashboardViewModel(
            dashboardService: service,
            settingsStore: InMemorySettingsStore(),
            logger: TestLogger()
        )

        await viewModel.refresh()

        XCTAssertEqual(viewModel.quotaCards[0].usedText, "123,456")
        XCTAssertEqual(viewModel.quotaCards[0].remainingText, "--")
        XCTAssertEqual(viewModel.quotaCards[0].totalText, "--")
        XCTAssertNil(viewModel.quotaCards[0].statusText)
    }
}
