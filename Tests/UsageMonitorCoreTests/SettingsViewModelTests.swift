import XCTest
@testable import UsageMonitorCore

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testTestConnectionUsesStoredDefaultBaseURLAndCurrentAPIKey() async throws {
        let settingsStore = InMemorySettingsStore(
            baseURLString: "https://api.z.ai",
            refreshInterval: 60,
            showCompactSummary: true
        )
        let apiKeyStore = InMemoryAPIKeyProvider(apiKey: "abc123")
        let service = MockConnectionTestingService(result: .success(()))

        let viewModel = SettingsViewModel(
            settingsStore: settingsStore,
            apiKeyStore: apiKeyStore,
            connectionTester: service,
            logger: TestLogger()
        )

        viewModel.apiKey = "next-key"

        await viewModel.testConnection()

        XCTAssertEqual(service.lastConfiguration?.baseURLString, "https://api.z.ai")
        XCTAssertEqual(service.lastAPIKey, "next-key")
        XCTAssertEqual(try apiKeyStore.loadAPIKey(), "next-key")
    }

    func testSavePersistsLanguageAndSelectedSummaryBuckets() throws {
        let settingsStore = InMemorySettingsStore(
            baseURLString: "https://api.z.ai",
            refreshInterval: 60,
            showCompactSummary: true
        )
        let apiKeyStore = InMemoryAPIKeyProvider(apiKey: "abc123")
        let service = MockConnectionTestingService(result: .success(()))

        let viewModel = SettingsViewModel(
            settingsStore: settingsStore,
            apiKeyStore: apiKeyStore,
            connectionTester: service,
            logger: TestLogger()
        )

        viewModel.selectedLanguage = .simplifiedChinese
        viewModel.showFiveHourSummary = true
        viewModel.showWeeklySummary = false
        viewModel.showMCPSummary = true

        viewModel.save()

        XCTAssertEqual(settingsStore.selectedLanguage, .simplifiedChinese)
        XCTAssertTrue(settingsStore.showFiveHourSummary)
        XCTAssertFalse(settingsStore.showWeeklySummary)
        XCTAssertTrue(settingsStore.showMCPSummary)
    }

    func testClearLocalDataResetsSettingsAndRemovesStoredAPIKey() async throws {
        let settingsStore = InMemorySettingsStore(
            baseURLString: "https://api.z.ai",
            refreshInterval: 120,
            showCompactSummary: false,
            selectedLanguage: .simplifiedChinese,
            showFiveHourSummary: false,
            showWeeklySummary: false,
            showMCPSummary: true,
            launchAtLoginEnabled: true
        )
        let apiKeyStore = InMemoryAPIKeyProvider(apiKey: "secret-key")
        let service = MockConnectionTestingService(result: .success(()))

        let viewModel = SettingsViewModel(
            settingsStore: settingsStore,
            apiKeyStore: apiKeyStore,
            connectionTester: service,
            logger: TestLogger()
        )

        await viewModel.clearLocalData()

        XCTAssertEqual(viewModel.apiKey, "")
        XCTAssertEqual(settingsStore.baseURLString, "https://api.z.ai")
        XCTAssertEqual(settingsStore.refreshInterval, 300)
        XCTAssertTrue(settingsStore.showCompactSummary)
        XCTAssertEqual(settingsStore.selectedLanguage, .simplifiedChinese)
        XCTAssertTrue(settingsStore.showFiveHourSummary)
        XCTAssertTrue(settingsStore.showWeeklySummary)
        XCTAssertTrue(settingsStore.showMCPSummary)
        XCTAssertFalse(settingsStore.launchAtLoginEnabled)
        XCTAssertNil(try apiKeyStore.loadAPIKey())
    }
}
