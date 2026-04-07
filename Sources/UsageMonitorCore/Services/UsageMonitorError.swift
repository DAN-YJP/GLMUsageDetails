import Foundation

public enum UsageMonitorError: Error, LocalizedError, Equatable {
    case missingAPIKey
    case invalidBaseURL(String)
    case invalidEndpoint(String)
    case invalidHTTPResponse
    case unauthorized
    case networkFailure(URLError)
    case emptyQuotaData
    case decodingFailure(String)
    case apiError(String)

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key is missing."
        case .invalidBaseURL(let value):
            return "The API base URL is invalid: \(value)"
        case .invalidEndpoint(let value):
            return "The endpoint path is invalid: \(value)"
        case .invalidHTTPResponse:
            return "The server response was invalid."
        case .unauthorized:
            return "Authorization failed. Check the API key."
        case .networkFailure(let error):
            return "Network request failed: \(error.localizedDescription)"
        case .emptyQuotaData:
            return "No quota data was returned."
        case .decodingFailure(let message):
            return "Response decoding failed: \(message)"
        case .apiError(let message):
            return message
        }
    }
}
