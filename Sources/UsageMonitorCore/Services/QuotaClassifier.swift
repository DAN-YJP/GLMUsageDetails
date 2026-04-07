import Foundation

public enum QuotaClassifier {
    public static func classify(_ entries: [QuotaLimitEntry]) -> ClassifiedQuotaSnapshot {
        var fiveHour: FiveHourQuota?
        var weekly: WeeklyQuota?
        var mcpMonthly: MCPMonthlyQuota?
        var unmatched: [QuotaLimitEntry] = []
        var diagnostics: [QuotaClassificationDiagnostic] = []

        for entry in entries {
            let bucket = classifyBucket(for: entry)
            diagnostics.append(
                QuotaClassificationDiagnostic(
                    bucket: bucket,
                    entrySummary: "\(entry.type)|unit=\(entry.unit)|number=\(entry.number)",
                    metadata: entry.metadata
                )
            )

            switch bucket {
            case .fiveHour:
                fiveHour = FiveHourQuota(
                    limit: entry.limit,
                    used: entry.used,
                    remaining: normalizedRemaining(for: entry),
                    percentage: normalizedPercentage(for: entry),
                    nextResetTime: entry.nextResetTime,
                    usageDetails: entry.usageDetails ?? [],
                    rawMetadata: entry.metadata
                )
            case .weekly:
                weekly = WeeklyQuota(
                    limit: entry.limit,
                    used: entry.used,
                    remaining: normalizedRemaining(for: entry),
                    percentage: normalizedPercentage(for: entry),
                    nextResetTime: entry.nextResetTime,
                    usageDetails: entry.usageDetails ?? [],
                    rawMetadata: entry.metadata
                )
            case .mcpMonthly:
                mcpMonthly = MCPMonthlyQuota(
                    limit: entry.limit,
                    used: entry.used,
                    remaining: normalizedRemaining(for: entry),
                    percentage: normalizedPercentage(for: entry),
                    nextResetTime: entry.nextResetTime,
                    usageDetails: entry.usageDetails ?? [],
                    rawMetadata: entry.metadata
                )
            case .unmatched:
                unmatched.append(entry)
            }
        }

        return ClassifiedQuotaSnapshot(
            fiveHourQuota: fiveHour,
            weeklyQuota: weekly,
            mcpMonthlyQuota: mcpMonthly,
            unmatchedEntries: unmatched,
            diagnostics: diagnostics
        )
    }

    public static func classifyBucket(for entry: QuotaLimitEntry) -> QuotaBucket {
        switch (entry.type, entry.unit, entry.number) {
        case ("TOKENS_LIMIT", 3, 5):
            return .fiveHour
        case ("TOKENS_LIMIT", 6, 1):
            return .weekly
        case ("TOKENS_LIMIT", 6, 7):
            return .weekly
        case ("TIME_LIMIT", 5, 1):
            return .mcpMonthly
        default:
            return .unmatched
        }
    }

    private static func normalizedRemaining(for entry: QuotaLimitEntry) -> Double {
        if let remaining = entry.remaining {
            return max(remaining, 0)
        }
        return max(entry.limit - entry.used, 0)
    }

    private static func normalizedPercentage(for entry: QuotaLimitEntry) -> Double {
        if let percentage = entry.percentage {
            return percentage
        }
        guard entry.limit > 0 else { return 0 }
        return min(max((entry.used / entry.limit) * 100, 0), 100)
    }
}
