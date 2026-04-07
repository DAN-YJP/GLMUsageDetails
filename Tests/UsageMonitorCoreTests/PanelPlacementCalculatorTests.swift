import CoreGraphics
import XCTest
@testable import UsageMonitorCore

final class PanelPlacementCalculatorTests: XCTestCase {
    func testPositionsPanelCenteredBelowStatusItemWithinVisibleFrame() {
        let buttonFrame = CGRect(x: 900, y: 846, width: 28, height: 22)
        let visibleFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let panelSize = DashboardLayoutMetrics.preferredPanelSize

        let origin = PanelPlacementCalculator.origin(
            forStatusButtonFrame: buttonFrame,
            panelSize: panelSize,
            visibleFrame: visibleFrame
        )

        XCTAssertEqual(origin.x, 714, accuracy: 0.5)
        XCTAssertEqual(origin.y, 118, accuracy: 0.5)
    }
}
