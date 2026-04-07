import XCTest
@testable import UsageMonitorCore

final class LocalAPIKeyStoreTests: XCTestCase {
    func testSavesAndLoadsObfuscatedAPIKeyFromLocalFile() throws {
        let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directoryURL.appendingPathComponent("api-key.json")
        let store = LocalObfuscatedAPIKeyStore(
            fileURL: fileURL,
            keyMaterial: "test-seed"
        )

        try store.saveAPIKey("super-secret-key")

        let rawData = try Data(contentsOf: fileURL)
        let rawText = String(decoding: rawData, as: UTF8.self)

        XCTAssertFalse(rawText.contains("super-secret-key"))
        XCTAssertEqual(try store.loadAPIKey(), "super-secret-key")
    }

    func testClearingAPIKeyRemovesLocalFile() throws {
        let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directoryURL.appendingPathComponent("api-key.json")
        let store = LocalObfuscatedAPIKeyStore(
            fileURL: fileURL,
            keyMaterial: "test-seed"
        )

        try store.saveAPIKey("super-secret-key")
        try store.saveAPIKey(nil)

        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertNil(try store.loadAPIKey())
    }
}
