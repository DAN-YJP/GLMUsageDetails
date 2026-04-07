import Foundation

public protocol APIKeyProviding: Sendable {
    func loadAPIKey() throws -> String?
    func saveAPIKey(_ apiKey: String?) throws
}
