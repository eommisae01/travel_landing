import SwiftUI

struct MapScreen: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.appTheme) private var theme
    @Environment(\.appDisplaySize) private var displaySize
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
                VStack(alignment: .leading, spacing: 26) {
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

                            LazyVGrid(columns: placeGridColumns, spacing: 14) {
                                ForEach(places) { place in
                                    PlaceRow(place: place)
                                }
                            }
                        }
                        .padding(18)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(sectionColor(for: category).opacity(0.10))
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
                .readableWidth(1380)
                .padding(horizontalSizeClass == .compact ? 18 : 34)
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
        return [GridItem(.adaptive(minimum: displaySize.size(340), maximum: displaySize.size(460)), spacing: 14)]
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
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 138), spacing: 10)], spacing: 10) {
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
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.black))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 17, weight: .black, design: .rounded))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 13))
        .overlay {
            RoundedRectangle(cornerRadius: 13)
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
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.black))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .lineLimit(1)
                Text(favoriteCount > 0 ? "별표 \(favoriteCount)개 포함" : "후보 \(count)개")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Text("\(count)")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(tint)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(tint.opacity(0.10), in: Capsule())
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .center)
    }
}

struct PlaceRow: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.appTheme) private var theme
    @Environment(\.appDisplaySize) private var displaySize
    var place: PlaceCandidate
    @State private var isEditing = false
    @State private var isScheduling = false
    @State private var isShowingDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: displaySize.size(10)) {
            cardHeader

            memoPreview

            Spacer(minLength: 0)

            actionBar
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isShowingDetail = true
        }
        .frame(maxWidth: .infinity, minHeight: displaySize.size(222), alignment: .topLeading)
        .padding(displaySize.size(14))
        .background(.background.opacity(0.98), in: RoundedRectangle(cornerRadius: 18))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(categoryColor)
                .frame(width: 3)
                .padding(.vertical, 18)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(categoryColor.opacity(place.isFavorite ? 0.32 : 0.13), lineWidth: place.isFavorite ? 1.1 : 0.8)
        }
        .shadow(color: Color.primary.opacity(0.020), radius: 9, x: 0, y: 4)
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
        HStack(alignment: .top, spacing: displaySize.size(10)) {
            categoryBadge

            VStack(alignment: .leading, spacing: displaySize.size(6)) {
                Text(place.name)
                    .font(.system(size: displaySize.size(18), weight: .black, design: .rounded))
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: displaySize.size(40), alignment: .topLeading)

                cardBadges
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            HStack(spacing: 6) {
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
                .font(.system(size: displaySize.size(18), weight: .black))
                .foregroundStyle(categoryColor)
        }
        .frame(width: displaySize.size(38), height: displaySize.size(38))
    }

    private var actionBar: some View {
        HStack(spacing: displaySize.size(6)) {
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
        .padding(displaySize.size(5))
        .background(.secondary.opacity(0.045), in: RoundedRectangle(cornerRadius: 14))
    }

    private var memoPreview: some View {
        let hasBothNotes = !place.mapNote.isEmpty && !place.appNote.isEmpty

        return VStack(alignment: .leading, spacing: 6) {
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
                        lineLimit: hasBothNotes ? 1 : 3
                    )
                }
                if !place.appNote.isEmpty {
                    PlaceMemoLine(
                        title: "앱 메모",
                        value: place.appNote,
                        iconName: "note.text",
                        tint: .secondary,
                        lineLimit: hasBothNotes ? 1 : 3
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: displaySize.size(70), alignment: .topLeading)
        .padding(.horizontal, displaySize.size(10))
        .padding(.vertical, displaySize.size(9))
        .background(categoryColor.opacity(0.035), in: RoundedRectangle(cornerRadius: 13))
        .overlay {
            RoundedRectangle(cornerRadius: 13)
                .stroke(categoryColor.opacity(0.075))
        }
    }

    private var cardBadges: some View {
        HStack(spacing: 6) {
            Text(place.category)
                .font(.system(size: displaySize.size(11), weight: .black, design: .rounded))
                .foregroundStyle(categoryColor)
                .lineLimit(1)
                .padding(.horizontal, displaySize.size(8))
                .padding(.vertical, displaySize.size(4))
                .background(categoryColor.opacity(0.10), in: Capsule())

            if place.isFavorite {
                Label("Favorite", systemImage: "star.fill")
                .font(.system(size: displaySize.size(11), weight: .black))
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.yellow)
                    .frame(width: displaySize.size(22), height: displaySize.size(22))
                    .background(.yellow.opacity(0.13), in: Capsule())
                    .accessibilityLabel("별표")
            }

            if URL(string: place.mapURL) != nil {
                Image(systemName: "link")
                    .font(.system(size: displaySize.size(11), weight: .black))
                    .foregroundStyle(.blue)
                    .frame(width: displaySize.size(22), height: displaySize.size(22))
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
            .font(.system(size: displaySize.size(15), weight: .black))
            .frame(width: displaySize.size(30), height: displaySize.size(30))
            .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(tint)
    }
}

private struct PlaceMemoLine: View {
    @Environment(\.appDisplaySize) private var displaySize
    var title: String
    var value: String
    var iconName: String
    var tint: Color
    var isPlaceholder = false
    var lineLimit = 2

    var body: some View {
        HStack(alignment: .top, spacing: displaySize.size(8)) {
            Image(systemName: iconName)
                .font(.system(size: displaySize.size(11), weight: .black))
                .foregroundStyle(isPlaceholder ? .secondary : tint)
                .frame(width: displaySize.size(24), height: displaySize.size(24))
                .background(tint.opacity(isPlaceholder ? 0.065 : 0.10), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: displaySize.size(10), weight: .black, design: .rounded))
                    .foregroundStyle(isPlaceholder ? .secondary : tint)
                Text(value.isEmpty ? "메모 없음" : value)
                    .font(.system(size: displaySize.size(12), weight: .semibold, design: .rounded))
                    .foregroundStyle(isPlaceholder ? .tertiary : .secondary)
                    .lineLimit(lineLimit)
                    .truncationMode(.tail)
            }
        }
        .frame(maxWidth: .infinity, minHeight: displaySize.size(30), alignment: .leading)
    }
}

private struct PlaceCardActionLabel: View {
    @Environment(\.appDisplaySize) private var displaySize
    var title: String
    var iconName: String
    var tint: Color

    var body: some View {
        Label(title, systemImage: iconName)
            .font(.system(size: displaySize.size(11), weight: .black, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.86)
            .frame(maxWidth: .infinity, minHeight: displaySize.size(32))
            .padding(.horizontal, displaySize.size(7))
            .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
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
                VStack(alignment: .leading, spacing: 18) {
                    ScreenHeader(title: place.name, subtitle: place.category)

                    VStack(alignment: .leading, spacing: 14) {
                        SectionLabel(title: "MEMO")
                        DetailMemoRow(title: "앱 메모", value: place.appNote, iconName: "note.text")
                        DetailMemoRow(title: "지도 메모", value: place.mapNote, iconName: "map")
                    }
                    .appPanel(cornerRadius: 22)

                    HStack(spacing: 10) {
                        Button {
                            dismiss()
                            isScheduling = true
                        } label: {
                            Label("일정에 넣기", systemImage: "calendar.badge.plus")
                                .frame(maxWidth: .infinity)
                                .font(.headline.weight(.black))
                                .padding(.vertical, 7)
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            dismiss()
                            isEditing = true
                        } label: {
                            Label("수정", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                                .font(.headline.weight(.black))
                                .padding(.vertical, 7)
                        }
                        .buttonStyle(.bordered)
                    }

                    if let url = URL(string: place.mapURL) {
                        Link(destination: url) {
                            Label("Google Maps 열기", systemImage: "arrow.up.right.square")
                                .font(.headline.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .readableWidth(620)
                .padding(24)
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
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.headline.weight(.black))
                .foregroundStyle(.secondary)
                .frame(width: 40, height: 40)
                .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.callout.weight(.black))
                    .foregroundStyle(.secondary)
                Text(value.isEmpty ? "입력 전" : value)
                    .font(.body.weight(.semibold))
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
                VStack(alignment: .leading, spacing: 18) {
                    ScreenHeader(title: "일정에 넣기", subtitle: place.name)

                    VStack(alignment: .leading, spacing: 14) {
                        SectionLabel(title: "WHEN")
                        if dateOptions.isEmpty {
                            DatePicker("날짜", selection: $date, displayedComponents: .date)
                                .datePickerStyle(.compact)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 10)], spacing: 10) {
                                ForEach(Array(dateOptions.enumerated()), id: \.offset) { index, option in
                                    Button {
                                        date = option
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Day \(index + 1)")
                                                .font(.caption.weight(.black))
                                            Text(compactDayLabel(option))
                                                .font(.callout.weight(.black))
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 11)
                                        .padding(.vertical, 10)
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
                    .appPanel(cornerRadius: 22)

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "PLACE")
                        HStack(spacing: 12) {
                            Image(systemName: placeIcon)
                                .font(.title3.weight(.bold))
                                .frame(width: 46, height: 46)
                                .background(placeTint.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(placeTint)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(place.name)
                                    .font(.title3.weight(.black))
                                Text(place.category)
                                    .font(.callout.weight(.bold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if !place.mapNote.isEmpty {
                            Label(place.mapNote, systemImage: "map")
                                .font(.callout.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .appPanel(cornerRadius: 22)

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "MEMO")
                        TextField("일정에 같이 남길 메모", text: $note, axis: .vertical)
                            .font(.body.weight(.semibold))
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                    .appPanel(cornerRadius: 22)
                }
                .readableWidth(680)
                .padding(24)
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
