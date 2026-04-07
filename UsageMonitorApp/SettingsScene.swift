import SwiftUI
import UsageMonitorCore

struct SettingsSceneView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let onSave: () -> Void

    var body: some View {
        SettingsView(viewModel: viewModel, onSave: onSave)
    }
}
