import AppKit
import SwiftUI
import UsageMonitorCore

@MainActor
final class DashboardPanelController: NSWindowController, NSWindowDelegate {
    private let environment: AppEnvironment
    private weak var statusButton: NSStatusBarButton?

    init(environment: AppEnvironment) {
        self.environment = environment

        let contentView = DashboardView(
            viewModel: environment.dashboardViewModel,
            openSettings: { environment.openSettings() },
            copyDebugInfo: { environment.copyDebugInfo($0) },
            onOpenWeeklyDetail: { window in environment.openWeeklyDetail(for: window) }
        )

        let hostingController = NSHostingController(rootView: contentView)
        hostingController.sizingOptions = .preferredContentSize
        let panel = NSPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: DashboardLayoutMetrics.preferredPanelWidth,
                height: DashboardLayoutMetrics.maxPanelHeight
            ),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .titled],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = hostingController
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.contentMinSize = NSSize(
            width: DashboardLayoutMetrics.preferredPanelWidth,
            height: DashboardLayoutMetrics.minPanelHeight
        )
        panel.contentMaxSize = NSSize(
            width: DashboardLayoutMetrics.preferredPanelWidth,
            height: DashboardLayoutMetrics.maxPanelHeight
        )
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        super.init(window: panel)
        panel.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func toggle(relativeTo statusButton: NSStatusBarButton) {
        self.statusButton = statusButton
        guard let window else { return }
        if window.isVisible {
            window.orderOut(nil)
            updateStatusItemHighlight(false)
        } else {
            positionWindow(relativeTo: statusButton)
            NSApp.activate(ignoringOtherApps: true)
            showWindow(nil)
            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)
            updateStatusItemHighlight(true)
            DispatchQueue.main.async { [weak self, weak statusButton] in
                guard let self, let statusButton else { return }
                self.positionWindow(relativeTo: statusButton)
            }
        }
    }

    func closePanel() {
        window?.orderOut(nil)
        updateStatusItemHighlight(false)
    }

    func windowDidResignKey(_ notification: Notification) {
        updateStatusItemHighlight(false)
    }

    func windowWillClose(_ notification: Notification) {
        updateStatusItemHighlight(false)
    }

    private func positionWindow(relativeTo statusButton: NSStatusBarButton) {
        guard let window, let buttonWindow = statusButton.window else { return }
        let screenRect = buttonWindow.frame
        let visibleFrame = buttonWindow.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let origin = PanelPlacementCalculator.origin(
            forStatusButtonFrame: screenRect,
            panelSize: window.frame.size,
            visibleFrame: visibleFrame
        )
        window.setFrameOrigin(origin)
    }

    private func updateStatusItemHighlight(_ isHighlighted: Bool) {
        guard let statusButton else { return }
        statusButton.highlight(isHighlighted)
    }
}
