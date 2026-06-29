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
                VStack(alignment: .leading, spacing: 14) {
                    ScreenHeader(title: placesTitle, subtitle: "\(placeCount)개 장소 · 별표 \(favoriteCount)개")
                    PlaceOverviewStrip(
                        totalCount: placeCount,
                        favoriteCount: favoriteCount,
                        linkedCount: linkedPlaceCount,
                        categoryCount: groupedPlaces.count
                    )

                    if let trip = store.trip, !trip.myMapsURL.isEmpty, let url = URL(string: trip.myMapsURL) {
                        sharedMapCard(url)
                    }

                    ForEach(groupedPlaces, id: \.0) { category, places in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label(category, systemImage: sectionIcon(for: category))
                                    .font(.headline.weight(.black))
                                    .foregroundStyle(sectionColor(for: category))
                                Spacer()
                                Text("\(places.count)")
                                    .font(.caption.weight(.black))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.secondary.opacity(0.10), in: Capsule())
                                    .foregroundStyle(.secondary)
                            }
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 10)], spacing: 10) {
                                ForEach(places) { place in
                                    PlaceRow(place: place)
                                }
                            }
                        }
                        .padding(9)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.quaternary)
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
        .appScreenBackground()
    }

    private var placeCount: Int {
        store.placesForSelectedCity().count
    }

    private var favoriteCount: Int {
        store.placesForSelectedCity().filter(\.isFavorite).count
    }

    private var linkedPlaceCount: Int {
        store.placesForSelectedCity().filter { URL(string: $0.mapURL) != nil }.count
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

    private func sharedMapCard(_ url: URL) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(.teal.opacity(0.14))
                Image(systemName: "map.fill")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.teal)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 3) {
                Text("My Maps")
                    .font(.subheadline.weight(.black))
                Text("공유 지도에서 고른 장소와 앱 메모를 같이 확인")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Link(destination: url) {
                Label("열기", systemImage: "arrow.up.right")
                    .font(.caption.weight(.black))
                    .labelStyle(.iconOnly)
                    .frame(width: 32, height: 32)
            }
            .background(.teal, in: RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(.white)
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.quaternary)
        }
    }

    private func sectionColor(for category: String) -> Color {
        switch category {
        case let value where value.contains("식") || value.contains("우동"): return .orange
        case let value where value.contains("카페") || value.contains("디저트"): return .pink
        case let value where value.contains("환승"): return .blue
        case let value where value.contains("숙소"): return .purple
        case let value where value.contains("미술관") || value.contains("전망"): return .teal
        default: return .teal
        }
    }

    private func sectionIcon(for category: String) -> String {
        switch category {
        case let value where value.contains("식") || value.contains("우동"): return "fork.knife"
        case let value where value.contains("카페") || value.contains("디저트"): return "cup.and.saucer"
        case let value where value.contains("환승"): return "bus"
        case let value where value.contains("숙소"): return "bed.double"
        case let value where value.contains("미술관") || value.contains("전망"): return "building.columns"
        default: return "mappin"
        }
    }
}

private struct PlaceOverviewStrip: View {
    var totalCount: Int
    var favoriteCount: Int
    var linkedCount: Int
    var categoryCount: Int

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 8)], spacing: 8) {
            PlaceMetricPill(title: "전체", value: "\(totalCount)", iconName: "mappin.and.ellipse", tint: .teal)
            PlaceMetricPill(title: "별표", value: "\(favoriteCount)", iconName: "star.fill", tint: .yellow)
            PlaceMetricPill(title: "지도", value: "\(linkedCount)", iconName: "map", tint: .blue)
            PlaceMetricPill(title: "분류", value: "\(categoryCount)", iconName: "square.grid.2x2", tint: .purple)
        }
    }
}

private struct PlaceMetricPill: View {
    var title: String
    var value: String
    var iconName: String
    var tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.caption2.weight(.black))
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.weight(.black))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.quaternary)
        }
    }
}

struct PlaceRow: View {
    @EnvironmentObject private var store: TripStore
    var place: PlaceCandidate
    @State private var isEditing = false
    @State private var isScheduling = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: categoryIcon)
                    .font(.caption.weight(.black))
                    .foregroundStyle(categoryColor)
                    .frame(width: 30, height: 30)
                    .background(categoryColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(place.name)
                            .font(.subheadline.weight(.black))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        if place.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption2.weight(.black))
                                .foregroundStyle(.yellow)
                        }
                    }
                    HStack(spacing: 5) {
                        Image(systemName: categoryIcon)
                            .font(.caption2.weight(.black))
                        Text(place.category)
                            .font(.caption2.weight(.black))
                            .lineLimit(1)
                    }
                    .foregroundStyle(categoryColor)

                    Text(summaryText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 4) {
                    Button {
                        store.toggleFavorite(place)
                    } label: {
                        actionIcon(place.isFavorite ? "star.fill" : "star", tint: place.isFavorite ? .yellow : .secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(place.isFavorite ? "별표 해제" : "별표")

                    Menu {
                        Button {
                            isEditing = true
                        } label: {
                            Label("수정", systemImage: "pencil")
                        }
                        Button {
                            store.toggleFavorite(place)
                        } label: {
                            Label(place.isFavorite ? "별표 해제" : "별표", systemImage: place.isFavorite ? "star.slash" : "star")
                        }
                        if let url = URL(string: place.mapURL) {
                            Link(destination: url) {
                                Label("지도 열기", systemImage: "map")
                            }
                        }
                    } label: {
                        actionIcon("ellipsis", tint: .secondary)
                    }
                    .menuStyle(.button)
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 7) {
                if let url = URL(string: place.mapURL) {
                    Link(destination: url) {
                        PlaceActionChip(title: "지도", iconName: "map", tint: .blue)
                    }
                    .accessibilityLabel("지도 열기")
                }

                Button {
                    isScheduling = true
                } label: {
                    PlaceActionChip(title: "일정", iconName: "calendar.badge.plus", tint: categoryColor)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("일정에 추가")

                Button {
                    isEditing = true
                } label: {
                    PlaceActionChip(title: "수정", iconName: "pencil", tint: .secondary)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 126, maxHeight: 126, alignment: .topLeading)
        .padding(10)
        .background(.background.opacity(0.58), in: RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(categoryColor)
                .frame(width: 3)
                .padding(.vertical, 10)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(categoryColor.opacity(place.isFavorite ? 0.22 : 0.07))
        }
        .shadow(color: categoryColor.opacity(0.035), radius: 5, x: 0, y: 3)
        .sheet(isPresented: $isEditing) {
            PlaceEditorSheet(existingPlace: place)
                .environmentObject(store)
        }
        .sheet(isPresented: $isScheduling) {
            PlaceScheduleSheet(place: place)
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

    private var categoryIcon: String {
        switch place.category {
        case let value where value.contains("식") || value.contains("우동"): return "fork.knife"
        case let value where value.contains("카페") || value.contains("디저트"): return "cup.and.saucer"
        case let value where value.contains("환승"): return "bus"
        case let value where value.contains("숙소"): return "bed.double"
        case let value where value.contains("미술관") || value.contains("전망"): return "building.columns"
        default: return "mappin"
        }
    }

    private var summaryText: String {
        if !place.appNote.isEmpty { return place.appNote }
        if !place.mapNote.isEmpty { return place.mapNote }
        return "메모 없음"
    }

    private func actionIcon(_ iconName: String, tint: Color) -> some View {
        Image(systemName: iconName)
            .font(.caption.weight(.black))
            .frame(width: 26, height: 26)
            .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(tint)
    }
}

private struct PlaceActionChip: View {
    var title: String
    var iconName: String
    var tint: Color

    var body: some View {
        Label(title, systemImage: iconName)
            .font(.caption2.weight(.black))
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(tint.opacity(0.10), in: Capsule())
            .foregroundStyle(tint)
    }
}

struct PlaceScheduleSheet: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.dismiss) private var dismiss

    var place: PlaceCandidate

    @State private var date = Date()
    @State private var startTime = ""
    @State private var endTime = ""
    @State private var note = ""
    @State private var didLoad = false

    private var dateOptions: [Date] {
        guard let trip = store.trip, let start = trip.startDate, let end = trip.endDate else {
            return []
        }
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        let dayCount = calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
        return (0...max(dayCount, 0)).compactMap { calendar.date(byAdding: .day, value: $0, to: startDay) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ScreenHeader(title: "일정에 넣기", subtitle: place.name)

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "WHEN")
                        if dateOptions.isEmpty {
                            DatePicker("날짜", selection: $date, displayedComponents: .date)
                                .datePickerStyle(.compact)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], spacing: 8) {
                                ForEach(Array(dateOptions.enumerated()), id: \.offset) { index, option in
                                    Button {
                                        date = option
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Day \(index + 1)")
                                                .font(.caption2.weight(.black))
                                            Text(compactDayLabel(option))
                                                .font(.caption.weight(.black))
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(isSameDay(option, date) ? Color.teal : Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                                        .foregroundStyle(isSameDay(option, date) ? .white : .primary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        HStack(spacing: 10) {
                            LabeledPlaceField(title: "시작", iconName: "clock", placeholder: "12:00", text: $startTime)
                            LabeledPlaceField(title: "종료", iconName: "clock.badge.checkmark", placeholder: "13:00", text: $endTime)
                        }
                    }
                    .appPanel(cornerRadius: 18)

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(title: "PLACE")
                        HStack(spacing: 10) {
                            Image(systemName: placeIcon)
                                .font(.headline.weight(.bold))
                                .frame(width: 38, height: 38)
                                .background(placeTint.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(placeTint)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(place.name)
                                    .font(.headline.weight(.black))
                                Text(place.category)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if !place.mapNote.isEmpty {
                            Label(place.mapNote, systemImage: "map")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .appPanel(cornerRadius: 18)

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(title: "MEMO")
                        TextField("일정에 같이 남길 메모", text: $note, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                    .appPanel(cornerRadius: 18)
                }
                .readableWidth(620)
                .padding()
            }
            .navigationTitle("일정에 넣기")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        addToSchedule()
                    }
                }
            }
            .onAppear(perform: loadDefaults)
        }
    }

    private func loadDefaults() {
        guard !didLoad else { return }
        didLoad = true
        date = dateOptions.first ?? Date()
        note = place.appNote
    }

    private func addToSchedule() {
        store.addScheduleItem(
            date: date,
            startTime: startTime,
            endTime: endTime,
            title: place.name,
            note: note,
            placeName: place.name,
            sourceMapNote: place.mapNote,
            kind: place.category.contains("식") || place.category.contains("카페") || place.category.contains("우동") ? .food : .place
        )
        dismiss()
    }

    private func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        Calendar.current.isDate(lhs, inSameDayAs: rhs)
    }

    private func compactDayLabel(_ value: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M.d E"
        return formatter.string(from: value)
    }

    private var placeTint: Color {
        switch place.category {
        case let value where value.contains("식") || value.contains("우동"): return .orange
        case let value where value.contains("카페") || value.contains("디저트"): return .pink
        case let value where value.contains("환승"): return .blue
        case let value where value.contains("숙소"): return .purple
        default: return .teal
        }
    }

    private var placeIcon: String {
        switch place.category {
        case let value where value.contains("식") || value.contains("우동"): return "fork.knife"
        case let value where value.contains("카페") || value.contains("디저트"): return "cup.and.saucer"
        case let value where value.contains("환승"): return "bus"
        case let value where value.contains("숙소"): return "bed.double"
        default: return "mappin"
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
