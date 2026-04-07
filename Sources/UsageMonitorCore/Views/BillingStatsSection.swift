import SwiftUI

struct BillingStatsSection: View {
    let stats: BillingStatsSnapshot
    let language: AppLanguage
    let syncState: SyncState
    var onWindowTap: ((TimeWindow) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader

            timeWindowRow(stats.fiveHour, isTappable: true)
            timeWindowRow(stats.oneDay, isTappable: true)
            timeWindowRow(stats.oneWeek, isTappable: true)
            timeWindowRow(stats.oneMonth, isTappable: true)

            syncFooter
        }
        .dashboardCardChrome()
    }

    private var sectionHeader: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "creditcard")
                .foregroundStyle(Color.accentColor)
            Text(AppStrings.billingStats(language: language))
                .font(.headline.weight(.semibold))
            Spacer()
            Text(stats.membershipTier)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                )
        }
    }

    private func timeWindowRow(_ windowStats: UsageWindowStats, isTappable: Bool = false) -> some View {
        HStack(spacing: 10) {
            Text(windowStats.window.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isTappable ? Color.accentColor : .secondary)
                .frame(width: 28, alignment: .leading)

            VStack(alignment: .leading, spacing: 1) {
                Text("\(QuotaFormatter.tokenCount(windowStats.tokenUsage)) \(AppStrings.tokens(language: language))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.primary)
                Text("\(QuotaFormatter.callCount(windowStats.callCount)) \(AppStrings.calls(language: language))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if windowStats.totalCost > 0 {
                Text(QuotaFormatter.cost(windowStats.totalCost))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if let growth = windowStats.growthRate, growth != 0 {
                Text(QuotaFormatter.growthRate(growth))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(growth > 0 ? .orange : .green)
            }

            if isTappable {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            guard isTappable else { return }
            onWindowTap?(windowStats.window)
        }
        .onHover { isHovering in
            if isTappable && isHovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    private var syncFooter: some View {
        VStack(alignment: .leading, spacing: 4) {
            if syncState.isSyncing {
                // Single row: spinner + month text + progress count
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    if let month = syncState.currentBillingMonth {
                        Text(AppStrings.syncingMonth(language: language, month: month))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if syncState.expectedTotal != nil || syncState.fetchedCount > 0 {
                        if let total = syncState.expectedTotal {
                            Text("\(syncState.fetchedCount)/\(total)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.tertiary)
                        } else {
                            Text("\(syncState.fetchedCount)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            } else {
                // Idle / completed / failed row
                HStack(spacing: 6) {
                    Image(systemName: syncIconName)
                        .foregroundStyle(syncState.stage == .failed ? .red : .secondary)
                        .font(.caption2)
                    Text(syncStatusText)
                        .font(.caption2)
                        .foregroundStyle(syncState.stage == .failed ? .red : .secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    if syncState.totalBillsInDB > 0 {
                        Text("\(syncState.totalBillsInDB) records")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .help(syncState.lastError ?? "")
            }
        }
    }

    private var syncIconName: String {
        switch syncState.stage {
        case .idle, .completed: return "checkmark.circle"
        case .fetching, .saving, .clearing: return "arrow.triangle.2.circlepath"
        case .failed: return "exclamationmark.triangle"
        }
    }

    private var syncStatusText: String {
        if syncState.isSyncing {
            // Don't show generic "Refreshing" — the month progress line above is more specific
            return ""
        }
        if let error = syncState.lastError {
            // Truncate long error messages for display; full text available via help tooltip
            let short = error.prefix(60)
            return error.count > 60 ? short + "..." : error
        }
        if let time = syncState.lastSyncTime {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            return "\(AppStrings.lastSync(language: language)) \(formatter.string(from: time))"
        }
        return AppStrings.lastSync(language: language) + ": --"
    }
}
