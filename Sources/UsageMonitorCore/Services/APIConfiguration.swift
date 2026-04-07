import Foundation

public struct APIConfiguration: Equatable, Sendable {
    public var baseURLString: String
    public var subscriptionPath: String
    public var quotaPath: String

    public init(
        baseURLString: String = "https://api.z.ai",
        subscriptionPath: String = "/api/biz/subscription/list",
        quotaPath: String = "/api/monitor/usage/quota/limit"
    ) {
        self.baseURLString = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        self.subscriptionPath = subscriptionPath
        self.quotaPath = quotaPath
    }

    public func validatedBaseURL() throws -> URL {
        guard let url = URL(string: baseURLString), url.scheme != nil, url.host != nil else {
            throw UsageMonitorError.invalidBaseURL(baseURLString)
        }
        return url
    }

    public func endpointURL(path: String) throws -> URL {
        let baseURL = try validatedBaseURL()
        guard let url = URL(string: path, relativeTo: baseURL)?.absoluteURL else {
            throw UsageMonitorError.invalidEndpoint(path)
        }
        return url
    }
}

public protocol ConfigurationProviding: Sendable {
    func currentConfiguration() throws -> APIConfiguration
}
