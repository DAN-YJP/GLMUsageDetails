import SwiftUI

struct DashboardCardChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06))
            )
    }
}

extension View {
    func dashboardCardChrome() -> some View {
        modifier(DashboardCardChrome())
    }
}
