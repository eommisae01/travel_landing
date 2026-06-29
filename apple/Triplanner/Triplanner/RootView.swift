import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: TripStore
    @AppStorage(AppTheme.storageKey) private var themeRawValue = AppTheme.setouchi.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: themeRawValue) ?? .setouchi
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
        .tint(theme.accent)
    }
}
