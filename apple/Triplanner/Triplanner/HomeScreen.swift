import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct HomeScreen: View {
    @EnvironmentObject private var store: TripStore
    @State private var selectedCity = ""
    @State private var showingAddCity = false
    @State private var newCity = ""
    @State private var showingChecklistSummary = false

    private var undoneChecklistCount: Int {
        store.checklist.filter { !$0.isDone }.count
    }

    private var selectedCityValue: String {
        selectedCity.isEmpty ? (store.trip?.cities.first ?? "") : selectedCity
    }

    private var cityScheduleItems: [ScheduleItem] {
        store.scheduleItems
            .filter { isRelevant($0.title + " " + $0.placeName + " " + $0.note + " " + $0.sourceMapNote, to: selectedCityValue) }
            .sorted { lhs, rhs in
                if lhs.date != rhs.date { return lhs.date < rhs.date }
                return lhs.startTime < rhs.startTime
            }
    }

    private var cityNotes: [NoteGroup] {
        store.notes.filter { isRelevant($0.title + " " + $0.body, to: selectedCityValue) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let trip = store.trip {
                        hero(trip)
                    }

                    statusStrip

                    sectionTitle("TODAY")
                    ForEach(cityScheduleItems.prefix(4)) { item in
                        ScheduleRow(item: item)
                    }

                    sectionTitle("TODAY NOTES")
                    ForEach(cityNotes.prefix(2)) { note in
                        InfoCard(title: note.title, subtitle: note.body)
                    }
                }
                .padding()
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    cityMenu
                }
            }
            .onAppear {
                selectedCity = selectedCity.isEmpty ? (store.trip?.cities.first ?? "") : selectedCity
            }
            .alert("지역 추가", isPresented: $showingAddCity) {
                TextField("예: Osaka", text: $newCity)
                Button("추가") {
                    let trimmedCity = newCity.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedCity.isEmpty else { return }
                    store.addCity(trimmedCity)
                    selectedCity = trimmedCity
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

    private func hero(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let dateRange = dateRange(for: trip) {
                Text(dateRange)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 10) {
                CopySummaryTile(
                    title: "가는 편",
                    value: flightSummary(trip.outbound),
                    copyValue: trip.outbound.flightNumber
                )
                CopySummaryTile(
                    title: "오는 편",
                    value: flightSummary(trip.inbound),
                    copyValue: trip.inbound.flightNumber
                )
                CopySummaryTile(
                    title: "숙소",
                    value: accommodationSummary(trip),
                    copyValue: trip.accommodationAddress ?? trip.accommodation
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private var statusStrip: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 12) {
            Button {
                showingChecklistSummary = true
            } label: {
                InfoCard(title: "남은 준비", subtitle: "\(undoneChecklistCount)개")
            }
            .buttonStyle(.plain)
            InfoCard(title: "지출", subtitle: "\(Int(store.expenses.reduce(0) { $0 + $1.amount })) JPY")
        }
    }

    private var cityMenu: some View {
        Menu {
            if let trip = store.trip {
                ForEach(trip.cities, id: \.self) { city in
                    Button {
                        selectedCity = city
                    } label: {
                        Label(cityDisplayName(city), systemImage: selectedCity == city ? "checkmark" : "mappin")
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
            HStack(spacing: 5) {
                Text(cityDisplayName(selectedCity.isEmpty ? (store.trip?.cities.first ?? "Trip") : selectedCity))
                    .font(.title2.weight(.black))
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func flightSummary(_ flight: FlightInfo) -> String {
        let route = "\(flight.origin.isEmpty ? "출발지" : flight.origin) → \(flight.destination.isEmpty ? "도착지" : flight.destination)"
        let departure = flight.localDeparture.isEmpty ? "출발시간 입력 전" : "출발 \(flight.localDeparture)"
        let arrival = flight.localArrival.isEmpty ? "도착시간 입력 전" : "도착 \(flight.localArrival)"
        return "\(flight.flightNumber.isEmpty ? "편명 입력 전" : flight.flightNumber)\n\(route)\n\(departure) · \(arrival)"
    }

    private func accommodationSummary(_ trip: Trip) -> String {
        let name = trip.accommodation.isEmpty ? "숙소 입력 전" : trip.accommodation
        guard let address = trip.accommodationAddress, !address.isEmpty else { return name }
        return "\(name)\n\(address)"
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

    private func isRelevant(_ text: String, to city: String) -> Bool {
        if city == "도쿄" {
            return text.contains("도쿄") || text.contains("긴자") || text.contains("시부야")
        }
        if city == "나오시마" {
            return text.contains("나오시마") || text.contains("지중") || text.contains("미야노우라") || text.contains("츠츠지소") || text.contains("베네세") || text.contains("이우환")
        }
        return !text.contains("도쿄") && !text.contains("긴자") && !text.contains("시부야")
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.black))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CopySummaryTile: View {
    var title: String
    var value: String
    var copyValue: String

    var body: some View {
        Button {
            copyToClipboard(copyValue.isEmpty ? value : copyValue)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Text(title)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.teal)
                    .frame(width: 56, alignment: .leading)
                Text(value)
                    .font(.footnote.weight(.bold))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Image(systemName: "doc.on.doc")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.background.opacity(0.78), in: RoundedRectangle(cornerRadius: 14))
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
            List(remaining) { item in
                HStack {
                    Text(item.title)
                        .font(.headline.weight(.bold))
                    Spacer()
                    Text(item.owner)
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("남은 준비")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") { dismiss() }
                }
            }
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
