import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject private var store: TripStore

    private var undoneChecklistCount: Int {
        store.checklist.filter { !$0.isDone }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let trip = store.trip {
                        hero(trip)
                        quickCards(trip)
                    }

                    statusStrip

                    sectionTitle("여행 브리핑")
                    ForEach(store.scheduleItems.prefix(4)) { item in
                        ScheduleRow(item: item)
                    }

                    sectionTitle("지도에서 고른 장소")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 170))], spacing: 12) {
                        ForEach(store.places.filter { $0.isFavorite }.prefix(4)) { place in
                            InfoCard(title: place.category, subtitle: "\(place.name)\n\(place.appNote)")
                        }
                    }

                    sectionTitle("Notes")
                    ForEach(store.notes.prefix(3)) { note in
                        InfoCard(title: note.title, subtitle: note.body)
                    }
                }
                .padding()
            }
            .navigationTitle("Trip")
        }
    }

    private func hero(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(trip.country)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Text(trip.name)
                .font(.largeTitle.weight(.black))
            Menu {
                ForEach(trip.cities, id: \.self) { city in
                    Button(city) {}
                }
            } label: {
                Label(trip.cities.first ?? "도시 선택", systemImage: "chevron.down.circle")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private var statusStrip: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 145))], spacing: 12) {
            InfoCard(title: "남은 준비", subtitle: "\(undoneChecklistCount)개")
            InfoCard(title: "장소 후보", subtitle: "\(store.places.count)개")
            InfoCard(title: "Notes", subtitle: "\(store.notes.count)개")
            InfoCard(title: "지출", subtitle: "\(Int(store.expenses.reduce(0) { $0 + $1.amount })) JPY")
        }
    }

    private func quickCards(_ trip: Trip) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 12) {
            InfoCard(title: "숙소", subtitle: trip.accommodation.isEmpty ? "숙소 입력 전" : trip.accommodation)
            InfoCard(title: "가는 편", subtitle: "\(trip.outbound.flightNumber) \(trip.outbound.origin) → \(trip.outbound.destination) \(trip.outbound.localArrival)")
            InfoCard(title: "오는 편", subtitle: "\(trip.inbound.flightNumber) \(trip.inbound.origin) → \(trip.inbound.destination) \(trip.inbound.localDeparture)")
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.black))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
