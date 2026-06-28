import SwiftUI

@main
struct TravelPlannerApp: App {
    @StateObject private var store = TripStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}

