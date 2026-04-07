import XCTest
@testable import UsageMonitorCore

final class DateFormattingTests: XCTestCase {
    func testFormatsDatesUsingSelectedLanguage() {
        let date = Date(timeIntervalSince1970: 1_715_000_000)

        let english = DateFormatting.string(from: date, language: .english)
        let simplifiedChinese = DateFormatting.string(from: date, language: .simplifiedChinese)

        XCTAssertNotEqual(english, simplifiedChinese)
        XCTAssertTrue(
            simplifiedChinese.contains("年")
                || simplifiedChinese.contains("月")
                || simplifiedChinese.contains("日")
                || simplifiedChinese.contains("今天")
                || simplifiedChinese.contains("昨天")
        )
    }

    func testFormatsUnavailableUsingSelectedLanguage() {
        XCTAssertEqual(DateFormatting.string(from: nil, language: .english), "Unavailable")
        XCTAssertEqual(DateFormatting.string(from: nil, language: .simplifiedChinese), "不可用")
    }
}
