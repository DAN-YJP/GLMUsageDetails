import XCTest
@testable import UsageMonitorCore

final class StatusItemPresentationPolicyTests: XCTestCase {
    func testUsesMouseUpForLeftClickAndMouseDownForRightClick() {
        XCTAssertEqual(StatusItemPresentationPolicy.triggerEvents, [.leftMouseUp, .rightMouseDown])
    }

    func testHighlightsStatusItemOnlyWhenPanelIsVisible() {
        XCTAssertFalse(StatusItemPresentationPolicy.shouldHighlightStatusItem(isPanelVisible: false))
        XCTAssertTrue(StatusItemPresentationPolicy.shouldHighlightStatusItem(isPanelVisible: true))
    }
}
