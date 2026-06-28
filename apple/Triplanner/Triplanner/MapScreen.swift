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
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.teal.opacity(0.14))
                                Image(systemName: "map.fill")
                                    .font(.title3.weight(.black))
                                    .foregroundStyle(.teal)
                            }
                            .frame(width: 48, height: 48)

                            VStack(alignment: .leading, spacing: 3) {
                                Text("공유 지도")
                                    .font(.headline.weight(.black))
                                Text("My Maps에서 고른 장소와 앱 메모를 함께 관리")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                            Link(destination: url) {
                                Label("열기", systemImage: "arrow.up.right")
                                    .font(.caption.weight(.black))
                            }
                            .buttonStyle(.borderedProminent)
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
                PlaceEditorSheet()
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
    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text(place.category)
                            .font(.caption2.weight(.black))
                            .foregroundStyle(categoryColor)
                        if place.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.yellow)
                        }
                    }
                    Text(place.name)
                        .font(.footnote.weight(.black))
                        .lineLimit(2)
                }
                Spacer()
                HStack(spacing: 7) {
                    Button {
                        isEditing = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    Button {
                        store.toggleFavorite(place)
                    } label: {
                        Image(systemName: place.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(place.isFavorite ? .yellow : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            if !place.mapNote.isEmpty {
                Label(place.mapNote, systemImage: "map")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if !place.appNote.isEmpty {
                Text(place.appNote)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                if let url = URL(string: place.mapURL) {
                    Link(destination: url) {
                        Label("지도", systemImage: "map")
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 7)
                    .background(.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
                }
                Button {
                    store.addSchedule(from: place, date: Date())
                } label: {
                    Label("일정", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 7)
                .background(categoryColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            }
            .font(.caption2.weight(.bold))
            .labelStyle(.titleAndIcon)
        }
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
        .padding(10)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.quaternary)
        }
        .sheet(isPresented: $isEditing) {
            PlaceEditorSheet(existingPlace: place)
                .environmentObject(store)
        }
    }

    private var categoryColor: Color {
        switch place.category {
        case let value where value.contains("식") || value.contains("우동"): return .orange
        case let value where value.contains("카페") || value.contains("디저트"): return .pink
        case let value where value.contains("환승"): return .blue
        case let value where value.contains("숙소"): return .purple
        case let value where value.contains("미술관") || value.contains("전망"): return .teal
        default: return .teal
        }
    }
}

struct PlaceEditorSheet: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.dismiss) private var dismiss
    var existingPlace: PlaceCandidate?

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
                    ScreenHeader(title: existingPlace == nil ? "장소 추가" : "장소 수정", subtitle: "지도 메모와 앱 메모를 분리해서 관리")

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(title: "PLACE")
                        LabeledPlaceField(title: "이름", iconName: "mappin", placeholder: "장소명", text: $name)
                        LabeledPlaceField(title: "지도", iconName: "link", placeholder: "Google Maps 링크", text: $mapURL)
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
                                        .font(.caption.weight(.black))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 9)
                                        .background(category == item ? Color.teal : Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                                        .foregroundStyle(category == item ? .white : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .appPanel()

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(title: "MEMO")
                        TextField("지도에서 가져온 메모", text: $mapNote, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(2...4)
                        TextField("앱에서 추가할 메모", text: $appNote, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                    .appPanel()
                }
                .readableWidth(680)
                .padding()
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingPlace == nil ? "추가" : "저장") {
                        if let existingPlace {
                            store.updatePlace(existingPlace, name: name, category: category, mapURL: mapURL, mapNote: mapNote, appNote: appNote)
                        } else {
                            store.addPlace(name: name, category: category, mapURL: mapURL, mapNote: mapNote, appNote: appNote)
                        }
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                guard let existingPlace else { return }
                name = existingPlace.name
                category = existingPlace.category
                mapURL = existingPlace.mapURL
                mapNote = existingPlace.mapNote
                appNote = existingPlace.appNote
            }
        }
    }
}

private struct LabeledPlaceField: View {
    var title: String
    var iconName: String
    var placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Label(title, systemImage: iconName)
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}
