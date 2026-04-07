import Foundation

public protocol AuthorizationHeaderBuilder: Sendable {
    func authorizationHeader(apiKey: String) throws -> String
}

public struct BearerAuthorizationHeaderBuilder: AuthorizationHeaderBuilder, Sendable {
    public init() {}

    public func authorizationHeader(apiKey: String) throws -> String {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw UsageMonitorError.missingAPIKey
        }
        return "Bearer \(trimmed)"
    }
}
