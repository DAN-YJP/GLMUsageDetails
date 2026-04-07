import CryptoKit
import Foundation

public final class LocalObfuscatedAPIKeyStore: APIKeyProviding, @unchecked Sendable {
    private struct Payload: Codable {
        let version: Int
        let combinedCiphertext: String
    }

    private let fileURL: URL
    private let fileManager: FileManager
    private let keyMaterial: String
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    public init(
        fileURL: URL? = nil,
        fileManager: FileManager = .default,
        keyMaterial: String? = nil
    ) {
        self.fileManager = fileManager
        self.fileURL = fileURL ?? Self.defaultFileURL(fileManager: fileManager)
        self.keyMaterial = keyMaterial ?? Self.defaultKeyMaterial()
    }

    public func loadAPIKey() throws -> String? {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let payload = try decoder.decode(Payload.self, from: data)
            guard payload.version == 1 else {
                throw UsageMonitorError.apiError("Unsupported API key storage version")
            }
            guard let combinedData = Data(base64Encoded: payload.combinedCiphertext) else {
                throw UsageMonitorError.apiError("Corrupted API key storage")
            }
            let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
            let plaintext = try AES.GCM.open(sealedBox, using: encryptionKey)
            return String(data: plaintext, encoding: .utf8)
        } catch let error as UsageMonitorError {
            throw error
        } catch {
            throw UsageMonitorError.apiError("Local API key read failed: \(error.localizedDescription)")
        }
    }

    public func saveAPIKey(_ apiKey: String?) throws {
        let trimmed = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else {
            try removeStoredAPIKey()
            return
        }

        do {
            try ensureStorageDirectoryExists()
            let plaintext = Data(trimmed.utf8)
            let sealedBox = try AES.GCM.seal(plaintext, using: encryptionKey)
            guard let combined = sealedBox.combined else {
                throw UsageMonitorError.apiError("Failed to seal API key")
            }

            let payload = Payload(version: 1, combinedCiphertext: combined.base64EncodedString())
            let data = try encoder.encode(payload)
            try data.write(to: fileURL, options: [.atomic])
        } catch let error as UsageMonitorError {
            throw error
        } catch {
            throw UsageMonitorError.apiError("Local API key write failed: \(error.localizedDescription)")
        }
    }

    private func removeStoredAPIKey() throws {
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            throw UsageMonitorError.apiError("Local API key delete failed: \(error.localizedDescription)")
        }
    }

    private func ensureStorageDirectoryExists() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }
    }

    private var encryptionKey: SymmetricKey {
        let material = Data(keyMaterial.utf8)
        let digest = SHA256.hash(data: material)
        return SymmetricKey(data: Data(digest))
    }

    private static func defaultKeyMaterial() -> String {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.yyh.UsageMonitorApp"
        let userName = NSUserName()
        let hostName = ProcessInfo.processInfo.hostName
        return "\(bundleIdentifier)|\(userName)|\(hostName)|UsageMonitorAPIKeyV1"
    }

    private static func defaultFileURL(fileManager: FileManager) -> URL {
        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.yyh.UsageMonitorApp"
        return baseDirectory
            .appendingPathComponent(bundleIdentifier, isDirectory: true)
            .appendingPathComponent("api-key.json")
    }
}
