import Foundation

public protocol BillingAPIClientProtocol: Sendable {
    func fetchBills(billingMonth: String, pageNum: Int, pageSize: Int) async throws -> BillingAPIEnvelope
    func fetchAllBills(billingMonth: String, pageSize: Int) async throws -> [BillRow]
}

public final class BillingAPIClient: BillingAPIClientProtocol, @unchecked Sendable {
    private let apiKeyProvider: APIKeyProviding
    private let session: HTTPSessionProtocol
    private let logger: Logging
    private let decoder: JSONDecoder

    private let baseURL = "https://bigmodel.cn/api/finance/expenseBill/expenseBillList"
    private let maxRetries = 3
    private let retryDelay: UInt64 = 1_000_000_000 // 1 second in nanoseconds
    private let minDelayMs: UInt64 = 500
    private let maxDelayMs: UInt64 = 2000

    /// Dedicated URLSession for billing — isolated from quota URLSession,
    /// with a longer default timeout for large data fetches.
    public static let billingSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 600
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    public init(
        apiKeyProvider: APIKeyProviding,
        session: HTTPSessionProtocol? = nil,
        logger: Logging = AppLogger()
    ) {
        self.apiKeyProvider = apiKeyProvider
        self.session = session ?? Self.billingSession
        self.logger = logger
        self.decoder = JSONDecoder()
    }

    public func fetchBills(billingMonth: String, pageNum: Int = 1, pageSize: Int = 100) async throws -> BillingAPIEnvelope {
        let apiKey = try apiKeyProvider.loadAPIKey()
        guard let apiKey, !apiKey.isEmpty else {
            throw UsageMonitorError.missingAPIKey
        }

        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "billingMonth", value: billingMonth),
            URLQueryItem(name: "pageNum", value: String(pageNum)),
            URLQueryItem(name: "pageSize", value: String(pageSize))
        ]

        guard let url = components?.url else {
            throw UsageMonitorError.invalidEndpoint(baseURL)
        }

        return try await performWithRetry(url: url, apiKey: apiKey)
    }

    public func fetchAllBills(billingMonth: String, pageSize: Int = 100) async throws -> [BillRow] {
        var allRows: [BillRow] = []
        var pageNum = 1
        var totalPages: Int? = nil
        let seenBillingNos = NSMutableSet()

        while true {
            let envelope = try await fetchBills(billingMonth: billingMonth, pageNum: pageNum, pageSize: pageSize)

            guard let rows = envelope.rows, !rows.isEmpty else {
                break
            }

            if totalPages == nil, let total = envelope.total {
                totalPages = Int(ceil(Double(total) / Double(pageSize)))
            }

            for row in rows {
                if let billingNo = row.billingNo {
                    if seenBillingNos.contains(billingNo) {
                        continue
                    }
                    seenBillingNos.add(billingNo)
                }
                allRows.append(row)
            }

            if let totalPages, pageNum >= totalPages {
                break
            }

            pageNum += 1
            try await Task.sleep(nanoseconds: randomDelayNanos())
        }

        return allRows
    }

    // MARK: - Private

    private func performWithRetry(url: URL, apiKey: String, attempt: Int = 0) async throws -> BillingAPIEnvelope {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 120

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            if attempt < maxRetries && isRetryable(error: error) {
                logger.debug("Billing API retry \(attempt + 1)/\(maxRetries): \(error.localizedDescription)")
                try await Task.sleep(nanoseconds: retryDelay)
                return try await performWithRetry(url: url, apiKey: apiKey, attempt: attempt + 1)
            }
            throw UsageMonitorError.networkFailure(error)
        } catch {
            throw UsageMonitorError.apiError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UsageMonitorError.invalidHTTPResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw UsageMonitorError.unauthorized
            }
            throw UsageMonitorError.apiError("Billing API HTTP \(httpResponse.statusCode)")
        }

        do {
            let envelope = try decoder.decode(BillingAPIEnvelope.self, from: data)
            if let code = envelope.code, code != 200 {
                throw UsageMonitorError.apiError("Billing API error: \(envelope.msg ?? "unknown")")
            }
            return envelope
        } catch let error as DecodingError {
            let body = String(data: data, encoding: .utf8) ?? "(non-UTF-8)"
            logger.error("Billing API decode error for \(url.absoluteString): \(error)")
            logger.debug("Response body (first 2000 chars): \(String(body.prefix(2000)))")
            throw UsageMonitorError.decodingFailure("Billing API response: \(error.localizedDescription)")
        } catch let error as UsageMonitorError {
            throw error
        } catch {
            throw UsageMonitorError.apiError(error.localizedDescription)
        }
    }

    private func isRetryable(error: Error) -> Bool {
        if let urlError = error as? URLError {
            return [.notConnectedToInternet, .timedOut, .cannotConnectToHost, .cannotFindHost, .networkConnectionLost].contains(urlError.code)
        }
        return false
    }

    private func randomDelayNanos() -> UInt64 {
        let range = maxDelayMs - minDelayMs
        let random = UInt64.random(in: 0...range)
        return (minDelayMs + random) * 1_000_000
    }
}
