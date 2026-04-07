import Foundation

extension KeyedDecodingContainer {
    func decodeLossyInt(forKey key: K) throws -> Int? {
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return Int(value)
        }
        if let string = try? decodeIfPresent(String.self, forKey: key), let value = Int(string) {
            return value
        }
        return nil
    }

    func decodeLossyDouble(forKeys keys: [K]) throws -> Double? {
        for key in keys {
            if let value = try? decodeIfPresent(Double.self, forKey: key) {
                return value
            }
            if let value = try? decodeIfPresent(Int.self, forKey: key) {
                return Double(value)
            }
            if let string = try? decodeIfPresent(String.self, forKey: key), let value = Double(string) {
                return value
            }
        }
        return nil
    }

    func decodeFlexibleDateIfPresent(forKey key: K) throws -> Date? {
        if let milliseconds = try? decodeIfPresent(Double.self, forKey: key) {
            return Date(timeIntervalSince1970: milliseconds > 10_000_000_000 ? milliseconds / 1000 : milliseconds)
        }
        if let integer = try? decodeIfPresent(Int.self, forKey: key) {
            let value = Double(integer)
            return Date(timeIntervalSince1970: value > 10_000_000_000 ? value / 1000 : value)
        }
        if let string = try? decodeIfPresent(String.self, forKey: key) {
            if let value = Double(string) {
                return Date(timeIntervalSince1970: value > 10_000_000_000 ? value / 1000 : value)
            }
            if let isoDate = ISO8601DateFormatter().date(from: string) {
                return isoDate
            }

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.date(from: string)
        }
        return nil
    }
}
