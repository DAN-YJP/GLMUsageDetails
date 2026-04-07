import SwiftUI

public struct SettingsView: View {
    @ObservedObject private var viewModel: SettingsViewModel
    private let onSave: (() -> Void)?
    private let onClearLocalData: (() -> Void)?
    @State private var showClearAPIConfirmation = false

    public init(
        viewModel: SettingsViewModel,
        onSave: (() -> Void)? = nil,
        onClearLocalData: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onSave = onSave
        self.onClearLocalData = onClearLocalData
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                menuBarCard
                dashboardCard
                appearanceCard
                apiCard
                footer
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 580, idealWidth: 600, minHeight: 560, idealHeight: 680)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                Image(systemName: "gearshape.2.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(AppStrings.usageMonitorSettings(language: viewModel.selectedLanguage))
                    .font(.title2.weight(.semibold))
                Text(AppStrings.settingsSubtitle(language: viewModel.selectedLanguage))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - API Card

    private var apiCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(AppStrings.apiAccess(language: viewModel.selectedLanguage))
            } icon: {
                Image(systemName: "key.fill")
                    .foregroundStyle(.orange)
            }
            .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text(AppStrings.apiKey(language: viewModel.selectedLanguage))
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 8) {
                    SecureField(AppStrings.pasteAPIKey(language: viewModel.selectedLanguage), text: $viewModel.apiKey)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: viewModel.apiKey) {
                            if !viewModel.keyValidationState.isIdle {
                                viewModel.keyValidationState = .idle
                            }
                        }
                    Button(AppStrings.validateKey(language: viewModel.selectedLanguage)) {
                        Task { await viewModel.validateKey() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.apiKey.isEmpty || viewModel.keyValidationState.isValidating)
                    Button(AppStrings.clear(language: viewModel.selectedLanguage)) {
                        showClearAPIConfirmation = true
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.apiKey.isEmpty)
                    .alert(
                        AppStrings.clearAPIKeyTitle(language: viewModel.selectedLanguage),
                        isPresented: $showClearAPIConfirmation
                    ) {
                        Button(AppStrings.clear(language: viewModel.selectedLanguage), role: .destructive) {
                            Task {
                                await viewModel.clearAPIKeyAndLocalData()
                                onClearLocalData?()
                            }
                        }
                        Button(AppStrings.cancel(language: viewModel.selectedLanguage), role: .cancel) {}
                    } message: {
                        Text(AppStrings.clearAPIKeyMessage(language: viewModel.selectedLanguage))
                    }
                }
                keyValidationBanner
            }

            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(AppStrings.localStorageHint(host: viewModel.defaultBaseURLString, language: viewModel.selectedLanguage))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    // MARK: - Menu Bar Card

    private var menuBarCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(AppStrings.behavior(language: viewModel.selectedLanguage))
            } icon: {
                Image(systemName: "menubar.rectangle")
                    .foregroundStyle(.blue)
            }
            .font(.headline)

            row(
                title: AppStrings.language(language: viewModel.selectedLanguage),
                subtitle: "English / 简体中文"
            ) {
                Picker("", selection: $viewModel.selectedLanguage) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(language.settingsLabel).tag(language)
                    }
                }
                .labelsHidden()
                .frame(width: 130)
            }

            Divider()

            row(
                title: AppStrings.autoRefresh(language: viewModel.selectedLanguage),
                subtitle: AppStrings.autoRefreshHint(language: viewModel.selectedLanguage)
            ) {
                HStack(spacing: 4) {
                    TextField("30", value: $viewModel.refreshInterval, format: .number)
                        .frame(width: 64)
                        .textFieldStyle(.roundedBorder)
                    Text(AppStrings.secondsUnit(language: viewModel.selectedLanguage))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Toggle(isOn: $viewModel.showCompactSummary) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(AppStrings.showMenuBarSummary(language: viewModel.selectedLanguage))
                        .font(.subheadline.weight(.medium))
                    Text(AppStrings.menuBarSummaryHint(language: viewModel.selectedLanguage))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(AppStrings.menuBarContent(language: viewModel.selectedLanguage))
                    .font(.subheadline.weight(.medium))
                Text(AppStrings.menuBarContentHint(language: viewModel.selectedLanguage))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Toggle("5H", isOn: $viewModel.showFiveHourSummary)
                    Toggle("Weekly", isOn: $viewModel.showWeeklySummary)
                    Toggle("MCP", isOn: $viewModel.showMCPSummary)
                }
                .toggleStyle(.checkbox)
            }
            .disabled(!viewModel.showCompactSummary)

            Divider()

            Toggle(isOn: $viewModel.launchAtLoginEnabled) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(AppStrings.launchAtLogin(language: viewModel.selectedLanguage))
                        .font(.subheadline.weight(.medium))
                    Text(AppStrings.launchAtLoginHint(language: viewModel.selectedLanguage))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(true)
        }
        .padding(16)
        .background(cardBackground)
    }

    // MARK: - Appearance Card

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(AppStrings.appearance(language: viewModel.selectedLanguage))
            } icon: {
                Image(systemName: "paintbrush.fill")
                    .foregroundStyle(.purple)
            }
            .font(.headline)

            row(
                title: AppStrings.appearance(language: viewModel.selectedLanguage),
                subtitle: AppStrings.appearanceHint(language: viewModel.selectedLanguage)
            ) {
                Picker("", selection: $viewModel.themePreference) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.settingsLabel).tag(theme)
                    }
                }
                .labelsHidden()
                .frame(width: 130)
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    // MARK: - Dashboard Sections Card

    private var dashboardCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(AppStrings.dashboardSections(language: viewModel.selectedLanguage))
            } icon: {
                Image(systemName: "square.grid.2x2.fill")
                    .foregroundStyle(.green)
            }
            .font(.headline)

            Text(AppStrings.dashboardSectionsHint(language: viewModel.selectedLanguage))
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Toggle(isOn: $viewModel.showFiveHourQuota) {
                    label(AppStrings.fiveHourQuota(language: viewModel.selectedLanguage), icon: "clock.arrow.circlepath")
                }

                Toggle(isOn: $viewModel.showWeeklyQuota) {
                    label(AppStrings.weeklyQuota(language: viewModel.selectedLanguage), icon: "calendar")
                }

                Toggle(isOn: $viewModel.showMCPQuota) {
                    label(AppStrings.mcpQuota(language: viewModel.selectedLanguage), icon: "arrow.triangle.branch")
                }
            }

            Divider()

            Toggle(isOn: $viewModel.showBillingStats) {
                label(AppStrings.billingStatsSection(language: viewModel.selectedLanguage), icon: "chart.bar.fill")
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let feedback = viewModel.feedbackMessage {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text(feedback)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Button(AppStrings.clearLocalData(language: viewModel.selectedLanguage), role: .destructive) {
                    Task {
                        await viewModel.clearLocalData()
                        onClearLocalData?()
                    }
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(AppStrings.testConnection(language: viewModel.selectedLanguage)) {
                    Task { await viewModel.testConnection() }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isTestingConnection)

                Button(AppStrings.save(language: viewModel.selectedLanguage)) {
                    viewModel.save()
                    onSave?()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Helpers

    private func row<Trailing: View>(
        title: String,
        subtitle: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            trailing()
        }
    }

    private func label(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            Text(title)
                .font(.subheadline.weight(.medium))
        }
    }

    @ViewBuilder
    private var keyValidationBanner: some View {
        switch viewModel.keyValidationState {
        case .idle:
            EmptyView()
        case .validating:
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .valid:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
                Text(AppStrings.keyValid(language: viewModel.selectedLanguage))
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        case .invalid(let message):
            HStack(spacing: 6) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var cardBackground: some ShapeStyle {
        .regularMaterial
    }
}
