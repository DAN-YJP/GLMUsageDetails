import XCTest
@testable import UsageMonitorCore

final class QuotaPercentageStylingTests: XCTestCase {
    func testAssignsGreenBelowOrEqualEightyPercent() {
        XCTAssertEqual(QuotaPercentageStyling.severity(for: 80), .good)
        XCTAssertEqual(QuotaPercentageStyling.severity(for: 12), .good)
    }

    func testAssignsOrangeBetweenEightyAndNinetyFivePercent() {
        XCTAssertEqual(QuotaPercentageStyling.severity(for: 80.1), .warning)
        XCTAssertEqual(QuotaPercentageStyling.severity(for: 94.9), .warning)
    }

    func testAssignsRedAboveNinetyFivePercent() {
        XCTAssertEqual(QuotaPercentageStyling.severity(for: 95), .danger)
        XCTAssertEqual(QuotaPercentageStyling.severity(for: 95.1), .danger)
        XCTAssertEqual(QuotaPercentageStyling.severity(for: 100), .danger)
    }
}
