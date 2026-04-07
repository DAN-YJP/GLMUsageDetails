import AppKit
import SwiftUI
import UsageMonitorCore

@MainActor
final class WeeklyDetailWindowController: NSWindowController, NSWindowDelegate {
    private let environment: AppEnvironment
    private var currentTimeWindow: TimeWindow = .oneWeek

    init(environment: AppEnvironment) {
        self.environment = environment

        let loadingView = WeeklyDetailLoadingView(language: environment.settingsStore.selectedLanguage)
        let hostingController = NSHostingController(rootView: loadingView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = AppStrings.detailTitle(for: .oneWeek, language: environment.settingsStore.selectedLanguage)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 580, height: 400)

        super.init(window: window)
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(for timeWindow: TimeWindow = .oneWeek) {
        guard let window = self.window else { return }
        currentTimeWindow = timeWindow
        let preferredWidth: CGFloat = timeWindow == .oneMonth ? 1088 : 680
        let frame = window.frame
        let newFrame = NSRect(
            x: frame.origin.x + (frame.width - preferredWidth) / 2,
            y: frame.origin.y + (frame.height - 720) / 2,
            width: preferredWidth,
            height: 720
        )
        window.setFrame(newFrame, display: true)
        window.minSize = NSSize(width: timeWindow == .oneMonth ? 900 : 580, height: 400)
        window.center()
        window.title = AppStrings.detailTitle(for: timeWindow, language: environment.settingsStore.selectedLanguage)
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)

        // Load data asynchronously and update view
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let snapshot = try await environment.dashboardViewModel.loadDetail(for: timeWindow)
                let language = environment.settingsStore.selectedLanguage
                let detailView = WeeklyDetailView(snapshot: snapshot, timeWindow: timeWindow, language: language, onHeightChange: { [weak self] height in
                    guard let self, let window = self.window else { return }
                    let frame = window.frame
                    let newFrame = NSRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: height)
                    if abs(frame.height - height) > 2 {
                        window.setFrame(newFrame, display: true, animate: false)
                        window.center()
                    }
                })
                window.contentViewController = NSHostingController(rootView: detailView)
            } catch {
                let errorView = WeeklyDetailErrorView(message: error.localizedDescription, language: environment.settingsStore.selectedLanguage)
                window.contentViewController = NSHostingController(rootView: errorView)
            }
        }
    }
}

// MARK: - Loading & Error Views

private struct WeeklyDetailLoadingView: View {
    let language: AppLanguage

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text(AppStrings.refreshing(language: language))
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 580, minHeight: 600)
    }
}

private struct WeeklyDetailErrorView: View {
    let message: String
    let language: AppLanguage

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(message)
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(minWidth: 580, minHeight: 600)
    }
}
