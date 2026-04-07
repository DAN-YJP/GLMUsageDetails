import AppKit
import SwiftUI
import UsageMonitorCore

@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment

        let contentView = SettingsView(
            viewModel: environment.settingsViewModel,
            onSave: {
                environment.saveSettingsAndRefresh()
            },
            onClearLocalData: {
                environment.clearLocalData()
            }
        )

        let hostingController = NSHostingController(rootView: contentView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Settings"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 600, height: 640)
        window.initialFirstResponder = hostingController.view

        super.init(window: window)
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        guard let window else { return }
        // Clear stale feedback from previous session
        environment.settingsViewModel.clearFeedback()
        window.center()
        window.title = AppStrings.settings(language: environment.settingsStore.selectedLanguage)
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        DispatchQueue.main.async { [weak window] in
            guard let window else { return }
            if let contentView = window.contentViewController?.view {
                window.makeFirstResponder(contentView)
            }
        }
    }

    func windowWillClose(_ notification: Notification) {
        environment.persistSettingsWithoutFeedback()
    }
}
