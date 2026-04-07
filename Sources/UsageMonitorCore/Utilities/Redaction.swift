import Foundation

public enum Redaction {
    public static func redactAPIKey(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "<empty>" }
        guard value.count > 8 else { return "<redacted>" }
        let prefix = value.prefix(4)
        let suffix = value.suffix(2)
        return "\(prefix)…\(suffix)"
    }
}
