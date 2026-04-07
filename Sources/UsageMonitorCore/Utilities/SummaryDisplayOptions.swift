import Foundation

public struct SummaryDisplayOptions: Equatable, Sendable {
    public let showFiveHour: Bool
    public let showWeekly: Bool
    public let showMCP: Bool

    public init(showFiveHour: Bool, showWeekly: Bool, showMCP: Bool) {
        self.showFiveHour = showFiveHour
        self.showWeekly = showWeekly
        self.showMCP = showMCP
    }
}
