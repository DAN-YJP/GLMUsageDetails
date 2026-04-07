import Foundation
@testable import UsageMonitorCore

final class TestLogger: Logging, @unchecked Sendable {
    func debug(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}

final class InMemoryConfigurationProvider: ConfigurationProviding, @unchecked Sendable {
    var configuration: APIConfiguration

    init(configuration: APIConfiguration) {
        self.configuration = configuration
    }

    func currentConfiguration() throws -> APIConfiguration {
        configuration
    }
}

final class InMemoryAPIKeyProvider: APIKeyProviding, @unchecked Sendable {
    var apiKey: String?

    init(apiKey: String?) {
        self.apiKey = apiKey
    }

    func loadAPIKey() throws -> String? {
        apiKey
    }

    func saveAPIKey(_ apiKey: String?) throws {
        self.apiKey = apiKey
    }
}

final class InMemorySettingsStore: SettingsStoreProtocol, @unchecked Sendable {
    var baseURLString: String
    var refreshInterval: TimeInterval
    var showCompactSummary: Bool
    var selectedLanguage: AppLanguage
    var showFiveHourSummary: Bool
    var showWeeklySummary: Bool
    var showMCPSummary: Bool
    var launchAtLoginEnabled: Bool

    init(
        baseURLString: String = "https://api.z.ai",
        refreshInterval: TimeInterval = 300,
        showCompactSummary: Bool = true,
        selectedLanguage: AppLanguage = .english,
        showFiveHourSummary: Bool = true,
        showWeeklySummary: Bool = true,
        showMCPSummary: Bool = true,
        launchAtLoginEnabled: Bool = false
    ) {
        self.baseURLString = baseURLString
        self.refreshInterval = refreshInterval
        self.showCompactSummary = showCompactSummary
        self.selectedLanguage = selectedLanguage
        self.showFiveHourSummary = showFiveHourSummary
        self.showWeeklySummary = showWeeklySummary
        self.showMCPSummary = showMCPSummary
        self.launchAtLoginEnabled = launchAtLoginEnabled
    }

    func currentConfiguration() throws -> APIConfiguration {
        APIConfiguration(baseURLString: baseURLString)
    }

    func resetToDefaults() {
        baseURLString = "https://api.z.ai"
        refreshInterval = 300
        showCompactSummary = true
        selectedLanguage = .simplifiedChinese
        showFiveHourSummary = true
        showWeeklySummary = true
        showMCPSummary = true
        launchAtLoginEnabled = false
    }
}

final class MockDashboardService: DashboardServicing, @unchecked Sendable {
    private var results: [Result<DashboardSnapshot, Error>]
    private var index = 0

    init(results: [Result<DashboardSnapshot, Error>]) {
        self.results = results
    }

    func refreshDashboard() async throws -> DashboardSnapshot {
        let result = results[min(index, results.count - 1)]
        index += 1
        return try result.get()
    }
}

final class MockConnectionTestingService: ConnectionTestingService, @unchecked Sendable {
    let result: Result<Void, Error>
    var lastConfiguration: APIConfiguration?
    var lastAPIKey: String?

    init(result: Result<Void, Error>) {
        self.result = result
    }

    func testConnection(configuration: APIConfiguration, apiKey: String?) async throws {
        lastConfiguration = configuration
        lastAPIKey = apiKey
        try result.get()
    }
}

final class RequestRecorder: @unchecked Sendable {
    private(set) var requests: [URLRequest] = []

    func append(_ request: URLRequest) {
        requests.append(request)
    }
}

enum MockResponse {
    case success(Int, String)
}

struct MockHTTPSession: HTTPSessionProtocol, @unchecked Sendable {
    var recorder: RequestRecorder?
    let handler: @Sendable (URLRequest) -> MockResponse

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        recorder?.append(request)
        switch handler(request) {
        case .success(let statusCode, let body):
            let httpResponse = HTTPURLResponse(
                url: request.url ?? URL(string: "https://example.com")!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (Data(body.utf8), httpResponse)
        }
    }
}
