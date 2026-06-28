import SwiftUI

struct MainTabView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedSection: AppSection = .home

    var body: some View {
        if horizontalSizeClass == .compact {
            compactTabs
        } else {
            sidebarLayout
        }
    }

    private var compactTabs: some View {
        TabView {
            HomeScreen()
                .tabItem { Label(AppSection.home.title, systemImage: AppSection.home.iconName) }
            ScheduleScreen()
                .tabItem { Label(AppSection.schedule.title, systemImage: AppSection.schedule.iconName) }
            MapScreen()
                .tabItem { Label(AppSection.map.title, systemImage: AppSection.map.iconName) }
            NotesScreen()
                .tabItem { Label(AppSection.notes.title, systemImage: AppSection.notes.iconName) }
            ChecklistScreen()
                .tabItem { Label(AppSection.checklist.title, systemImage: AppSection.checklist.iconName) }
            BudgetScreen()
                .tabItem { Label(AppSection.budget.title, systemImage: AppSection.budget.iconName) }
            SettingsScreen()
                .tabItem { Label(AppSection.settings.title, systemImage: AppSection.settings.iconName) }
        }
    }

    private var sidebarLayout: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $selectedSection) { section in
                Label(section.title, systemImage: section.iconName)
                    .font(.headline.weight(.semibold))
                    .tag(section)
            }
            .navigationTitle("Triplanner")
            .listStyle(.sidebar)
        } detail: {
            selectedSection.view
        }
    }
}

private enum AppSection: String, CaseIterable, Identifiable {
    case home
    case schedule
    case map
    case notes
    case checklist
    case budget
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "홈"
        case .schedule: return "일정"
        case .map: return "지도 / 식당"
        case .notes: return "Notes"
        case .checklist: return "체크리스트"
        case .budget: return "예산"
        case .settings: return "설정"
        }
    }

    var iconName: String {
        switch self {
        case .home: return "house"
        case .schedule: return "calendar"
        case .map: return "map"
        case .notes: return "note.text"
        case .checklist: return "checklist"
        case .budget: return "creditcard"
        case .settings: return "gearshape"
        }
    }

    @ViewBuilder
    var view: some View {
        switch self {
        case .home:
            HomeScreen()
        case .schedule:
            ScheduleScreen()
        case .map:
            MapScreen()
        case .notes:
            NotesScreen()
        case .checklist:
            ChecklistScreen()
        case .budget:
            BudgetScreen()
        case .settings:
            SettingsScreen()
        }
    }
}
