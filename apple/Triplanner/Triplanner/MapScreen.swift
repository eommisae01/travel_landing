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
                    ScreenHeader(title: placesTitle, subtitle: "\(placeCount)개 장소 · 지도, 식당, 카페, 환승")

                    if let trip = store.trip, !trip.myMapsURL.isEmpty, let url = URL(string: trip.myMapsURL) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("공유 지도")
                                        .font(.headline.weight(.black))
                                    Text("My Maps 링크와 앱 메모를 함께 관리")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Link(destination: url) {
                                    Label("열기", systemImage: "map")
                                        .font(.caption.weight(.black))
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    }

                    ForEach(groupedPlaces, id: \.0) { category, places in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(category)
                                    .font(.headline.weight(.black))
                                Spacer()
                                Text("\(places.count)")
                                    .font(.caption.weight(.black))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.secondary.opacity(0.10), in: Capsule())
                                    .foregroundStyle(.secondary)
                            }
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 172), spacing: 8)], spacing: 8) {
                                ForEach(places) { place in
                                    PlaceRow(place: place)
                                }
                            }
                        }
                    }
                    if groupedPlaces.isEmpty {
                        EmptyStateView(
                            title: "장소가 비어있어요",
                            message: "지도 링크나 식당 후보를 추가하면 도시별로 모아볼 수 있습니다.",
                            iconName: "map"
                        )
                    }
                }
                .readableWidth(1120)
                .padding()
            }
            .navigationTitle("지도")
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

    private var placeCount: Int {
        store.placesForSelectedCity().count
    }

    private var placesTitle: String {
        store.currentCity.isEmpty ? "Places" : "\(displayCity(store.currentCity)) Places"
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name)
                        .font(.footnote.weight(.black))
                        .lineLimit(2)
                    if !place.mapNote.isEmpty {
                        Text(place.mapNote)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Button {
                    store.toggleFavorite(place)
                } label: {
                    Image(systemName: place.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(place.isFavorite ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
            }
            if !place.appNote.isEmpty {
                Text(place.appNote)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            HStack {
                if let url = URL(string: place.mapURL) {
                    Link(destination: url) {
                        Label("지도", systemImage: "map")
                    }
                }
                Button {
                    store.addSchedule(from: place, date: Date())
                } label: {
                    Label("일정", systemImage: "calendar.badge.plus")
                }
            }
            .font(.caption2.weight(.bold))
            .labelStyle(.titleAndIcon)
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .padding(8)
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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ScreenHeader(title: "장소 추가", subtitle: "지도 링크와 앱 메모를 분리해서 저장합니다.")

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "PLACE")
                        TextField("장소명", text: $name)
                            .textFieldStyle(.roundedBorder)
                        TextField("Google Maps 링크", text: $mapURL)
                            .textFieldStyle(.roundedBorder)
                    }
                    .appPanel()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "CATEGORY")
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
                            ForEach(categories, id: \.self) { item in
                                Button {
                                    category = item
                                } label: {
                                    Text(item)
                                        .font(.subheadline.weight(.black))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(category == item ? Color.teal : Color.secondary.opacity(0.12), in: Capsule())
                                        .foregroundStyle(category == item ? .white : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .appPanel()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "MEMO")
                        TextField("지도에서 가져온 메모", text: $mapNote, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                        TextField("앱에서 추가할 메모", text: $appNote, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                    }
                    .appPanel()
                }
                .readableWidth(680)
                .padding()
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
