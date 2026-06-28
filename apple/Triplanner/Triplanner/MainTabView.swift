import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeScreen()
                .tabItem { Label("홈", systemImage: "house") }
            ScheduleScreen()
                .tabItem { Label("일정", systemImage: "calendar") }
            MapScreen()
                .tabItem { Label("지도", systemImage: "map") }
            NotesScreen()
                .tabItem { Label("Notes", systemImage: "note.text") }
            ChecklistScreen()
                .tabItem { Label("체크리스트", systemImage: "checklist") }
            BudgetScreen()
                .tabItem { Label("예산", systemImage: "creditcard") }
            SettingsScreen()
                .tabItem { Label("설정", systemImage: "gearshape") }
        }
    }
}
