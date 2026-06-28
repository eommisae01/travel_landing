import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: TripStore
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
            List(selection: $selectedSection) {
                Section {
                    SidebarTripSummary(
                        city: displayCity(store.currentCity),
                        subtitle: tripSubtitle
                    )
                    .listRowInsets(EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14))
                }

                Section("메뉴") {
                    ForEach(AppSection.allCases) { section in
                        Label(section.title, systemImage: section.iconName)
                            .font(.headline.weight(.semibold))
                            .tag(section)
                    }
                }
            }
            .navigationTitle("Triplanner")
            .listStyle(.sidebar)
        } detail: {
            selectedSection.view
        }
    }

    private var tripSubtitle: String {
        guard let trip = store.trip else { return "" }
        if let start = trip.startDate, let end = trip.endDate {
            return "\(start.dayLabel) - \(end.dayLabel)"
        }
        return trip.country
    }

    private func displayCity(_ city: String) -> String {
        switch city {
        case "타카마쓰": return "Takamatsu"
        case "나오시마": return "Naoshima"
        case "도쿄": return "Tokyo"
        default: return city.isEmpty ? "Trip" : city
        }
    }
}

private struct SidebarTripSummary: View {
    var city: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(city)
                .font(.title2.weight(.black))
                .lineLimit(1)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
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
