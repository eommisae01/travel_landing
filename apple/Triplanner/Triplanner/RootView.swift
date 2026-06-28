import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: TripStore

    var body: some View {
        Group {
            if store.hasTrip {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
    }
}

