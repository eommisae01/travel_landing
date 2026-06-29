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
            CompactMoreScreen()
                .tabItem { Label("더보기", systemImage: "ellipsis.circle") }
        }
    }

    private var sidebarLayout: some View {
        NavigationSplitView {
            List {
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
                        Button {
                            selectedSection = section
                        } label: {
                            SidebarMenuRow(
                                section: section,
                                count: badgeCount(for: section),
                                isSelected: selectedSection == section
                            )
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        .listRowBackground(selectedSection == section ? Color.teal.opacity(0.10) : Color.clear)
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

    private func badgeCount(for section: AppSection) -> Int? {
        switch section {
        case .schedule:
            return store.scheduleItemsForSelectedCity().count
        case .map:
            return store.placesForSelectedCity().count
        case .notes:
            return store.notesForSelectedCity().count
        case .checklist:
            return store.checklist.filter { !$0.isDone }.count
        case .budget:
            return store.expenses.count
        case .home, .settings:
            return nil
        }
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
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(.teal, in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(city)
                        .font(.headline.weight(.black))
                        .lineLimit(1)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption2.weight(.semibold))
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
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

private struct SidebarMenuRow: View {
    var section: AppSection
    var count: Int?
    var isSelected = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: section.iconName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .teal : .secondary)
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(section.title)
                    .font(.subheadline.weight(isSelected ? .bold : .semibold))
                Text(section.sidebarSubtitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if let count {
                Text("\(count)")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(isSelected ? .teal : .secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background((isSelected ? Color.teal : Color.secondary).opacity(0.10), in: Capsule())
            }
        }
        .frame(minHeight: 34, alignment: .center)
    }
}

private struct CompactMoreScreen: View {
    @EnvironmentObject private var store: TripStore

    private var remainingChecklistCount: Int {
        store.checklist.filter { !$0.isDone }.count
    }

    private var totalExpense: Int {
        Int(store.expenses.reduce(0) { $0 + $1.amount })
    }

    private var noteCount: Int {
        store.notesForSelectedCity().count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ScreenHeader(title: "More", subtitle: "공유 전 확인할 여행 관리 허브")

                    MoreSummaryStrip(
                        checklistCount: remainingChecklistCount,
                        expenseTotal: totalExpense,
                        currency: store.trip?.budgetCurrency ?? "JPY",
                        noteCount: noteCount
                    )

                    if let trip = store.trip {
                        MoreTripCard(trip: trip, currentCity: displayCity(store.currentCity))
                    }

                    VStack(spacing: 8) {
                        NavigationLink {
                            ChecklistScreen()
                        } label: {
                            MoreRow(
                                title: "체크리스트",
                                subtitle: "남은 준비 \(remainingChecklistCount)개",
                                iconName: "checklist",
                                tint: .teal
                            )
                        }

                        NavigationLink {
                            BudgetScreen()
                        } label: {
                            MoreRow(
                                title: "예산",
                                subtitle: "현재 지출 \(totalExpense) \(store.trip?.budgetCurrency ?? "JPY")",
                                iconName: "creditcard",
                                tint: .blue
                            )
                        }

                        NavigationLink {
                            SettingsScreen()
                        } label: {
                            MoreRow(
                                title: "설정",
                                subtitle: "항공편, 숙소, 공유 지도",
                                iconName: "gearshape",
                                tint: .purple
                            )
                        }
                    }
                    .appPanel(cornerRadius: 18)
                }
                .readableWidth(680)
                .padding()
            }
            .navigationTitle("더보기")
        }
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

private struct MoreSummaryStrip: View {
    var checklistCount: Int
    var expenseTotal: Int
    var currency: String
    var noteCount: Int

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
            MoreMetric(title: "남은 준비", value: "\(checklistCount)", unit: "개", iconName: "checklist", tint: .teal)
            MoreMetric(title: "지출", value: "\(expenseTotal)", unit: currency, iconName: "creditcard", tint: .blue)
            MoreMetric(title: "자료", value: "\(noteCount)", unit: "개", iconName: "note.text", tint: .purple)
        }
    }
}

private struct MoreTripCard: View {
    var trip: Trip
    var currentCity: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.headline.weight(.bold))
                    .frame(width: 38, height: 38)
                    .foregroundStyle(.white)
                    .background(.teal, in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 3) {
                    Text(currentCity)
                        .font(.headline.weight(.black))
                    Text(trip.cities.map(displayCity).joined(separator: " / "))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Text(trip.country)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.teal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.teal.opacity(0.11), in: Capsule())
            }

            VStack(spacing: 8) {
                MoreTripInfoLine(iconName: "bed.double", title: "숙소", value: trip.accommodation.isEmpty ? "숙소 입력 전" : trip.accommodation)
                if let address = trip.accommodationAddress, !address.isEmpty {
                    MoreTripInfoLine(iconName: "mappin", title: "주소", value: address)
                }
                MoreTripInfoLine(iconName: "map", title: "지도", value: trip.myMapsURL.isEmpty ? "My Maps 링크 없음" : "My Maps 연결됨")
            }
        }
        .appPanel(cornerRadius: 18)
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

private struct MoreTripInfoLine: View {
    var iconName: String
    var title: String
    var value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.caption.weight(.black))
                .foregroundStyle(.teal)
                .frame(width: 22)
            Text(title)
                .font(.caption2.weight(.black))
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)
            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.background.opacity(0.58), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct MoreMetric: View {
    var title: String
    var value: String
    var unit: String
    var iconName: String
    var tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(value)
                        .font(.headline.weight(.black))
                    Text(unit)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .padding(9)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.quaternary)
        }
    }
}

private struct MoreRow: View {
    var title: String
    var subtitle: String
    var iconName: String
    var tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.bold))
                .frame(width: 34, height: 34)
                .foregroundStyle(.white)
                .background(tint, in: RoundedRectangle(cornerRadius: 11))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.weight(.black))
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 50, alignment: .center)
        .padding(10)
        .background(.background.opacity(0.64), in: RoundedRectangle(cornerRadius: 13))
        .overlay {
            RoundedRectangle(cornerRadius: 13)
                .stroke(.quaternary)
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
        case .map: return "지도"
        case .notes: return "Notes"
        case .checklist: return "체크리스트"
        case .budget: return "Budget"
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

    var sidebarSubtitle: String {
        switch self {
        case .home: return "오늘 볼 것"
        case .schedule: return "타임라인"
        case .map: return "장소 후보"
        case .notes: return "자료 보드"
        case .checklist: return "준비 항목"
        case .budget: return "지출 관리"
        case .settings: return "여행 정보"
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
