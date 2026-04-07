import XCTest
@testable import UsageMonitorCore

@MainActor
final class DashboardViewModelStatusTests: XCTestCase {
    func testFormatsProviderSubscriptionStatusForDisplay() async {
        let snapshot = DashboardSnapshot(
            subscription: SubscriptionSnapshot(planName: "GLM Coding Pro", status: "VALID", nextRenewal: nil),
            quotas: ClassifiedQuotaSnapshot(
                fiveHourQuota: nil,
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

        XCTAssertEqual(viewModel.subscriptionStatusText, "Active")
    }

    func testBuildsHeaderMetadataForRenewalAndRefresh() async {
        let refreshDate = Date(timeIntervalSince1970: 1_715_000_000)
        let renewalDate = Date(timeIntervalSince1970: 1_716_000_000)
        let snapshot = DashboardSnapshot(
            subscription: SubscriptionSnapshot(planName: "GLM Coding Pro", status: "VALID", nextRenewal: renewalDate),
            quotas: ClassifiedQuotaSnapshot(
                fiveHourQuota: nil,
                weeklyQuota: nil,
                mcpMonthlyQuota: nil,
                unmatchedEntries: [],
                diagnostics: []
            ),
            refreshedAt: refreshDate
        )

        let service = MockDashboardService(results: [.success(snapshot)])
        let viewModel = DashboardViewModel(
            dashboardService: service,
            settingsStore: InMemorySettingsStore(),
            logger: TestLogger()
        )

        await viewModel.refresh()

        XCTAssertEqual(viewModel.headerMetadataItems.count, 2)
        XCTAssertEqual(viewModel.headerMetadataItems[0].title, "Next Renewal")
        XCTAssertEqual(viewModel.headerMetadataItems[0].symbolName, "arrow.clockwise.circle")
        XCTAssertEqual(viewModel.headerMetadataItems[0].value, DateFormatting.string(from: renewalDate, language: .english))
        XCTAssertEqual(viewModel.headerMetadataItems[1].title, "Last Refresh")
        XCTAssertEqual(viewModel.headerMetadataItems[1].symbolName, "clock")
        XCTAssertEqual(viewModel.headerMetadataItems[1].value, DateFormatting.string(from: refreshDate, language: .english))
    }
}
