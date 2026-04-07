import Foundation

private struct APIEnvelope<T: Decodable>: Decodable {
    let success: Bool?
    let code: Int?
    let message: String?
    let data: T?
}

private struct QuotaPayload: Decodable {
    let limits: [QuotaLimitEntry]?
}

public protocol DashboardServicing: Sendable {
    func refreshDashboard() async throws -> DashboardSnapshot
}

public protocol ConnectionTestingService: Sendable {
    func testConnection(configuration: APIConfiguration, apiKey: String?) async throws
}

public final class UsageMonitorAPIClient: DashboardServicing, ConnectionTestingService, @unchecked Sendable {
    private let configurationProvider: ConfigurationProviding
    private let apiKeyProvider: APIKeyProviding
    private let headerBuilder: AuthorizationHeaderBuilder
    private let session: HTTPSessionProtocol
    private let logger: Logging
    private let decoder: JSONDecoder

    public init(
        configurationProvider: ConfigurationProviding,
        apiKeyProvider: APIKeyProviding,
        headerBuilder: AuthorizationHeaderBuilder = BearerAuthorizationHeaderBuilder(),
        session: HTTPSessionProtocol = URLSession.shared,
        logger: Logging = AppLogger()
    ) {
        self.configurationProvider = configurationProvider
        self.apiKeyProvider = apiKeyProvider
        self.headerBuilder = headerBuilder
        self.session = session
        self.logger = logger
        self.decoder = JSONDecoder()
    }

    public func fetchSubscriptions() async throws -> [SubscriptionTransportItem] {
        let configuration = try configurationProvider.currentConfiguration()
        let apiKey = try apiKeyProvider.loadAPIKey()
        return try await fetchSubscriptions(configuration: configuration, apiKey: apiKey)
    }

    public func fetchQuotaLimits() async throws -> [QuotaLimitEntry] {
        let configuration = try configurationProvider.currentConfiguration()
        let apiKey = try apiKeyProvider.loadAPIKey()
        return try await fetchQuotaLimits(configuration: configuration, apiKey: apiKey)
    }

    public func refreshDashboard() async throws -> DashboardSnapshot {
        let configuration = try configurationProvider.currentConfiguration()
        let apiKey = try apiKeyProvider.loadAPIKey()
        return try await refreshDashboard(configuration: configuration, apiKey: apiKey)
    }

    public func testConnection(configuration: APIConfiguration, apiKey: String?) async throws {
        _ = try await fetchSubscriptions(configuration: configuration, apiKey: apiKey)
        _ = try await fetchQuotaLimits(configuration: configuration, apiKey: apiKey)
    }

    public func refreshDashboard(configuration: APIConfiguration, apiKey: String?) async throws -> DashboardSnapshot {
        async let subscriptions = fetchSubscriptions(configuration: configuration, apiKey: apiKey)
        async let quotas = fetchQuotaLimits(configuration: configuration, apiKey: apiKey)

        let subscriptionItems = try await subscriptions
        let quotaItems = try await quotas
        let selectedSubscription = SubscriptionSelector.selectMostRelevant(from: subscriptionItems)
        let classified = QuotaClassifier.classify(quotaItems)

        logger.debug("quota diagnostics: \(classified.diagnostics.map(\.entrySummary).joined(separator: ", "))")

        return DashboardSnapshot(
            subscription: selectedSubscription,
            quotas: classified,
            refreshedAt: Date()
        )
    }

    private func fetchSubscriptions(configuration: APIConfiguration, apiKey: String?) async throws -> [SubscriptionTransportItem] {
        let request = try buildRequest(url: configuration.endpointURL(path: configuration.subscriptionPath), apiKey: apiKey)
        let envelope: APIEnvelope<[SubscriptionTransportItem]> = try await perform(request)
        return envelope.data ?? []
    }

    private func fetchQuotaLimits(configuration: APIConfiguration, apiKey: String?) async throws -> [QuotaLimitEntry] {
        let request = try buildRequest(url: configuration.endpointURL(path: configuration.quotaPath), apiKey: apiKey)
        let envelope: APIEnvelope<QuotaPayload> = try await perform(request)
        guard let limits = envelope.data?.limits, !limits.isEmpty else {
            throw UsageMonitorError.emptyQuotaData
        }
        return limits
    }

    private func buildRequest(url: URL, apiKey: String?) throws -> URLRequest {
        guard let apiKey, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw UsageMonitorError.missingAPIKey
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(try headerBuilder.authorizationHeader(apiKey: apiKey), forHTTPHeaderField: "Authorization")
        logger.debug("request \(request.httpMethod ?? "GET") \(url.absoluteString) auth=\(Redaction.redactAPIKey(apiKey))")
        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw UsageMonitorError.invalidHTTPResponse
            }

            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw UsageMonitorError.unauthorized
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw UsageMonitorError.apiError("HTTP \(httpResponse.statusCode)")
            }

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw UsageMonitorError.decodingFailure(error.localizedDescription)
            }
        } catch let error as UsageMonitorError {
            logger.error(error.localizedDescription)
            throw error
        } catch let error as URLError {
            logger.error(error.localizedDescription)
            throw UsageMonitorError.networkFailure(error)
        } catch {
            logger.error(error.localizedDescription)
            throw UsageMonitorError.apiError(error.localizedDescription)
        }
    }
}
