import XCTest
@testable import UsageMonitorCore

final class APIClientTests: XCTestCase {
    func testAuthorizationHeaderUsesSharedBuilder() async throws {
        let recorder = RequestRecorder()
        let session = MockHTTPSession(recorder: recorder) { request in
            let body = """
            {"success":true,"code":200,"data":[{"productName":"GLM Coding Max","status":"ACTIVE","nextRenewTime":1715000000000}]}
            """
            return .success(200, body)
        }

        let client = UsageMonitorAPIClient(
            configurationProvider: InMemoryConfigurationProvider(
                configuration: APIConfiguration(baseURLString: "https://api.z.ai")
            ),
            apiKeyProvider: InMemoryAPIKeyProvider(apiKey: "secret-key"),
            headerBuilder: BearerAuthorizationHeaderBuilder(),
            session: session,
            logger: TestLogger()
        )

        _ = try await client.fetchSubscriptions()

        XCTAssertEqual(recorder.requests.count, 1)
        XCTAssertEqual(recorder.requests[0].value(forHTTPHeaderField: "Authorization"), "Bearer secret-key")
    }

    func testRefreshDashboardCombinesSubscriptionAndQuotaResponses() async throws {
        let session = MockHTTPSession { request in
            if request.url?.path == "/api/biz/subscription/list" {
                return .success(200, #"{"success":true,"code":200,"data":[{"productName":"GLM Coding Pro","status":"ACTIVE","nextRenewTime":"2026-02-12"}]}"#)
            }

            return .success(200, #"{"success":true,"code":200,"data":{"limits":[{"type":"TOKENS_LIMIT","unit":"3","number":"5","usage":"1000","currentValue":"500","nextResetTime":"1715000000000"},{"type":"TOKENS_LIMIT","unit":"6","number":"7","usage":"7000","currentValue":"1000","remaining":"6000"},{"type":"TIME_LIMIT","unit":"5","number":"1","usage":"4000","currentValue":"2000","remaining":"2000","usageDetails":[{"modelCode":"search-prime","usage":1000}]}]}}"#)
        }

        let client = UsageMonitorAPIClient(
            configurationProvider: InMemoryConfigurationProvider(
                configuration: APIConfiguration(baseURLString: "https://api.z.ai")
            ),
            apiKeyProvider: InMemoryAPIKeyProvider(apiKey: "secret-key"),
            headerBuilder: BearerAuthorizationHeaderBuilder(),
            session: session,
            logger: TestLogger()
        )

        let snapshot = try await client.refreshDashboard()

        XCTAssertEqual(snapshot.subscription?.planName, "GLM Coding Pro")
        XCTAssertNotNil(snapshot.subscription?.nextRenewal)
        XCTAssertEqual(snapshot.quotas.fiveHourQuota?.percentage, 50)
        XCTAssertEqual(snapshot.quotas.weeklyQuota?.remaining, 6000)
        XCTAssertEqual(snapshot.quotas.mcpMonthlyQuota?.usageDetails.first?.tool, "search-prime")
    }
}
