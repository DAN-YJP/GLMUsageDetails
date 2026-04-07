import AppKit
import UsageMonitorCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var environment: AppEnvironment!
    private var panelController: DashboardPanelController!
    private var settingsWindowController: SettingsWindowController!
    private var weeklyDetailWindowController: WeeklyDetailWindowController!
    private var statusItemController: StatusItemController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        environment = AppEnvironment()
        panelController = DashboardPanelController(environment: environment)
        settingsWindowController = SettingsWindowController(environment: environment)
        weeklyDetailWindowController = WeeklyDetailWindowController(environment: environment)
        environment.closeDashboardHandler = { [weak self] in
            self?.panelController.closePanel()
        }
        environment.openSettingsHandler = { [weak self] in
            self?.settingsWindowController.show()
        }
        environment.openWeeklyDetailHandler = { [weak self] window in
            self?.weeklyDetailWindowController.show(for: window)
        }
        statusItemController = StatusItemController(environment: environment, panelController: panelController)
        NSApp.activate(ignoringOtherApps: true)
        Self.applyAppearance(environment.settingsStore.themePreference)
        environment.performInitialRefreshIfPossible()
    }

    private static func applyAppearance(_ theme: AppTheme) {
        switch theme {
        case .system: NSApp.appearance = nil
        case .light: NSApp.appearance = NSAppearance(named: .aqua)
        case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
}
