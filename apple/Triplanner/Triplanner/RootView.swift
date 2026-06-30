import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: TripStore
    @AppStorage(AppTheme.storageKey) private var themeRawValue = AppTheme.setouchi.rawValue
    @AppStorage(AppDisplaySize.storageKey) private var displaySizeRawValue = AppDisplaySize.comfortable.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: themeRawValue) ?? .setouchi
    }

    private var displaySize: AppDisplaySize {
        AppDisplaySize(rawValue: displaySizeRawValue) ?? .comfortable
    }

    var body: some View {
        Group {
            if store.hasTrip {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .environment(\.appTheme, theme)
        .environment(\.appDisplaySize, displaySize)
        .tint(theme.accent)
    }
}
