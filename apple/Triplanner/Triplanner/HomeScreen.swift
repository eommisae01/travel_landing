import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct HomeScreen: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showingAddCity = false
    @State private var newCity = ""
    @State private var showingChecklistSummary = false

    private var undoneChecklistCount: Int {
        store.checklist.filter { !$0.isDone }.count
    }

    private var cityScheduleItems: [ScheduleItem] {
        store.scheduleItemsForSelectedCity()
    }

    private var cityNotes: [NoteGroup] {
        store.notesForSelectedCity()
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
    }

    private func cityHero(_ trip: Trip) -> some View {
        HStack(alignment: .bottom, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                cityMenu
                if let dateRange = dateRange(for: trip) {
                    Label(dateRange, systemImage: "calendar")
                        .font(.callout.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.regularMaterial)
        }
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.teal)
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
                Text("TRAVEL")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("탭하면 복사")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.10), in: Capsule())
            }
            VStack(spacing: 10) {
                FlightSummaryTile(
                    title: "가는 편",
                    flight: trip.outbound,
                    iconName: "airplane.departure",
                    tint: .teal
                )
                FlightSummaryTile(
                    title: "오는 편",
                    flight: trip.inbound,
                    iconName: "airplane.arrival",
                    tint: .blue
                )
                AccommodationSummaryTile(trip: trip)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(.quaternary)
        }
    }

    private var statusStrip: some View {
        HStack(spacing: 10) {
            StatButton(title: "남은 준비", value: "\(undoneChecklistCount)", unit: "개") {
                showingChecklistSummary = true
            }
            StatChip(title: "지출", value: "\(Int(store.expenses.reduce(0) { $0 + $1.amount }))", unit: "JPY")
        }
    }

    private var todayPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionTitle("TODAY")
                Spacer()
                Text("\(cityScheduleItems.prefix(5).count)")
                    .font(.caption2.weight(.black))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.10), in: Capsule())
                    .foregroundStyle(.secondary)
            }
            if cityScheduleItems.isEmpty {
                EmptyStateView(
                    title: "오늘 일정이 비어있어요",
                    message: "장소나 이동 계획을 일정에 추가하면 여기서 바로 보입니다.",
                    iconName: "calendar"
                )
            } else {
                ForEach(cityScheduleItems.prefix(5)) { item in
                    CompactScheduleRow(item: item)
                }
            }
        }
        .panelStyle()
    }

    private var notesPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("TODAY NOTES")
            Text("현재 선택한 도시에서 오늘 확인하기 좋은 자료만 먼저 보여줍니다.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            if cityNotes.isEmpty {
                EmptyStateView(
                    title: "오늘 볼 자료가 없어요",
                    message: "시간표, 예약 캡처, 현장 메모를 Notes에 모아두세요.",
                    iconName: "note.text"
                )
            } else {
                ForEach(cityNotes.prefix(3)) { note in
                    CompactNoteCard(note: note)
                }
            }
        }
        .panelStyle()
    }

    private var cityMenu: some View {
        Menu {
            if let trip = store.trip {
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
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(cityDisplayName(store.currentCity))
                    .font(.system(size: isWideLayout ? 58 : 42, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.78)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func dateRange(for trip: Trip) -> String? {
        guard let start = trip.startDate, let end = trip.endDate else { return nil }
        return "\(start.dayLabel) - \(end.dayLabel)"
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
        default: return city.isEmpty ? "Trip" : city
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.black))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct FlightSummaryTile: View {
    var title: String
    var flight: FlightInfo
    var iconName: String
    var tint: Color

    var body: some View {
        Button {
            copyToClipboard(flight.flightNumber.isEmpty ? "\(flight.origin) \(flight.destination)" : flight.flightNumber)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: iconName)
                    .font(.headline.weight(.bold))
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(tint)

                VStack(alignment: .leading, spacing: 6) {
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
                    VStack(alignment: .leading, spacing: 5) {
                        RouteTimeLine(title: "출발", city: flight.origin, time: flight.localDeparture, tint: tint)
                        RouteTimeLine(title: "도착", city: flight.destination, time: flight.localArrival, tint: tint)
                    }
                }
                Spacer(minLength: 6)
                Image(systemName: "doc.on.doc")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .padding(12)
        .background(.background.opacity(0.74), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary)
        }
    }

    private var routeText: String {
        "\(flight.origin.isEmpty ? "출발지" : flight.origin) → \(flight.destination.isEmpty ? "도착지" : flight.destination)"
    }
}

private struct RouteTimeLine: View {
    var title: String
    var city: String
    var time: String
    var tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption2.weight(.black))
                .foregroundStyle(tint)
                .frame(width: 28, alignment: .leading)
            Text(city.isEmpty ? "미정" : city)
                .font(.caption.weight(.bold))
                .lineLimit(1)
            Spacer(minLength: 6)
            Text(time.isEmpty ? "--:--" : time)
                .font(.caption.weight(.black))
                .monospacedDigit()
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(tint.opacity(0.10), in: Capsule())
        }
    }
}

private struct AccommodationSummaryTile: View {
    var trip: Trip

    var body: some View {
        Button {
            copyToClipboard(trip.accommodationAddress ?? trip.accommodation)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "bed.double")
                    .font(.headline.weight(.bold))
                    .frame(width: 38, height: 38)
                    .background(.purple.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.purple)

                VStack(alignment: .leading, spacing: 5) {
                    Text("숙소")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.purple)
                    Text(trip.accommodation.isEmpty ? "숙소 입력 전" : trip.accommodation)
                        .font(.subheadline.weight(.black))
                        .lineLimit(1)
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
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .padding(12)
        .background(.background.opacity(0.74), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
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
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            StatChipContent(title: title, value: value, unit: unit, iconName: "checklist")
        }
        .buttonStyle(.plain)
    }
}

private struct StatChip: View {
    var title: String
    var value: String
    var unit: String

    var body: some View {
        StatChipContent(title: title, value: value, unit: unit, iconName: "creditcard")
    }
}

private struct StatChipContent: View {
    var title: String
    var value: String
    var unit: String
    var iconName: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.headline.weight(.bold))
                .frame(width: 34, height: 34)
                .background(.teal.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.teal)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(value)
                        .font(.title3.weight(.black))
                    Text(unit)
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        .padding(11)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary)
        }
    }
}

private struct CompactScheduleRow: View {
    var item: ScheduleItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.startTime.isEmpty ? item.kind.rawValue : item.startTime)
                    .font(.caption.weight(.black))
                    .foregroundStyle(kindColor)
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
        case .place: return .teal
        }
    }
}

private struct CompactNoteCard: View {
    var note: NoteGroup

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "doc.text.image")
                .font(.subheadline.weight(.bold))
                .frame(width: 30, height: 30)
                .background(.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
                .foregroundStyle(.teal)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(note.title)
                        .font(.subheadline.weight(.black))
                        .lineLimit(1)
                    if !note.imageNames.isEmpty {
                        Label("\(note.imageNames.count)", systemImage: "photo")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.teal)
                    }
                }
                Text(note.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
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
    }
}

private struct ChecklistSummarySheet: View {
    @EnvironmentObject private var store: TripStore
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
        case "공통": return .teal
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
