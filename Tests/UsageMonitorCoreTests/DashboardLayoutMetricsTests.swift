import XCTest
@testable import UsageMonitorCore

final class DashboardLayoutMetricsTests: XCTestCase {
    func testPreferredPanelHeightFitsTypicalDashboardContent() {
        XCTAssertEqual(DashboardLayoutMetrics.preferredPanelSize.width, 400)
        XCTAssertEqual(DashboardLayoutMetrics.preferredPanelSize.height, 720)
    }
}
