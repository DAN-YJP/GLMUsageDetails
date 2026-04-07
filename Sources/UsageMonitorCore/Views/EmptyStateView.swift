import SwiftUI

public struct EmptyStateView: View {
    public let openSettings: () -> Void
    public let language: AppLanguage

    public init(openSettings: @escaping () -> Void, language: AppLanguage) {
        self.openSettings = openSettings
        self.language = language
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppStrings.connectAccount(language: language))
                .font(.title3.weight(.semibold))
            Text(AppStrings.emptyStateHint(language: language))
                .font(.callout)
                .foregroundStyle(.secondary)
            Button(AppStrings.openSettings(language: language), action: openSettings)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
