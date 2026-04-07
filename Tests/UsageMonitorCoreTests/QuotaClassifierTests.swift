import XCTest
@testable import UsageMonitorCore

final class QuotaClassifierTests: XCTestCase {
    func testClassifiesExpectedQuotaBuckets() throws {
        let entries = [
            QuotaLimitEntry(
                type: "TOKENS_LIMIT",
                unit: 3,
                number: 5,
                limit: 1000,
                used: 270,
                remaining: nil,
                percentage: nil,
                nextResetTime: Date(timeIntervalSince1970: 1_714_567_890),
                usageDetails: nil,
                metadata: ["bucket": "fiveHour"]
            ),
            QuotaLimitEntry(
                type: "TOKENS_LIMIT",
                unit: 6,
                number: 7,
                limit: 5000,
                used: 650,
                remaining: 4350,
                percentage: 13,
                nextResetTime: nil,
                usageDetails: nil,
                metadata: ["bucket": "weekly"]
            ),
            QuotaLimitEntry(
                type: "TIME_LIMIT",
                unit: 5,
                number: 1,
                limit: 4000,
                used: 1828,
                remaining: nil,
                percentage: nil,
                nextResetTime: Date(timeIntervalSince1970: 1_714_999_999),
                usageDetails: [
                    MCPToolUsageDetail(tool: "search-prime", used: 1200),
                    MCPToolUsageDetail(tool: "web-reader", used: 628)
                ],
                metadata: ["bucket": "mcp"]
            ),
            QuotaLimitEntry(
                type: "TOKENS_LIMIT",
                unit: 2,
                number: 1,
                limit: 999,
                used: 1,
                remaining: 998,
                percentage: 0.1,
                nextResetTime: nil,
                usageDetails: nil,
                metadata: ["bucket": "ignored"]
            )
        ]

        let result = QuotaClassifier.classify(entries)

        XCTAssertEqual(result.fiveHourQuota?.used, 270)
        XCTAssertEqual(result.fiveHourQuota?.remaining, 730)
        XCTAssertEqual(result.fiveHourQuota?.percentage, 27)
        XCTAssertEqual(result.weeklyQuota?.used, 650)
        XCTAssertEqual(result.mcpMonthlyQuota?.usageDetails.map { $0.tool }, ["search-prime", "web-reader"])
        XCTAssertEqual(result.unmatchedEntries.count, 1)
        XCTAssertTrue(result.diagnostics.contains(where: { $0.bucket == QuotaBucket.fiveHour }))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.bucket == QuotaBucket.weekly }))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.bucket == QuotaBucket.mcpMonthly }))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.bucket == QuotaBucket.unmatched }))
    }

    func testClassifiesWeeklyQuotaWhenProviderUsesUnitSixNumberOne() throws {
        let entry = QuotaLimitEntry(
            type: "TOKENS_LIMIT",
            unit: 6,
            number: 1,
            limit: 800000000,
            used: 200000000,
            remaining: 600000000,
            percentage: 25,
            nextResetTime: nil,
            usageDetails: nil,
            metadata: ["source": "provider"]
        )

        let result = QuotaClassifier.classify([entry])

        XCTAssertEqual(result.weeklyQuota?.limit, 800000000)
        XCTAssertEqual(result.weeklyQuota?.used, 200000000)
        XCTAssertEqual(result.unmatchedEntries.count, 0)
        XCTAssertTrue(result.diagnostics.contains(where: { $0.bucket == QuotaBucket.weekly }))
    }

    func testComputesDerivedValuesWhenResponseOmitsThem() throws {
        let entry = QuotaLimitEntry(
            type: "TIME_LIMIT",
            unit: 5,
            number: 1,
            limit: 4000,
            used: 1000,
            remaining: nil,
            percentage: nil,
            nextResetTime: nil,
            usageDetails: nil,
            metadata: [:]
        )

        let result = QuotaClassifier.classify([entry])

        XCTAssertEqual(result.mcpMonthlyQuota?.remaining, 3000)
        XCTAssertEqual(result.mcpMonthlyQuota?.percentage, 25)
    }

    func testDecodesProviderSemanticsForLimitUsageAndRemaining() throws {
        let data = Data(
            """
            {
              "type": "TIME_LIMIT",
              "unit": "5",
              "number": "1",
              "usage": 4000,
              "currentValue": 1828,
              "remaining": 2172,
              "percentage": 45,
              "usageDetails": [
                { "modelCode": "search-prime", "usage": 1433 },
                { "modelCode": "web-reader", "usage": 462 }
              ]
            }
            """.utf8
        )

        let decoded = try JSONDecoder().decode(QuotaLimitEntry.self, from: data)

        XCTAssertEqual(decoded.limit, 4000)
        XCTAssertEqual(decoded.used, 1828)
        XCTAssertEqual(decoded.remaining, 2172)
        XCTAssertEqual(decoded.percentage, 45)
        XCTAssertEqual(decoded.usageDetails?.map { $0.tool }, ["search-prime", "web-reader"])
    }
}
