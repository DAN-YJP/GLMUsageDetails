import AppKit
import Combine
import UsageMonitorCore

@MainActor
final class StatusItemController: NSObject {
    private let environment: AppEnvironment
    private let panelController: DashboardPanelController
    private let statusItem: NSStatusItem
    private var cancellables: Set<AnyCancellable> = []

    init(environment: AppEnvironment, panelController: DashboardPanelController) {
        self.environment = environment
        self.panelController = panelController
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureStatusItem()
        bindViewModel()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "chart.bar.doc.horizontal", accessibilityDescription: "Usage Monitor")
        button.imagePosition = .imageLeading
        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseDown])
    }

    private func bindViewModel() {
        environment.dashboardViewModel.$menuBarSummaryText
            .receive(on: RunLoop.main)
            .sink { [weak self] summary in
                self?.statusItem.button?.title = summary.isEmpty ? "" : " \(summary)"
            }
            .store(in: &cancellables)
    }

    @objc private func handleStatusItemClick(_ sender: Any?) {
        if isRightClick(NSApp.currentEvent) {
            showContextMenu()
            return
        }

        guard let button = statusItem.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async { [weak self, weak button] in
            guard let self, let button else { return }
            self.panelController.toggle(relativeTo: button)
        }
    }

    private func showContextMenu() {
        let language = environment.settingsStore.selectedLanguage
        let menu = NSMenu()
        menu.addItem(makeMenuItem(title: AppStrings.refresh(language: language), systemImage: "arrow.clockwise", action: #selector(refreshNow), keyEquivalent: "r"))
        menu.addItem(makeMenuItem(title: AppStrings.settings(language: language), systemImage: "gearshape", action: #selector(openSettingsFromMenu), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(makeMenuItem(title: AppStrings.quit(language: language), systemImage: "xmark.circle", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func refreshNow() {
        environment.refreshNow()
    }

    @objc private func openSettings() {
        environment.openSettings()
    }

    @objc private func openSettingsFromMenu() {
        DispatchQueue.main.async { [weak self] in
            self?.environment.openSettings()
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func isRightClick(_ event: NSEvent?) -> Bool {
        switch event?.type {
        case .rightMouseDown, .rightMouseUp:
            return true
        default:
            return false
        }
    }

    private func makeMenuItem(title: String, systemImage: String, action: Selector, keyEquivalent: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        item.image = NSImage(systemSymbolName: systemImage, accessibilityDescription: title)
        return item
    }
}
