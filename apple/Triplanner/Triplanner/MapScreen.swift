import SwiftUI

struct MapScreen: View {
    @EnvironmentObject private var store: TripStore
    @State private var addSheetOpen = false

    private var groupedPlaces: [(String, [PlaceCandidate])] {
        Dictionary(grouping: store.placesForSelectedCity(), by: \.category)
            .map { ($0.key, $0.value.sorted { lhs, rhs in
                if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite && !rhs.isFavorite }
                return lhs.name < rhs.name
            }) }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(store.currentCity.isEmpty ? "지도 / 식당" : "\(displayCity(store.currentCity)) places")
                        .font(.title2.weight(.black))

                    if let trip = store.trip, !trip.myMapsURL.isEmpty, let url = URL(string: trip.myMapsURL) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("공유 지도")
                                .font(.headline.weight(.black))
                            HStack {
                                Link(destination: url) {
                                    Label("Google My Maps 열기", systemImage: "map")
                                }
                                Spacer()
                                Label("자동 동기화 예정", systemImage: "arrow.triangle.2.circlepath")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline.weight(.bold))
                        }
                        .padding(12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    }

                    ForEach(groupedPlaces, id: \.0) { category, places in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(category)
                                .font(.headline.weight(.black))
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 10)], spacing: 10) {
                                ForEach(places) { place in
                                    PlaceRow(place: place)
                                }
                            }
                        }
                    }
                    if groupedPlaces.isEmpty {
                        Text("선택한 도시의 장소가 아직 없습니다.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
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

    private func displayCity(_ city: String) -> String {
        switch city {
        case "타카마쓰": return "Takamatsu"
        case "나오시마": return "Naoshima"
        case "도쿄": return "Tokyo"
        default: return city
        }
    }
}

struct PlaceRow: View {
    @EnvironmentObject private var store: TripStore
    var place: PlaceCandidate

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name)
                        .font(.subheadline.weight(.black))
                        .lineLimit(1)
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
                    .font(.caption)
                    .lineLimit(2)
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
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
        .padding(10)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.quaternary)
        }
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
