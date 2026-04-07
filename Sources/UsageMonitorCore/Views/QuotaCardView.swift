import SwiftUI

public struct QuotaCardView: View {
    public let model: QuotaCardDisplayModel
    @State private var isDetailsExpanded = false

    public init(model: QuotaCardDisplayModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            progressSection
            statsRow
            footerRow

            if let statusText = model.statusText {
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !model.usageDetails.isEmpty {
                usageDetailsSection
            }
        }
        .dashboardCardChrome()
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.title)
                    .font(.headline.weight(.semibold))
            }

            Spacer()

            Text(model.percentageText)
                .font(.headline.monospacedDigit().weight(.semibold))
                .foregroundStyle(percentageForegroundColor)
                .frame(width: 64, height: 30)
                .background(
                    Capsule(style: .continuous)
                        .fill(percentageBackgroundColor)
                )
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ProgressView(value: model.progress)
                .progressViewStyle(.linear)
        }
    }

    private var statsRow: some View {
        guard shouldShowStatsRow else {
            return AnyView(EmptyView())
        }

        return AnyView(
        HStack(spacing: 10) {
            statTile(label: AppStrings.used(language: model.language), value: model.usedText)
            statTile(label: AppStrings.remaining(language: model.language), value: model.remainingText)
            statTile(label: AppStrings.total(language: model.language), value: model.totalText)
        }
        )
    }

    private var footerRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(.secondary)
            Text(AppStrings.resetTime(language: model.language))
                .foregroundStyle(.secondary)
            Spacer()
            Text(model.resetText)
                .foregroundStyle(.primary)
        }
        .font(.caption2)
    }

    private var usageDetailsSection: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(model.usageDetails, id: \.tool) { detail in
                    HStack {
                        Text(detail.tool)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(QuotaFormatter.format(detail.used))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.primary)
                    }
                    .font(.caption)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.primary.opacity(0.045))
            )
        } label: {
            Text(AppStrings.mcpDetails(language: model.language))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
    }

    private var shouldShowStatsRow: Bool {
        model.id == "mcp-monthly"
    }

    private func statTile(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.monospacedDigit().weight(.medium))
        }
        .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.045))
        )
    }

    private var percentageForegroundColor: Color {
        switch model.percentageSeverity {
        case .good:
            return .green
        case .warning:
            return .orange
        case .danger:
            return .red
        }
    }

    private var percentageBackgroundColor: Color {
        switch model.percentageSeverity {
        case .good:
            return Color.green.opacity(0.14)
        case .warning:
            return Color.orange.opacity(0.16)
        case .danger:
            return Color.red.opacity(0.16)
        }
    }
}
