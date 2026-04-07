import XCTest
@testable import UsageMonitorCore

final class SubscriptionStatusFormatterTests: XCTestCase {
    func testMapsKnownProviderStatusesToFriendlyCopy() {
        XCTAssertEqual(SubscriptionStatusFormatter.displayText(for: "VALID"), "Active")
        XCTAssertEqual(SubscriptionStatusFormatter.displayText(for: "ACTIVE"), "Active")
        XCTAssertEqual(SubscriptionStatusFormatter.displayText(for: "EXPIRED"), "Expired")
        XCTAssertEqual(SubscriptionStatusFormatter.displayText(for: "CANCELLED"), "Cancelled")
    }

    func testFallsBackToTitleCasedStatusForUnknownProviderValue() {
        XCTAssertEqual(SubscriptionStatusFormatter.displayText(for: "PAUSED_BY_ADMIN"), "Paused By Admin")
    }

    func testUsesUnavailableForMissingStatus() {
        XCTAssertEqual(SubscriptionStatusFormatter.displayText(for: nil), "Unavailable")
        XCTAssertEqual(SubscriptionStatusFormatter.displayText(for: "   "), "Unavailable")
    }
}
