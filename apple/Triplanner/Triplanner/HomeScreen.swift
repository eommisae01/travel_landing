import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject private var store: TripStore
    @State private var selectedCity = ""
    @State private var showingAddCity = false
    @State private var newCity = ""

    private var undoneChecklistCount: Int {
        store.checklist.filter { !$0.isDone }.count
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
                    ForEach(store.scheduleItems.prefix(4)) { item in
                        ScheduleRow(item: item)
                    }

                    sectionTitle("Notes")
                    ForEach(store.notes.prefix(3)) { note in
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
        }
    }

    private func hero(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(trip.name)
                .font(.title.weight(.black))
            if let dateRange = dateRange(for: trip) {
                Text(dateRange)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 10)], spacing: 10) {
                TripSummaryTile(title: "가는 편", value: flightSummary(trip.outbound, mode: .outbound))
                TripSummaryTile(title: "오는 편", value: flightSummary(trip.inbound, mode: .inbound))
                TripSummaryTile(title: "숙소", value: trip.accommodation.isEmpty ? "숙소 입력 전" : trip.accommodation)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private var statusStrip: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 12) {
            InfoCard(title: "남은 준비", subtitle: "\(undoneChecklistCount)개")
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
                    .font(.headline.weight(.black))
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private enum FlightSummaryMode {
        case outbound
        case inbound
    }

    private func flightSummary(_ flight: FlightInfo, mode: FlightSummaryMode) -> String {
        let route = "\(flight.origin.isEmpty ? "출발지" : flight.origin) → \(flight.destination.isEmpty ? "도착지" : flight.destination)"
        let time: String
        switch mode {
        case .outbound:
            time = flight.localArrival.isEmpty ? "도착시간 입력 전" : "도착 \(flight.localArrival)"
        case .inbound:
            time = flight.localDeparture.isEmpty ? "출발시간 입력 전" : "출발 \(flight.localDeparture)"
        }
        return "\(flight.flightNumber.isEmpty ? "편명 입력 전" : flight.flightNumber)\n\(route)\n\(time)"
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
            .font(.title3.weight(.black))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TripSummaryTile: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.footnote.weight(.bold))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 78, alignment: .topLeading)
        .padding(12)
        .background(.background.opacity(0.72), in: RoundedRectangle(cornerRadius: 14))
    }
}
