import SwiftUI

struct MapScreen: View {
    @EnvironmentObject private var store: TripStore
    @State private var addSheetOpen = false

    private var groupedPlaces: [(String, [PlaceCandidate])] {
        Dictionary(grouping: store.places, by: \.category)
            .map { ($0.key, $0.value.sorted { lhs, rhs in
                if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite && !rhs.isFavorite }
                return lhs.name < rhs.name
            }) }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        NavigationStack {
            List {
                if let trip = store.trip, !trip.myMapsURL.isEmpty, let url = URL(string: trip.myMapsURL) {
                    Section("공유 지도") {
                        Link(destination: url) {
                            Label("Google My Maps 열기", systemImage: "map")
                        }
                        Label("자동 동기화는 다음 단계에서 서버 함수로 연결", systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(groupedPlaces, id: \.0) { category, places in
                    Section(category) {
                        ForEach(places) { place in
                            PlaceRow(place: place)
                        }
                    }
                }
            }
            .navigationTitle("지도 / 식당")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        addSheetOpen = true
                    } label: {
                        Label("장소 추가", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $addSheetOpen) {
                AddPlaceSheet()
                    .environmentObject(store)
            }
        }
    }
}

struct PlaceRow: View {
    @EnvironmentObject private var store: TripStore
    var place: PlaceCandidate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(place.name)
                        .font(.headline.weight(.black))
                    Text(place.category)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    store.toggleFavorite(place)
                } label: {
                    Image(systemName: place.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(place.isFavorite ? .yellow : .secondary)
                }
            }
            if !place.appNote.isEmpty {
                Text(place.appNote)
                    .font(.subheadline)
            }
            HStack {
                if let url = URL(string: place.mapURL) {
                    Link("Google Maps", destination: url)
                }
                Button("일정에 넣기") {
                    store.addSchedule(from: place, date: Date())
                }
            }
            .font(.caption.weight(.bold))
        }
        .padding(.vertical, 6)
    }
}

struct AddPlaceSheet: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var category = "장소"
    @State private var mapURL = ""
    @State private var mapNote = ""
    @State private var appNote = ""

    private let categories = ["장소", "식당", "카페", "미술관", "환승", "숙소", "기타"]

    var body: some View {
        NavigationStack {
            Form {
                Section("기본 정보") {
                    TextField("장소명", text: $name)
                    Picker("분류", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                    TextField("Google Maps 링크", text: $mapURL)
                }
                Section("메모") {
                    TextField("지도에서 가져온 메모", text: $mapNote, axis: .vertical)
                    TextField("앱에서 추가할 메모", text: $appNote, axis: .vertical)
                }
            }
            .navigationTitle("장소 추가")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        store.addPlace(name: name, category: category, mapURL: mapURL, mapNote: mapNote, appNote: appNote)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
