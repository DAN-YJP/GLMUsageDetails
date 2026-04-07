import SwiftUI

public struct DashboardView: View {
    @ObservedObject private var viewModel: DashboardViewModel
    private let openSettings: () -> Void
    private let copyDebugInfo: (String) -> Void
    private var onOpenWeeklyDetail: ((TimeWindow) -> Void)?

    public init(
        viewModel: DashboardViewModel,
        openSettings: @escaping () -> Void,
        copyDebugInfo: @escaping (String) -> Void,
        onOpenWeeklyDetail: ((TimeWindow) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.openSettings = openSettings
        self.copyDebugInfo = copyDebugInfo
        self.onOpenWeeklyDetail = onOpenWeeklyDetail
    }

    public var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 10) {
                header

                if let errorMessage = viewModel.errorMessage {
                    ErrorBannerView(message: errorMessage)
                }

                if viewModel.snapshot == nil {
                    EmptyStateView(openSettings: openSettings, language: viewModel.currentLanguage)
                } else {
                    ForEach(viewModel.visibleQuotaCards) { card in
                        QuotaCardView(model: card)
                    }

                    if viewModel.showBillingStats, let billing = viewModel.billingStats {
                        BillingStatsSection(
                            stats: billing,
                            language: viewModel.currentLanguage,
                            syncState: viewModel.syncState,
                            onWindowTap: { window in
                                onOpenWeeklyDetail?(window)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
            .padding(.top, 4)
        }
        .scrollIndicators(.never)
        .frame(
            minWidth: DashboardLayoutMetrics.preferredPanelWidth,
            maxWidth: DashboardLayoutMetrics.preferredPanelWidth,
            minHeight: DashboardLayoutMetrics.minPanelHeight,
            maxHeight: DashboardLayoutMetrics.maxPanelHeight
        )
        .background(
            LinearGradient(
                colors: [Color(nsColor: .windowBackgroundColor), Color(nsColor: .underPageBackgroundColor)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(0.22),
                                    Color.accentColor.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
                .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 1) {
                    Text(viewModel.planNameText)
                        .font(.headline.weight(.semibold))

                    HStack(spacing: 8) {
                        statusBadge
                        if viewModel.isLoading {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .controlSize(.small)
                                Text(AppStrings.refreshing(language: viewModel.currentLanguage))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                ForEach(viewModel.headerMetadataItems, id: \.title) { item in
                    headerMetadataTile(item)
                }
            }

            HStack(spacing: 6) {
                Button(AppStrings.refresh(language: viewModel.currentLanguage)) {
                    Task { await viewModel.refresh() }
                }
                .buttonStyle(.borderedProminent)

                Button(AppStrings.settings(language: viewModel.currentLanguage), action: openSettings)
                    .buttonStyle(.bordered)

                Button(AppStrings.copyDebugInfo(language: viewModel.currentLanguage)) {
                    copyDebugInfo(viewModel.copyDebugInfo())
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(6)
        .dashboardCardChrome()
    }

    private var statusBadge: some View {
        Text(viewModel.subscriptionStatusText)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.primary.opacity(0.08))
            )
    }

    private func headerMetadataTile(_ item: DashboardHeaderMetadataItem) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Label {
                Text(item.title)
            } icon: {
                Image(systemName: item.symbolName)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(item.value)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.045))
        )
    }
}
