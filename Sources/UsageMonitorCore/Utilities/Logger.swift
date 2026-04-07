import Foundation
import os.log

public protocol Logging: Sendable {
    func debug(_ message: @autoclosure () -> String)
    func error(_ message: @autoclosure () -> String)
}

public struct AppLogger: Logging, Sendable {
    public var isEnabled: Bool
    private let logger = Logger(subsystem: "com.yyh.UsageMonitorApp", category: "Billing")

    public init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    public func debug(_ message: @autoclosure () -> String) {
        guard isEnabled else { return }
        let msg = message()
        print("[UsageMonitor][DEBUG] \(msg)")
        logger.debug("\(msg)")
    }

    public func error(_ message: @autoclosure () -> String) {
        guard isEnabled else { return }
        let msg = message()
        print("[UsageMonitor][ERROR] \(msg)")
        logger.error("\(msg)")
    }
}
