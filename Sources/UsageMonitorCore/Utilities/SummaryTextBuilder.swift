import Foundation

public enum SummaryTextBuilder {
    public static func makeSummary(from snapshot: DashboardSnapshot?, options: SummaryDisplayOptions = SummaryDisplayOptions(showFiveHour: true, showWeekly: true, showMCP: true)) -> String {
        guard let snapshot else { return "" }
        var parts: [String] = []

        if options.showFiveHour, let fiveHour = snapshot.quotas.fiveHourQuota, shouldIncludeTokenQuotaInSummary(fiveHour) {
            parts.append("5h \(QuotaFormatter.percentage(fiveHour.percentage))")
        }
        if options.showWeekly, let weekly = snapshot.quotas.weeklyQuota, shouldIncludeTokenQuotaInSummary(weekly) {
            parts.append("W \(QuotaFormatter.percentage(weekly.percentage))")
        }
        if options.showMCP, let mcp = snapshot.quotas.mcpMonthlyQuota {
            parts.append("MCP \(QuotaFormatter.fraction(used: mcp.used, total: mcp.limit))")
        }

        return parts.joined(separator: " | ")
    }

    private static func shouldIncludeTokenQuotaInSummary<T: QuotaSnapshotProtocol>(_ quota: T) -> Bool {
        quota.limit > 0 || quota.used > 0 || quota.remaining > 0 || quota.percentage > 0
    }
}
