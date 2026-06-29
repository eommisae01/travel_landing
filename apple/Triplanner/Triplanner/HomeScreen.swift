import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct HomeScreen: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.appTheme) private var theme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showingAddCity = false
    @State private var newCity = ""
    @State private var showingChecklistSummary = false

    private var undoneChecklistCount: Int {
        store.checklist.filter { !$0.isDone }.count
    }

    private var expenseTotal: Int {
        Int(store.expenses.reduce(0) { $0 + $1.amount })
    }

    private var cityScheduleItems: [ScheduleItem] {
        store.scheduleItemsForSelectedCity()
    }

    private var cityNotes: [NoteGroup] {
        store.notesForSelectedCity()
    }

    private var focusDate: Date? {
        let calendar = Calendar.current
        if let trip = store.trip,
           let start = trip.startDate,
           let end = trip.endDate {
            let today = calendar.startOfDay(for: Date())
            let startDay = calendar.startOfDay(for: start)
            let endDay = calendar.startOfDay(for: end)
            if today >= startDay && today <= endDay {
                return today
            }
        }
        return cityScheduleItems.first.map { calendar.startOfDay(for: $0.date) }
    }

    private var focusItems: [ScheduleItem] {
        guard let focusDate else { return Array(cityScheduleItems.prefix(5)) }
        return cityScheduleItems.filter { Calendar.current.isDate($0.date, inSameDayAs: focusDate) }
    }

    private var focusNotes: [NoteGroup] {
        let relevantNotes = cityNotes.filter { note in
            guard !focusItems.isEmpty else { return true }
            let noteText = normalized(note.title + " " + note.body)
            return focusItems.contains { item in
                noteText.contains(normalized(item.title))
                || (!item.placeName.isEmpty && noteText.contains(normalized(item.placeName)))
                || (!item.kind.rawValue.isEmpty && noteText.contains(normalized(item.kind.rawValue)))
                || (!item.sourceMapNote.isEmpty && noteText.contains(normalized(item.sourceMapNote)))
            }
        }
        return relevantNotes.isEmpty ? Array(cityNotes.prefix(2)) : relevantNotes
    }

    private var isWideLayout: Bool {
        horizontalSizeClass != .compact
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let trip = store.trip {
                    if isWideLayout {
                        VStack(alignment: .leading, spacing: 16) {
                            cityHero(trip)
                            travelPanel(trip)

                            HStack(alignment: .top, spacing: 14) {
                                VStack(alignment: .leading, spacing: 14) {
                                    statusStrip
                                    todayPanel
                                }
                                .frame(maxWidth: .infinity)

                                notesPanel
                                    .frame(maxWidth: 420)
                            }
                        }
                        .readableWidth(1160)
                        .padding(22)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            cityHero(trip)
                            travelPanel(trip)
                            statusStrip
                            todayPanel
                            notesPanel
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("")
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
            .sheet(isPresented: $showingChecklistSummary) {
                ChecklistSummarySheet()
                    .environmentObject(store)
            }
        }
        .appScreenBackground()
    }

    private func cityHero(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: isWideLayout ? 16 : 14) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 7) {
                        Text("TRIP")
                            .font(.caption.weight(.black))
                            .foregroundStyle(.secondary)
                            .tracking(1.3)
                        if let dateRange = dateRange(for: trip) {
                            Text(dateRange)
                                .font(.caption2.weight(.black))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(.background.opacity(0.62), in: Capsule())
                        }
                    }
                    cityMenu
                }

                Spacer(minLength: 12)

                CityCountBadge(count: store.trip?.cities.count ?? 0, tint: theme.accent)
            }

            CityChipRail(
                cities: trip.cities,
                currentCity: store.currentCity,
                onSelect: store.selectCity
            )

            HeroTodayLine(
                title: todaySummary,
                scheduleCount: focusItems.count,
                noteCount: focusNotes.count,
                accent: theme.accent,
                secondaryAccent: theme.secondaryAccent
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, isWideLayout ? 24 : 20)
        .padding(.vertical, isWideLayout ? 20 : 18)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.accent.opacity(0.18),
                            theme.warmAccent.opacity(0.08),
                            Color.secondary.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        }
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.accent)
                .frame(width: 5)
                .padding(.vertical, 18)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(.quaternary)
        }
    }

    private func travelPanel(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("FLIGHTS & STAY")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
                Spacer()
                Label("Copy ready", systemImage: "doc.on.doc")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.accent.opacity(0.10), in: Capsule())
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    FlightSummaryRow(
                        title: "가는 편",
                        flight: trip.outbound,
                        iconName: "airplane.departure",
                        tint: theme.accent,
                        isCompact: true
                    )
                    FlightSummaryRow(
                        title: "오는 편",
                        flight: trip.inbound,
                        iconName: "airplane.arrival",
                        tint: theme.secondaryAccent,
                        isCompact: true
                    )
                    AccommodationSummaryRow(trip: trip, isCompact: true)
                }

                VStack(spacing: 8) {
                    FlightSummaryRow(
                        title: "가는 편",
                        flight: trip.outbound,
                        iconName: "airplane.departure",
                        tint: theme.accent
                    )
                    FlightSummaryRow(
                        title: "오는 편",
                        flight: trip.inbound,
                        iconName: "airplane.arrival",
                        tint: theme.secondaryAccent
                    )
                    AccommodationSummaryRow(trip: trip)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(.quaternary)
        }
    }

    private var statusStrip: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 154), spacing: 10)], spacing: 10) {
            StatButton(title: "남은 준비", value: "\(undoneChecklistCount)", unit: "개", iconName: "checklist", tint: theme.accent) {
                showingChecklistSummary = true
            }
            StatChip(title: "지출", value: "\(expenseTotal)", unit: store.trip?.budgetCurrency ?? "JPY", iconName: "creditcard", tint: theme.secondaryAccent)
        }
    }

    private var todayPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionTitle("TODAY")
                Spacer()
                Text(todaySummary)
                    .font(.caption2.weight(.black))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.10), in: Capsule())
                    .foregroundStyle(.secondary)
            }
            if focusItems.isEmpty {
                EmptyStateView(
                    title: "오늘 일정이 비어있어요",
                    message: "장소나 이동 계획을 일정에 추가하면 여기서 바로 보입니다.",
                    iconName: "calendar"
                )
            } else {
                ForEach(focusItems.prefix(5)) { item in
                    CompactScheduleRow(item: item)
                }
            }
        }
        .panelStyle()
    }

    private var notesPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionTitle("TODAY NOTES")
                Spacer()
                Text(focusDate.map(compactDateLabel) ?? "전체")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.10), in: Capsule())
            }
            if focusNotes.isEmpty {
                EmptyStateView(
                    title: "오늘 볼 자료가 없어요",
                    message: "시간표, 예약 캡처, 현장 메모를 Notes에 모아두세요.",
                    iconName: "note.text"
                )
            } else {
                ForEach(focusNotes.prefix(3)) { note in
                    NavigationLink {
                        NoteDetailView(note: note)
                    } label: {
                        CompactNoteCard(note: note)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .panelStyle()
    }

    private var cityMenu: some View {
        Menu {
            if let trip = store.trip {
                Button {
                    store.selectCity("")
                } label: {
                    Label("All Trip", systemImage: store.currentCity.isEmpty ? "checkmark" : "square.grid.2x2")
                }
                ForEach(trip.cities, id: \.self) { city in
                    Button {
                        store.selectCity(city)
                    } label: {
                        Label(cityDisplayName(city), systemImage: store.currentCity == city ? "checkmark" : "mappin")
                    }
                }
                Divider()
            }
            Button {
                showingAddCity = true
            } label: {
                Label("지역 추가", systemImage: "plus")
            }
        } label: {
            HStack(alignment: .center, spacing: 8) {
                Text(currentScopeTitle)
                    .font(.system(size: isWideLayout ? 58 : 40, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.70)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var currentScopeTitle: String {
        if store.currentCity.isEmpty {
            return store.trip?.name ?? "All Trip"
        }
        return cityDisplayName(store.currentCity)
    }

    private func dateRange(for trip: Trip) -> String? {
        guard let start = trip.startDate, let end = trip.endDate else { return nil }
        return "\(start.dayLabel) - \(end.dayLabel)"
    }

    private var todaySummary: String {
        guard let focusDate else { return "\(focusItems.count)개" }
        return "\(compactDateLabel(focusDate)) · \(focusItems.count)개"
    }

    private func compactDateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M.d E"
        return formatter.string(from: date)
    }

    private func cityDisplayName(_ city: String) -> String {
        switch city {
        case "타카마쓰": return "Takamatsu"
        case "나오시마": return "Naoshima"
        case "도쿄": return "Tokyo"
        case "오사카": return "Osaka"
        case "후쿠오카": return "Fukuoka"
        case "삿포로": return "Sapporo"
        case "교토": return "Kyoto"
        case "서울": return "Seoul"
        default: return city.isEmpty ? "All Trip" : city
        }
    }

    private func normalized(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.black))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct FlightSummaryRow: View {
    var title: String
    var flight: FlightInfo
    var iconName: String
    var tint: Color
    var isCompact = false

    var body: some View {
        Button {
            copyToClipboard(flight.flightNumber.isEmpty ? "\(flight.origin) \(flight.destination)" : flight.flightNumber)
        } label: {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: iconName)
                    .font(.subheadline.weight(.black))
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(tint)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.caption.weight(.black))
                            .foregroundStyle(tint)
                        Text(flight.flightNumber.isEmpty ? "편명 입력 전" : flight.flightNumber)
                            .font(.caption.weight(.black))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(tint.opacity(0.12), in: Capsule())
                            .foregroundStyle(tint)
                    }
                    Text(routeText)
                        .font(.subheadline.weight(.black))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 7) {
                            RouteTimeBadge(title: "출발", city: flight.origin, time: flight.localDeparture, tint: tint)
                            RouteTimeBadge(title: "도착", city: flight.destination, time: flight.localArrival, tint: tint)
                        }
                        VStack(alignment: .leading, spacing: 5) {
                            RouteTimeBadge(title: "출발", city: flight.origin, time: flight.localDeparture, tint: tint)
                            RouteTimeBadge(title: "도착", city: flight.destination, time: flight.localArrival, tint: tint)
                        }
                    }
                }
                Spacer(minLength: 6)
                Image(systemName: "doc.on.doc")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: isCompact ? 112 : 82, alignment: .leading)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(.background.opacity(0.66), in: RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 14)
                .fill(tint)
                .frame(width: 4)
                .padding(.vertical, 9)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.quaternary)
        }
    }

    private var routeText: String {
        "\(flight.origin.isEmpty ? "출발지" : flight.origin) → \(flight.destination.isEmpty ? "도착지" : flight.destination)"
    }
}

private struct RouteTimeBadge: View {
    var title: String
    var city: String
    var time: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.black))
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Text(city.isEmpty ? "미정" : city)
                    .lineLimit(1)
                Text(time.isEmpty ? "--:--" : time)
                    .monospacedDigit()
            }
            .font(.caption.weight(.black))
            .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 9))
    }
}

private struct AccommodationSummaryRow: View {
    var trip: Trip
    var isCompact = false

    var body: some View {
        Button {
            copyToClipboard(trip.accommodationAddress ?? trip.accommodation)
        } label: {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "bed.double")
                    .font(.subheadline.weight(.black))
                    .frame(width: 34, height: 34)
                    .background(.purple.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.purple)

                VStack(alignment: .leading, spacing: 4) {
                    Text("숙소")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.purple)
                    Text(trip.accommodation.isEmpty ? "숙소 입력 전" : trip.accommodation)
                        .font(.subheadline.weight(.black))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    if let address = trip.accommodationAddress, !address.isEmpty {
                        Text(address)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 6)
                Image(systemName: "doc.on.doc")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: isCompact ? 112 : 82, alignment: .leading)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(.background.opacity(0.66), in: RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 14)
                .fill(.purple)
                .frame(width: 4)
                .padding(.vertical, 9)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.quaternary)
        }
    }
}

private struct TimeBadge: View {
    var title: String
    var value: String

    var body: some View {
        HStack(spacing: 3) {
            Text(title)
                .font(.caption2.weight(.black))
                .foregroundStyle(.secondary)
            Text(value.isEmpty ? "--:--" : value)
                .font(.caption.weight(.black))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(.secondary.opacity(0.10), in: Capsule())
    }
}

private struct StatButton: View {
    var title: String
    var value: String
    var unit: String
    var iconName: String
    var tint: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            StatChipContent(title: title, value: value, unit: unit, iconName: iconName, tint: tint)
        }
        .buttonStyle(.plain)
    }
}

private struct StatChip: View {
    var title: String
    var value: String
    var unit: String
    var iconName: String
    var tint: Color

    var body: some View {
        StatChipContent(title: title, value: value, unit: unit, iconName: iconName, tint: tint)
    }
}

private struct StatChipContent: View {
    var title: String
    var value: String
    var unit: String
    var iconName: String
    var tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.headline.weight(.bold))
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(value)
                        .font(.title3.weight(.black))
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                    Text(unit)
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 58, maxHeight: 58, alignment: .leading)
        .padding(11)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary)
        }
    }
}

private struct CityCountBadge: View {
    var count: Int
    var tint: Color

    var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            Image(systemName: "map.fill")
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(tint, in: RoundedRectangle(cornerRadius: 13))
            Text("\(count) cities")
                .font(.caption2.weight(.black))
                .foregroundStyle(.secondary)
        }
    }
}

private struct CityChipRail: View {
    @Environment(\.appTheme) private var theme
    var cities: [String]
    var currentCity: String
    var onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                scopeChip(title: "All Trip", value: "", isSelected: currentCity.isEmpty)
                ForEach(cities, id: \.self) { city in
                    scopeChip(title: displayName(city), value: city, isSelected: city == currentCity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func scopeChip(title: String, value: String, isSelected: Bool) -> some View {
        Button {
            onSelect(value)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "mappin.circle")
                    .font(.caption2.weight(.black))
                Text(title)
                    .font(.caption.weight(.black))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? theme.accent : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background((isSelected ? theme.accent : Color.secondary).opacity(isSelected ? 0.13 : 0.08), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(isSelected ? theme.accent.opacity(0.22) : Color.secondary.opacity(0.08))
            }
        }
        .buttonStyle(.plain)
    }

    private func displayName(_ city: String) -> String {
        switch city {
        case "타카마쓰": return "Takamatsu"
        case "나오시마": return "Naoshima"
        case "도쿄": return "Tokyo"
        case "오사카": return "Osaka"
        case "후쿠오카": return "Fukuoka"
        case "삿포로": return "Sapporo"
        case "교토": return "Kyoto"
        case "서울": return "Seoul"
        default: return city.isEmpty ? "Trip" : city
        }
    }
}

private struct HeroTodayLine: View {
    var title: String
    var scheduleCount: Int
    var noteCount: Int
    var accent: Color
    var secondaryAccent: Color

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "sun.max.fill")
                .font(.subheadline.weight(.black))
                .foregroundStyle(secondaryAccent)
                .frame(width: 30, height: 30)
                .background(secondaryAccent.opacity(0.13), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text("TODAY")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.subheadline.weight(.black))
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            HeroCountPill(title: "일정", value: scheduleCount, tint: accent)
            HeroCountPill(title: "Notes", value: noteCount, tint: secondaryAccent)
        }
        .frame(maxWidth: .infinity, minHeight: 46, alignment: .center)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.background.opacity(0.58), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.quaternary)
        }
    }
}

private struct HeroCountPill: View {
    var title: String
    var value: Int
    var tint: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption2.weight(.black))
            Text("\(value)")
                .font(.caption.weight(.black))
                .monospacedDigit()
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(tint.opacity(0.11), in: Capsule())
    }
}

private struct CompactScheduleRow: View {
    @Environment(\.appTheme) private var theme
    var item: ScheduleItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.startTime.isEmpty ? item.kind.rawValue : item.startTime)
                    .font(.caption.weight(.black))
                    .foregroundStyle(kindColor)
                    .lineLimit(1)
                if !item.endTime.isEmpty {
                    Text(item.endTime)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 52)

            Circle()
                .fill(kindColor)
                .frame(width: 8, height: 8)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.title)
                        .font(.subheadline.weight(.black))
                        .lineLimit(1)
                    Text(item.kind.rawValue)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(kindColor)
                }
                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .center)
        .background(kindColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(kindColor.opacity(0.10))
        }
    }

    private var kindColor: Color {
        switch item.kind {
        case .move: return .blue
        case .food: return .orange
        case .flight: return .purple
        case .place: return theme.accent
        }
    }
}

private struct CompactNoteCard: View {
    @Environment(\.appTheme) private var theme
    var note: NoteGroup

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "doc.text.image")
                .font(.subheadline.weight(.bold))
                .frame(width: 30, height: 30)
                .background(theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
                .foregroundStyle(theme.accent)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(note.title)
                        .font(.subheadline.weight(.black))
                        .lineLimit(1)
                    if !note.imageNames.isEmpty {
                        Label("\(note.imageNames.count)", systemImage: "photo")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(theme.accent)
                    }
                }
                Text(note.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 6)
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.black))
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.background.opacity(0.62), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.quaternary)
        }
    }
}

private extension View {
    func panelStyle() -> some View {
        self
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.quaternary)
            }
    }
}

private struct ChecklistSummarySheet: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    private var remaining: [ChecklistItem] {
        store.checklist.filter { !$0.isDone }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ScreenHeader(title: "남은 준비", subtitle: "\(remaining.count)개 항목")

                    if remaining.isEmpty {
                        EmptyStateView(
                            title: "남은 준비 없음",
                            message: "지금 상태로는 출발 준비가 깔끔합니다.",
                            iconName: "checkmark.circle"
                        )
                    } else {
                        VStack(spacing: 6) {
                            ForEach(remaining) { item in
                                HStack(spacing: 10) {
                                    Image(systemName: "circle")
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 28, height: 28)
                                    Text(item.title)
                                        .font(.subheadline.weight(.semibold))
                                        .lineLimit(2)
                                    Spacer()
                                    Text(item.owner)
                                        .font(.caption.weight(.black))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(ownerTint(item.owner).opacity(0.12), in: Capsule())
                                        .foregroundStyle(ownerTint(item.owner))
                                }
                                .frame(maxWidth: .infinity, minHeight: 42, alignment: .center)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.background.opacity(0.62), in: RoundedRectangle(cornerRadius: 11))
                            }
                        }
                        .appPanel()
                    }
                }
                .readableWidth(640)
                .padding()
            }
            .navigationTitle("남은 준비")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    private func ownerTint(_ owner: String) -> Color {
        switch owner {
        case "공통": return theme.accent
        case "예지": return .pink
        case "승환": return .blue
        case "민지": return .orange
        default: return .secondary
        }
    }
}

private func copyToClipboard(_ value: String) {
    #if canImport(UIKit)
    UIPasteboard.general.string = value
    #elseif canImport(AppKit)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(value, forType: .string)
    #endif
}
