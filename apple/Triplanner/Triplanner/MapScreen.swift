import SwiftUI

struct MapScreen: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.appTheme) private var theme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
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
                VStack(alignment: .leading, spacing: 20) {
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
                        VStack(alignment: .leading, spacing: 16) {
                            PlaceCategoryHeader(
                                title: category,
                                count: places.count,
                                favoriteCount: places.filter(\.isFavorite).count,
                                iconName: sectionIcon(for: category),
                                tint: sectionColor(for: category)
                            )

                            LazyVGrid(columns: placeGridColumns, spacing: 18) {
                                ForEach(places) { place in
                                    PlaceRow(place: place)
                                }
                            }
                        }
                        .padding(.top, 6)
                    }
                    if groupedPlaces.isEmpty {
                        EmptyStateView(
                            title: "장소가 비어있어요",
                            message: "지도 링크나 식당 후보를 추가하면 도시별로 모아볼 수 있습니다.",
                            iconName: "map"
                        )
                    }
                }
                .readableWidth(1220)
                .padding(22)
            }
            .navigationTitle("")
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

    private var placeGridColumns: [GridItem] {
        if horizontalSizeClass == .compact {
            return [GridItem(.flexible(), spacing: 14)]
        }
        return [GridItem(.adaptive(minimum: 500, maximum: 620), spacing: 18)]
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
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(theme.accent.opacity(0.14))
                Image(systemName: "map.fill")
                    .font(.title2.weight(.black))
                    .foregroundStyle(theme.accent)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text("My Maps")
                    .font(.title3.weight(.black))
                Text("공유 지도에서 고른 장소와 앱 메모를 같이 확인")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Link(destination: url) {
                Label("열기", systemImage: "arrow.up.right")
                    .font(.headline.weight(.black))
                    .labelStyle(.iconOnly)
                    .frame(width: 42, height: 42)
            }
            .background(theme.accent, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.white)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(.quaternary)
        }
    }

    private func sectionColor(for category: String) -> Color {
        switch category {
        case let value where value.contains("식") || value.contains("우동"): return .orange
        case let value where value.contains("카페") || value.contains("디저트"): return .pink
        case let value where value.contains("환승"): return .blue
        case let value where value.contains("숙소"): return .purple
        case let value where value.contains("미술관") || value.contains("전망"): return theme.accent
        default: return theme.accent
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
    @Environment(\.appTheme) private var theme
    var totalCount: Int
    var favoriteCount: Int
    var linkedCount: Int
    var categoryCount: Int

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
            PlaceMetricPill(title: "전체", value: "\(totalCount)", iconName: "mappin.and.ellipse", tint: theme.accent)
            PlaceMetricPill(title: "별표", value: "\(favoriteCount)", iconName: "star.fill", tint: theme.warmAccent)
            PlaceMetricPill(title: "지도", value: "\(linkedCount)", iconName: "map", tint: theme.secondaryAccent)
            PlaceMetricPill(title: "분류", value: "\(categoryCount)", iconName: "square.grid.2x2", tint: theme.accent)
        }
    }
}

private struct PlaceMetricPill: View {
    var title: String
    var value: String
    var iconName: String
    var tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.headline.weight(.black))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 11))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3.weight(.black))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary)
        }
    }
}

private struct PlaceCategoryHeader: View {
    var title: String
    var count: Int
    var favoriteCount: Int
    var iconName: String
    var tint: Color

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: iconName)
                .font(.headline.weight(.black))
                .foregroundStyle(tint)
                .frame(width: 42, height: 42)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.title2.weight(.black))
                    .lineLimit(1)
                Text(favoriteCount > 0 ? "별표 \(favoriteCount)개 포함" : "후보 \(count)개")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Text("\(count)")
                .font(.subheadline.weight(.black))
                .foregroundStyle(tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(tint.opacity(0.10), in: Capsule())
        }
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .center)
    }
}

struct PlaceRow: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.appTheme) private var theme
    var place: PlaceCandidate
    @State private var isEditing = false
    @State private var isScheduling = false
    @State private var isShowingDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardHeader

            memoPreview

            Spacer(minLength: 0)

            Divider()
                .opacity(0.42)

            actionBar
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isShowingDetail = true
        }
        .frame(maxWidth: .infinity, minHeight: 276, maxHeight: 276, alignment: .topLeading)
        .padding(18)
        .background(.background.opacity(0.92), in: RoundedRectangle(cornerRadius: 20))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(categoryColor)
                .frame(width: 4)
                .padding(.vertical, 16)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(categoryColor.opacity(place.isFavorite ? 0.34 : 0.16), lineWidth: place.isFavorite ? 1.2 : 0.8)
        }
        .shadow(color: Color.primary.opacity(0.035), radius: 10, x: 0, y: 5)
        .sheet(isPresented: $isEditing) {
            PlaceEditorSheet(existingPlace: place)
                .environmentObject(store)
        }
        .sheet(isPresented: $isScheduling) {
            PlaceScheduleSheet(place: place)
                .environmentObject(store)
        }
        .sheet(isPresented: $isShowingDetail) {
            PlaceDetailSheet(place: place, isEditing: $isEditing, isScheduling: $isScheduling)
                .environmentObject(store)
        }
    }

    private var cardHeader: some View {
        HStack(alignment: .top, spacing: 14) {
            categoryBadge

            VStack(alignment: .leading, spacing: 8) {
                Text(place.name)
                    .font(.title2.weight(.black))
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                    .fixedSize(horizontal: false, vertical: true)

                cardBadges
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Button {
                    store.toggleFavorite(place)
                } label: {
                    actionIcon(place.isFavorite ? "star.fill" : "star", tint: place.isFavorite ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(place.isFavorite ? "별표 해제" : "별표")

                Menu {
                    Button {
                        isShowingDetail = true
                    } label: {
                        Label("전체 정보", systemImage: "info.circle")
                    }
                    Button {
                        isEditing = true
                    } label: {
                        Label("수정", systemImage: "pencil")
                    }
                    Button {
                        isScheduling = true
                    } label: {
                        Label("일정에 넣기", systemImage: "calendar.badge.plus")
                    }
                    if let url = URL(string: place.mapURL) {
                        Link(destination: url) {
                            Label("지도 열기", systemImage: "map")
                        }
                    }
                } label: {
                    actionIcon("ellipsis", tint: .secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var categoryBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(categoryColor.opacity(0.13))
            Image(systemName: categoryIcon)
                .font(.title3.weight(.black))
                .foregroundStyle(categoryColor)
        }
        .frame(width: 52, height: 52)
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            if let url = URL(string: place.mapURL) {
                Link(destination: url) {
                    PlaceCardActionLabel(title: "지도", iconName: "map", tint: .blue)
                }
                .frame(maxWidth: .infinity)
                .accessibilityLabel("지도 열기")
            } else {
                PlaceCardActionLabel(title: "지도 없음", iconName: "map", tint: .secondary)
                    .frame(maxWidth: .infinity)
                    .opacity(0.58)
            }

            Button {
                isScheduling = true
            } label: {
                PlaceCardActionLabel(title: "일정", iconName: "calendar.badge.plus", tint: categoryColor)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("일정에 추가")

            Button {
                isEditing = true
            } label: {
                PlaceCardActionLabel(title: "수정", iconName: "pencil", tint: .secondary)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
        }
    }

    private var memoPreview: some View {
        let hasBothNotes = !place.mapNote.isEmpty && !place.appNote.isEmpty

        return VStack(alignment: .leading, spacing: 8) {
            if place.appNote.isEmpty && place.mapNote.isEmpty {
                PlaceMemoLine(
                    title: "메모",
                    value: "상세를 열어 앱 메모 추가",
                    iconName: "note.text",
                    tint: .secondary,
                    isPlaceholder: true,
                    lineLimit: 2
                )
            } else {
                if !place.mapNote.isEmpty {
                    PlaceMemoLine(
                        title: "지도 메모",
                        value: place.mapNote,
                        iconName: "map",
                        tint: theme.secondaryAccent,
                        lineLimit: hasBothNotes ? 1 : 2
                    )
                }
                if !place.appNote.isEmpty {
                    PlaceMemoLine(
                        title: "앱 메모",
                        value: place.appNote,
                        iconName: "note.text",
                        tint: .secondary,
                        lineLimit: hasBothNotes ? 1 : 2
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 82, maxHeight: 82, alignment: .topLeading)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(categoryColor.opacity(0.055), in: RoundedRectangle(cornerRadius: 15))
    }

    private var cardBadges: some View {
        HStack(spacing: 6) {
            Text(place.category)
                .font(.subheadline.weight(.black))
                .foregroundStyle(categoryColor)
                .lineLimit(1)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(categoryColor.opacity(0.10), in: Capsule())

            if place.isFavorite {
                Label("Favorite", systemImage: "star.fill")
                    .font(.caption.weight(.black))
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.yellow)
                    .frame(width: 24, height: 24)
                    .background(.yellow.opacity(0.13), in: Capsule())
                    .accessibilityLabel("별표")
            }

            if URL(string: place.mapURL) != nil {
                Image(systemName: "link")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.blue)
                    .frame(width: 24, height: 24)
                    .background(.blue.opacity(0.10), in: Capsule())
                    .accessibilityLabel("지도 링크 있음")
            }

            Spacer(minLength: 0)
        }
    }

    private var categoryColor: Color {
        switch place.category {
        case let value where value.contains("식") || value.contains("우동"): return .orange
        case let value where value.contains("카페") || value.contains("디저트"): return .pink
        case let value where value.contains("환승"): return .blue
        case let value where value.contains("숙소"): return .purple
        case let value where value.contains("미술관") || value.contains("전망"): return theme.accent
        default: return theme.accent
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

    private func actionIcon(_ iconName: String, tint: Color) -> some View {
        Image(systemName: iconName)
            .font(.subheadline.weight(.black))
            .frame(width: 38, height: 38)
            .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(tint)
    }
}

private struct PlaceMemoLine: View {
    var title: String
    var value: String
    var iconName: String
    var tint: Color
    var isPlaceholder = false
    var lineLimit = 2

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.black))
                .foregroundStyle(isPlaceholder ? .secondary : tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(isPlaceholder ? 0.07 : 0.11), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(isPlaceholder ? .secondary : tint)
                Text(value.isEmpty ? "메모 없음" : value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isPlaceholder ? .tertiary : .secondary)
                    .lineLimit(lineLimit)
                    .truncationMode(.tail)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
    }
}

private struct PlaceCardActionLabel: View {
    var title: String
    var iconName: String
    var tint: Color

    var body: some View {
        Label(title, systemImage: iconName)
            .font(.subheadline.weight(.black))
            .lineLimit(1)
            .minimumScaleFactor(0.86)
            .frame(maxWidth: .infinity, minHeight: 46)
            .padding(.horizontal, 10)
            .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(tint)
    }
}

private struct PlaceDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: TripStore
    var place: PlaceCandidate
    @Binding var isEditing: Bool
    @Binding var isScheduling: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ScreenHeader(title: place.name, subtitle: place.category)

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(title: "MEMO")
                        DetailMemoRow(title: "앱 메모", value: place.appNote, iconName: "note.text")
                        DetailMemoRow(title: "지도 메모", value: place.mapNote, iconName: "map")
                    }
                    .appPanel(cornerRadius: 18)

                    HStack(spacing: 8) {
                        Button {
                            dismiss()
                            isScheduling = true
                        } label: {
                            Label("일정에 넣기", systemImage: "calendar.badge.plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            dismiss()
                            isEditing = true
                        } label: {
                            Label("수정", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    if let url = URL(string: place.mapURL) {
                        Link(destination: url) {
                            Label("Google Maps 열기", systemImage: "arrow.up.right.square")
                                .font(.headline.weight(.bold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .readableWidth(560)
                .padding()
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.toggleFavorite(place)
                    } label: {
                        Label(place.isFavorite ? "별표 해제" : "별표", systemImage: place.isFavorite ? "star.fill" : "star")
                    }
                }
            }
        }
        .appScreenBackground()
    }
}

private struct DetailMemoRow: View {
    var title: String
    var value: String
    var iconName: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconName)
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
                Text(value.isEmpty ? "입력 전" : value)
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
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
    @Environment(\.appTheme) private var theme

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
                                        .background(isSameDay(option, date) ? theme.accent : Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
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
        default: return theme.accent
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
    @Environment(\.appTheme) private var theme
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
                                        .background(category == item ? theme.accent : Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
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
    @Environment(\.appTheme) private var theme
    var title: String
    var iconName: String
    var placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Label(title, systemImage: iconName)
                .font(.caption.weight(.black))
                .foregroundStyle(theme.accent)
                .frame(width: 70, alignment: .leading)
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}
