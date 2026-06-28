import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedSection: AppSection = .home
    @State private var showingAddCity = false
    @State private var newCity = ""

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
                Section("TRIP") {
                    SidebarTripSummary(
                        city: displayCity(store.currentCity),
                        subtitle: tripSubtitle,
                        cityOptions: store.trip?.cities.map { SidebarCityOption(rawValue: $0, label: displayCity($0)) } ?? [],
                        currentCity: store.currentCity,
                        onSelectCity: { store.selectCity($0) },
                        onAddCity: { showingAddCity = true }
                    )
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 8, trailing: 12))
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
            .alert("지역 추가", isPresented: $showingAddCity) {
                TextField("예: Osaka", text: $newCity)
                Button("추가") {
                    let trimmedCity = newCity.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedCity.isEmpty else { return }
                    store.addCity(trimmedCity)
                    newCity = ""
                }
                Button("취소", role: .cancel) {
                    newCity = ""
                }
            }
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

private struct SidebarCityOption: Identifiable {
    var rawValue: String
    var label: String

    var id: String { rawValue }
}

private struct SidebarTripSummary: View {
    var city: String
    var subtitle: String
    var cityOptions: [SidebarCityOption]
    var currentCity: String
    var onSelectCity: (String) -> Void
    var onAddCity: () -> Void

    var body: some View {
        Menu {
            ForEach(cityOptions) { option in
                Button {
                    onSelectCity(option.rawValue)
                } label: {
                    Label(option.label, systemImage: option.rawValue == currentCity ? "checkmark" : "mappin")
                }
            }
            Divider()
            Button {
                onAddCity()
            } label: {
                Label("지역 추가", systemImage: "plus")
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.teal)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(city)
                        .font(.headline.weight(.black))
                        .lineLimit(1)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
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
        case .map: return "지도"
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
