import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.appTheme) private var theme
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
                        title: activeTripTitle,
                        subtitle: tripSubtitle,
                        cityOptions: cityOptions,
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
                        .listRowInsets(EdgeInsets(top: 2, leading: 10, bottom: 2, trailing: 10))
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .navigationTitle("Triplanner")
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 300, ideal: 326, max: 350)
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

    private var activeTripTitle: String {
        guard let trip = store.trip else { return "Trip" }
        return store.currentCity.isEmpty ? trip.name : displayCity(store.currentCity)
    }

    private var tripSubtitle: String {
        guard let trip = store.trip else { return "" }
        let scope = store.currentCity.isEmpty ? "All Trip" : displayCity(store.currentCity)
        if let start = trip.startDate, let end = trip.endDate {
            return "\(scope) · \(start.dayLabel) - \(end.dayLabel)"
        }
        return "\(scope) · \(trip.country)"
    }

    private var cityOptions: [SidebarCityOption] {
        guard let trip = store.trip else { return [] }
        return [SidebarCityOption(rawValue: "", label: "All Trip")]
            + trip.cities.map { SidebarCityOption(rawValue: $0, label: displayCity($0)) }
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
        default: return city.isEmpty ? "All Trip" : city
        }
    }
}

private struct SidebarCityOption: Identifiable {
    var rawValue: String
    var label: String

    var id: String { rawValue }
}

private struct SidebarTripSummary: View {
    @Environment(\.appTheme) private var theme
    var title: String
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
                    Label(option.label, systemImage: option.rawValue == currentCity ? "checkmark" : (option.rawValue.isEmpty ? "square.grid.2x2" : "mappin"))
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
                    .font(.system(size: 25, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(theme.accent, in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 27, weight: .black, design: .rounded))
                        .lineLimit(1)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}

private struct SidebarMenuRow: View {
    @Environment(\.appTheme) private var theme
    var section: AppSection
    var count: Int?
    var isSelected = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: section.iconName)
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(isSelected ? theme.accent : .secondary)
                .frame(width: 46, height: 46)
                .background((isSelected ? theme.accent : Color.secondary).opacity(isSelected ? 0.12 : 0.055), in: RoundedRectangle(cornerRadius: 13))

            VStack(alignment: .leading, spacing: 2) {
                Text(section.title)
                    .font(.system(size: 23, weight: isSelected ? .black : .semibold, design: .rounded))
                Text(section.sidebarSubtitle)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if let count {
                Text("\(count)")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(isSelected ? theme.accent : .secondary)
                    .monospacedDigit()
                    .frame(minWidth: 26)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background((isSelected ? theme.accent : Color.secondary).opacity(0.10), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(isSelected ? theme.accent.opacity(0.075) : Color.clear, in: RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .leading) {
            if isSelected {
                RoundedRectangle(cornerRadius: 2)
                    .fill(theme.accent)
                    .frame(width: 3)
                    .padding(.vertical, 9)
            }
        }
    }
}

private struct CompactMoreScreen: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.appTheme) private var theme

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
                    CompactMoreHeader(currentCity: displayCity(store.currentCity))

                    MoreSummaryStrip(
                        checklistCount: remainingChecklistCount,
                        expenseTotal: totalExpense,
                        currency: store.trip?.budgetCurrency ?? "JPY",
                        noteCount: noteCount
                    )

                    if let trip = store.trip {
                        MoreTripCard(trip: trip, currentCity: displayCity(store.currentCity))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(title: "CONTROLS")

                        NavigationLink {
                            ChecklistScreen()
                        } label: {
                            MoreActionRow(
                                title: "체크리스트",
                                subtitle: "남은 준비 \(remainingChecklistCount)개",
                                iconName: "checklist",
                                tint: theme.accent
                            )
                        }

                        NavigationLink {
                            BudgetScreen()
                        } label: {
                            MoreActionRow(
                                title: "Budget",
                                subtitle: "현재 지출 \(totalExpense) \(store.trip?.budgetCurrency ?? "JPY")",
                                iconName: "creditcard",
                                tint: theme.secondaryAccent
                            )
                        }

                        NavigationLink {
                            SettingsScreen()
                        } label: {
                            MoreActionRow(
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
            .navigationTitle("More")
        }
        .appScreenBackground()
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

private struct CompactMoreHeader: View {
    @Environment(\.appTheme) private var theme
    var currentCity: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "ellipsis.circle.fill")
                .font(.title2.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(theme.accent, in: RoundedRectangle(cornerRadius: 15))

            VStack(alignment: .leading, spacing: 3) {
                Text("More")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .lineLimit(1)
                Text("\(currentCity) controls")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MoreSummaryStrip: View {
    @Environment(\.appTheme) private var theme
    var checklistCount: Int
    var expenseTotal: Int
    var currency: String
    var noteCount: Int

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
            MoreMetric(title: "남은 준비", value: "\(checklistCount)", unit: "개", iconName: "checklist", tint: theme.accent)
            MoreMetric(title: "지출", value: "\(expenseTotal)", unit: currency, iconName: "creditcard", tint: theme.secondaryAccent)
            MoreMetric(title: "자료", value: "\(noteCount)", unit: "개", iconName: "note.text", tint: .purple)
        }
    }
}

private struct MoreTripCard: View {
    @Environment(\.appTheme) private var theme
    var trip: Trip
    var currentCity: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.subheadline.weight(.black))
                    .frame(width: 36, height: 36)
                    .foregroundStyle(.white)
                    .background(theme.accent, in: RoundedRectangle(cornerRadius: 12))
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
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.accent.opacity(0.11), in: Capsule())
            }

            VStack(spacing: 7) {
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
    @Environment(\.appTheme) private var theme
    var iconName: String
    var title: String
    var value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.caption.weight(.black))
                .foregroundStyle(theme.accent)
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

private struct MoreActionRow: View {
    var title: String
    var subtitle: String
    var iconName: String
    var tint: Color

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.black))
                .frame(width: 34, height: 34)
                .foregroundStyle(tint)
                .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.black))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .center)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.background.opacity(0.58), in: RoundedRectangle(cornerRadius: 13))
        .overlay {
            RoundedRectangle(cornerRadius: 13)
                .stroke(tint.opacity(0.18))
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
