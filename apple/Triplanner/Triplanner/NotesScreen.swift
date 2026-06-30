import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct NotesScreen: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.appTheme) private var theme
    @Environment(\.appDisplaySize) private var displaySize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var addSheetOpen = false
    @State private var showAllNotes = false

    private var selectedCityNotes: [NoteGroup] {
        store.notesForSelectedCity()
    }

    private var cityOnlyNotes: [NoteGroup] {
        guard !store.currentCity.isEmpty else { return [] }
        let commonIDs = Set(commonNotes.map(\.id))
        return selectedCityNotes.filter { !commonIDs.contains($0.id) }
    }

    private var commonNotes: [NoteGroup] {
        store.notes.filter { note in
            let text = noteSearchText(note)
            guard let cities = store.trip?.cities, !cities.isEmpty else { return true }
            return !cities.contains { city in
                text.localizedCaseInsensitiveContains(city) ||
                text.localizedCaseInsensitiveContains(displayCity(city))
            }
        }
    }

    private var hiddenAllNotes: [NoteGroup] {
        let visibleIDs = Set((commonNotes + cityOnlyNotes).map(\.id))
        return store.notes.filter { !visibleIDs.contains($0.id) }
    }

    private var visibleDefaultNotes: [NoteGroup] {
        commonNotes + cityOnlyNotes
    }

    private var currentNoteCount: Int {
        commonNotes.count + cityOnlyNotes.count
    }

    private func noteSearchText(_ note: NoteGroup) -> String {
        "\(note.title) \(note.body)"
    }

    private func noteGrid(_ notes: [NoteGroup]) -> some View {
        LazyVGrid(columns: noteGridColumns, spacing: 14) {
            ForEach(notes) { note in
                noteCard(note)
            }
        }
    }

    private var noteGridColumns: [GridItem] {
        if horizontalSizeClass == .compact {
            return [GridItem(.flexible(), spacing: 16)]
        }
        return [GridItem(.adaptive(minimum: 320, maximum: 460), spacing: 14)]
    }

    private var featuredNotes: [NoteGroup] {
        let imageNotes = visibleDefaultNotes.filter { !$0.imageNames.isEmpty }
        return Array((imageNotes.isEmpty ? visibleDefaultNotes : imageNotes).prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    ScreenHeader(title: "Notes", subtitle: "시간표, 예약 캡처, 현장 메모를 도시별로 묶어두는 자료함")

                    notesOverview
                    if !featuredNotes.isEmpty {
                        featuredNotesRail
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        sectionHeader(title: "COMMON", count: commonNotes.count)
                        if commonNotes.isEmpty {
                            EmptyStateView(
                                title: "공통 자료가 비어있어요",
                                message: "여러 도시에서 같이 필요한 예약, 준비, 이동 자료를 여기에 모아둘 수 있습니다.",
                                iconName: "tray.full"
                            )
                        } else {
                            noteGrid(commonNotes)
                        }
                    }
                    .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 14) {
                        sectionHeader(title: currentAreaTitle, count: cityOnlyNotes.count)
                        if cityOnlyNotes.isEmpty {
                            EmptyStateView(
                                title: store.currentCity.isEmpty ? "지역을 고르면 해당 자료가 보여요" : "자료가 비어있어요",
                                message: store.currentCity.isEmpty ? "상단의 Trip 메뉴에서 도시를 선택하면 그 지역 자료만 모아볼 수 있습니다." : "시간표, 예약 캡처, 현장 메모를 도시별 보드로 모아둘 수 있습니다.",
                                iconName: "doc.text.image"
                            )
                        } else {
                            noteGrid(cityOnlyNotes)
                        }
                    }
                    .padding(.top, 2)

                    if !hiddenAllNotes.isEmpty {
                        DisclosureGroup(isExpanded: $showAllNotes) {
                            VStack(alignment: .leading, spacing: 16) {
                                noteGrid(hiddenAllNotes)
                            }
                            .padding(.top, 10)
                        } label: {
                            AllNotesDisclosureLabel(
                                count: hiddenAllNotes.count,
                                isExpanded: showAllNotes,
                                tint: .secondary
                            )
                        }
                        .padding(12)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.primary.opacity(0.055))
                        }
                        .padding(.top, 2)
                    }
                }
                .readableWidth(1320)
                .padding(horizontalSizeClass == .compact ? 18 : 34)
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        addSheetOpen = true
                    } label: {
                        Label("노트 추가", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $addSheetOpen) {
                AddNoteSheet()
                    .environmentObject(store)
            }
        }
        .appScreenBackground()
    }

    private var notesOverview: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "doc.text.image.fill")
                    .font(.system(size: 18, weight: .black))
                    .frame(width: 42, height: 42)
                    .background(theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                    .foregroundStyle(theme.accent)

                VStack(alignment: .leading, spacing: 3) {
                    Text(store.currentCity.isEmpty ? "Common Materials" : "\(displayCity(store.currentCity)) Materials")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                    Text(store.currentCity.isEmpty ? "공통 자료를 먼저 보고, 지역 자료는 All Notes에서 펼쳐봅니다." : "공통 자료와 현재 지역 자료를 먼저 보여줍니다.")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Text("\(currentNoteCount)")
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(theme.accent)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    NoteOverviewChip(title: "공통", value: commonNotes.count, unit: "개", iconName: "tray.full", tint: theme.accent)
                    NoteOverviewChip(title: "지역", value: cityOnlyNotes.count, unit: "개", iconName: "mappin.and.ellipse", tint: theme.secondaryAccent)
                    NoteOverviewChip(title: "이미지", value: store.notes.reduce(0) { $0 + $1.imageNames.count }, unit: "장", iconName: "photo.stack", tint: theme.warmAccent)
                    NoteOverviewChip(title: "전체", value: store.notes.count, unit: "개", iconName: "square.grid.2x2", tint: .secondary)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                    NoteOverviewChip(title: "공통", value: commonNotes.count, unit: "개", iconName: "tray.full", tint: theme.accent)
                    NoteOverviewChip(title: "지역", value: cityOnlyNotes.count, unit: "개", iconName: "mappin.and.ellipse", tint: theme.secondaryAccent)
                    NoteOverviewChip(title: "이미지", value: store.notes.reduce(0) { $0 + $1.imageNames.count }, unit: "장", iconName: "photo.stack", tint: theme.warmAccent)
                    NoteOverviewChip(title: "전체", value: store.notes.count, unit: "개", iconName: "square.grid.2x2", tint: .secondary)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.055))
        }
    }

    private var featuredNotesRail: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionLabel(title: "빠른 자료")
                Spacer()
                Text(store.currentCity.isEmpty ? "All Trip" : displayCity(store.currentCity))
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.secondary.opacity(0.10), in: Capsule())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(featuredNotes) { note in
                        NavigationLink {
                            NoteDetailView(note: note)
                        } label: {
                            FeaturedNoteTile(note: note, accent: noteAccent(note), kindTitle: noteKindTitle(note), kindIcon: noteKindIcon(note))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.primary.opacity(0.055))
        }
    }

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: sectionIcon(title))
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(sectionTint(title))
                .frame(width: 38, height: 38)
                .background(sectionTint(title).opacity(0.11), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(displaySectionTitle(title))
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(sectionSubtitle(title))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
            Text("\(count)")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(sectionTint(title))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(sectionTint(title).opacity(0.10), in: Capsule())
        }
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .center)
    }

    private func sectionTint(_ title: String) -> Color {
        if title == "COMMON" { return theme.accent }
        if title == "ALL NOTES" { return .secondary }
        return theme.secondaryAccent
    }

    private func sectionIcon(_ title: String) -> String {
        if title == "COMMON" { return "tray.full.fill" }
        if title == "ALL NOTES" { return "square.grid.2x2.fill" }
        return "mappin.and.ellipse"
    }

    private func sectionSubtitle(_ title: String) -> String {
        if title == "COMMON" { return "여러 지역에서 같이 쓰는 자료" }
        if title == "ALL NOTES" { return "다른 지역 자료까지 펼쳐 보기" }
        if store.currentCity.isEmpty { return "도시를 선택하면 이 영역이 채워져요" }
        return "현재 여행지에서 바로 볼 자료"
    }

    private func displaySectionTitle(_ title: String) -> String {
        if title == "COMMON" { return "공통 자료" }
        if title == "CURRENT AREA" { return "지역 자료" }
        if title == "ALL NOTES" { return "전체 Notes" }
        return title
    }

    private var currentAreaTitle: String {
        store.currentCity.isEmpty ? "CURRENT AREA" : displayCity(store.currentCity)
    }

    private func noteCard(_ note: NoteGroup) -> some View {
        NavigationLink {
            NoteDetailView(note: note)
        } label: {
            HStack(alignment: .top, spacing: displaySize.size(12)) {
                noteThumbnail(note)
                noteCardText(note)
            }
            .frame(maxWidth: .infinity, minHeight: displaySize.size(142), alignment: .topLeading)
            .padding(displaySize.size(12))
            .background(.background.opacity(0.96), in: RoundedRectangle(cornerRadius: 18))
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(noteAccent(note))
                    .frame(width: 3)
                    .padding(.vertical, 15)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(noteAccent(note).opacity(0.13))
            }
            .shadow(color: Color.primary.opacity(0.014), radius: 7, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func noteThumbnail(_ note: NoteGroup) -> some View {
        RepresentativeNoteThumbnail(
            imageName: note.imageNames.first,
            iconName: note.imageNames.isEmpty ? noteKindIcon(note) : "photo",
            tint: noteAccent(note),
            compact: false,
            board: true
        )
        .overlay(alignment: .topTrailing) {
            if note.imageNames.count > 1 {
                NoteCountBadge(count: note.imageNames.count, tint: noteAccent(note))
                    .padding(8)
            }
        }
    }

    private func noteCardText(_ note: NoteGroup) -> some View {
        VStack(alignment: .leading, spacing: displaySize.size(10)) {
            VStack(alignment: .leading, spacing: displaySize.size(8)) {
                Text(note.title)
                    .font(.system(size: displaySize.size(17), weight: .black, design: .rounded))
                    .lineLimit(2)
                    .minimumScaleFactor(0.84)

                HStack(spacing: 7) {
                    NoteKindPill(title: noteKindTitle(note), iconName: noteKindIcon(note), tint: noteAccent(note))
                    NoteKindPill(title: noteScopeTitle(note), iconName: noteScopeIcon(note), tint: noteScopeTint(note))
                }
            }

            Text(note.body.isEmpty ? "메모 없음" : note.body)
                .lineLimit(2)
                .font(.system(size: displaySize.size(12), weight: .semibold, design: .rounded))
                .lineSpacing(3)
                .foregroundStyle(note.body.isEmpty ? .tertiary : .secondary)
                .frame(maxWidth: .infinity, minHeight: displaySize.size(34), alignment: .topLeading)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Label(note.imageNames.isEmpty ? "텍스트 메모" : "\(note.imageNames.count)장 자료", systemImage: note.imageNames.isEmpty ? "text.alignleft" : "photo.stack")
                    .font(.system(size: displaySize.size(11), weight: .black, design: .rounded))
                    .foregroundStyle(noteAccent(note))
                Spacer(minLength: 0)
                Text("열기")
                    .font(.system(size: displaySize.size(11), weight: .black, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, displaySize.size(10))
                    .padding(.vertical, displaySize.size(6))
                    .background(.secondary.opacity(0.08), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func noteAttachmentStrip(_ note: NoteGroup) -> some View {
        HStack(spacing: 10) {
            if note.imageNames.isEmpty {
                RepresentativeNoteThumbnail(imageName: nil, iconName: "text.alignleft", tint: .secondary, compact: true)
                NoteAttachmentSummary(
                    title: "텍스트 메모",
                    detail: "이미지 없음",
                    iconName: "text.alignleft",
                    tint: .secondary
                )
            } else {
                RepresentativeNoteThumbnail(imageName: note.imageNames.first, iconName: "photo", tint: noteAccent(note), compact: true)
                NoteAttachmentSummary(
                    title: note.imageNames.count == 1 ? "1장 자료" : "\(note.imageNames.count)장 묶음",
                    detail: "탭해서 크게 보기",
                    iconName: "photo.stack",
                    tint: noteAccent(note)
                )
            }

            Spacer(minLength: 0)

            Label("보기", systemImage: "chevron.right")
                .font(.caption2.weight(.black))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(.secondary.opacity(0.08), in: Capsule())
        }
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .center)
    }

    private func displayCity(_ city: String) -> String {
        switch city {
        case "타카마쓰": return "Takamatsu"
        case "나오시마": return "Naoshima"
        case "도쿄": return "Tokyo"
        default: return city.isEmpty ? "All Trip" : city
        }
    }

    private func noteAccent(_ note: NoteGroup) -> Color {
        let value = (note.title + " " + note.body).lowercased()
        if value.contains("페리") || value.contains("버스") || value.contains("교통") { return theme.secondaryAccent }
        if value.contains("예약") || value.contains("미술관") || value.contains("ticket") { return theme.warmAccent }
        if value.contains("공항") || value.contains("atm") || value.contains("환전") { return .orange }
        if value.contains("식당") || value.contains("카페") { return .pink }
        return theme.accent
    }

    private func noteKindTitle(_ note: NoteGroup) -> String {
        let value = note.title + " " + note.body
        if value.contains("페리") || value.contains("버스") || value.contains("교통") { return "이동" }
        if value.contains("예약") || value.contains("미술관") { return "예약" }
        if value.contains("공항") || value.contains("ATM") || value.contains("환전") { return "현장" }
        if value.contains("식당") || value.contains("카페") { return "후보" }
        return "메모"
    }

    private func noteKindIcon(_ note: NoteGroup) -> String {
        switch noteKindTitle(note) {
        case "이동": return "tram.fill"
        case "예약": return "ticket.fill"
        case "현장": return "exclamationmark.circle.fill"
        case "후보": return "fork.knife"
        default: return "doc.text.fill"
        }
    }

    private func noteScopeTitle(_ note: NoteGroup) -> String {
        if commonNotes.contains(where: { $0.id == note.id }) { return "공통" }
        if store.currentCity.isEmpty { return "지역" }
        if selectedCityNotes.contains(where: { $0.id == note.id }) { return displayCity(store.currentCity) }
        return "다른 지역"
    }

    private func noteScopeIcon(_ note: NoteGroup) -> String {
        if commonNotes.contains(where: { $0.id == note.id }) { return "tray.full.fill" }
        return "mappin.and.ellipse"
    }

    private func noteScopeTint(_ note: NoteGroup) -> Color {
        if commonNotes.contains(where: { $0.id == note.id }) { return theme.accent }
        if selectedCityNotes.contains(where: { $0.id == note.id }) { return theme.secondaryAccent }
        return .secondary
    }
}

private struct AllNotesDisclosureLabel: View {
    var count: Int
    var isExpanded: Bool
    var tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.subheadline.weight(.black))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text("전체 Notes")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.primary)
                Text("다른 지역 자료까지 \(isExpanded ? "접기" : "펼쳐 보기")")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Text("\(count)")
                .font(.subheadline.weight(.black))
                .foregroundStyle(tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(tint.opacity(0.10), in: Capsule())

            Image(systemName: "chevron.down")
                .font(.subheadline.weight(.black))
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
        }
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .center)
        .contentShape(Rectangle())
    }
}

private struct NoteKindPill: View {
    var title: String
    var iconName: String
    var tint: Color

    var body: some View {
        Label(title, systemImage: iconName)
            .font(.system(size: 11, weight: .black, design: .rounded))
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.11), in: Capsule())
            .foregroundStyle(tint)
    }
}

private struct NoteKindIconBadge: View {
    var iconName: String
    var tint: Color

    var body: some View {
        Image(systemName: iconName)
            .font(.subheadline.weight(.black))
            .frame(width: 32, height: 32)
            .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(tint)
    }
}

private struct NoteCountBadge: View {
    var count: Int
    var tint: Color

    var body: some View {
        Label("\(count)", systemImage: "photo.stack")
            .font(.system(size: 12, weight: .black, design: .rounded))
            .labelStyle(.titleAndIcon)
            .foregroundStyle(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(tint, in: Capsule())
    }
}

private struct NoteAttachmentSummary: View {
    var title: String
    var detail: String
    var iconName: String
    var tint: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: iconName)
                .font(.caption.weight(.black))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption.weight(.black))
                    .foregroundStyle(tint)
                    .lineLimit(1)
                Text(detail.isEmpty ? "상세 보기에서 확인" : detail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: 260, alignment: .leading)
    }
}

private struct RepresentativeNoteThumbnail: View {
    @Environment(\.appDisplaySize) private var displaySize
    var imageName: String?
    var iconName: String
    var tint: Color
    var compact = false
    var board = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.regularMaterial)

            thumbnailArtwork

            if compact {
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(tint)
                    .frame(width: 28, height: 28)
                    .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 9))
                    .padding(7)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                Image(systemName: iconName)
                    .font(.system(size: board ? 15 : 18, weight: .black))
                    .foregroundStyle(tint)
                    .frame(width: board ? 34 : 42, height: board ? 34 : 42)
                    .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: board ? 11 : 13))
                    .padding(board ? 8 : 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            if let imageName, !compact {
                thumbnailCaption(imageName)
            }
        }
        .frame(width: thumbnailWidth, height: thumbnailHeight)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(tint.opacity(0.14))
        }
        .accessibilityLabel(imageName ?? "텍스트 메모")
    }

    private var thumbnailWidth: CGFloat {
        if board { return displaySize.size(116) }
        return compact ? 92 : displaySize.size(260)
    }

    private var thumbnailHeight: CGFloat {
        if board { return displaySize.size(96) }
        return compact ? 68 : displaySize.size(132)
    }

    private var cornerRadius: CGFloat {
        if board { return displaySize.size(16) }
        return compact ? 14 : displaySize.size(24)
    }

    @ViewBuilder
    private var thumbnailArtwork: some View {
        if let imageName, hasImageAsset(named: imageName) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: thumbnailWidth, height: thumbnailHeight)
                .clipped()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: compact ? 12 : 22)
                    .fill(tint.opacity(compact ? 0.085 : 0.095))
                    .padding(compact || board ? 5 : 10)
                Circle()
                    .fill(tint.opacity(compact ? 0.16 : 0.13))
                    .frame(width: compact ? 40 : (board ? 54 : 108), height: compact ? 40 : (board ? 54 : 108))
                    .offset(x: compact ? 23 : (board ? 34 : 62), y: compact ? -10 : (board ? -18 : -40))
                RoundedRectangle(cornerRadius: compact ? 9 : 18)
                    .fill(.background.opacity(compact ? 0.66 : 0.78))
                    .frame(width: compact ? 48 : (board ? 72 : 140), height: compact ? 22 : (board ? 34 : 54))
                    .rotationEffect(.degrees(-3))
                    .offset(x: compact ? -12 : (board ? -18 : -32), y: compact ? 12 : (board ? 16 : 26))
                RoundedRectangle(cornerRadius: compact ? 8 : 16)
                    .fill(tint.opacity(compact ? 0.20 : 0.22))
                    .frame(width: compact ? 32 : (board ? 48 : 92), height: compact ? 17 : (board ? 24 : 38))
                    .rotationEffect(.degrees(5))
                    .offset(x: compact ? 16 : (board ? 34 : 58), y: compact ? 13 : (board ? 26 : 42))
                Image(systemName: imageName == nil ? iconName : "photo.on.rectangle.angled")
                    .font(.system(size: compact ? 18 : (board ? 22 : 36), weight: .black))
                    .foregroundStyle(tint.opacity(0.82))
            }
        }
    }

    private func thumbnailCaption(_ imageName: String) -> some View {
        VStack(alignment: .leading, spacing: compact ? 1 : 3) {
            Text(imageName)
                .font(.system(size: compact || board ? 10 : 12, weight: .black, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(compact ? 1 : 2)
                .minimumScaleFactor(0.76)
        }
        .padding(.horizontal, compact || board ? 7 : 9)
        .padding(.vertical, compact || board ? 5 : 7)
        .frame(maxWidth: compact ? 66 : (board ? 88 : 166), alignment: .leading)
        .background(.background.opacity(0.88), in: RoundedRectangle(cornerRadius: compact || board ? 9 : 11))
        .padding(compact || board ? 6 : 10)
    }

    private func hasImageAsset(named name: String) -> Bool {
        #if os(iOS)
        return UIImage(named: name) != nil
        #elseif os(macOS)
        return NSImage(named: name) != nil
        #else
        return false
        #endif
    }
}

private struct NoteStackPreview: View {
    var imageNames: [String]
    var tint: Color

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: -12) {
                ForEach(Array(imageNames.prefix(3).enumerated()), id: \.offset) { index, imageName in
                    MiniImageBadge(title: imageName, index: index, tint: tint, compact: true)
                        .rotationEffect(.degrees(Double(index - 1) * 2.5))
                        .offset(y: CGFloat(index) * 2)
                        .zIndex(Double(3 - index))
                }
            }

            Text("\(imageNames.count)")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(tint, in: Circle())
                .offset(x: 7, y: -7)
        }
        .padding(.horizontal, 4)
        .frame(width: 82, height: 44, alignment: .leading)
        .background(tint.opacity(0.07), in: RoundedRectangle(cornerRadius: 13))
        .overlay {
            RoundedRectangle(cornerRadius: 13)
                .stroke(tint.opacity(0.10))
        }
        .accessibilityLabel("\(imageNames.count)장 자료")
    }
}

private struct NoteSmallImageTile: View {
    var title: String
    var index: Int
    var tint: Color

    var body: some View {
        HStack(spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(tint.opacity(0.13))
                Image(systemName: "photo")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(tint)
            }
            .frame(width: 25, height: 25)
            .overlay(alignment: .topTrailing) {
                Text("\(index + 1)")
                    .font(.system(size: 7, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 13, height: 13)
                    .background(tint, in: Circle())
                    .offset(x: 4, y: -4)
            }

            Text(title)
                .font(.caption2.weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .foregroundStyle(tint)
        .frame(maxWidth: 88, minHeight: 30, alignment: .leading)
        .padding(.horizontal, 7)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 11))
    }
}

private struct FeaturedNoteTile: View {
    @Environment(\.appTheme) private var theme
    var note: NoteGroup
    var accent: Color
    var kindTitle: String
    var kindIcon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            RepresentativeNoteThumbnail(
                imageName: note.imageNames.first,
                iconName: note.imageNames.isEmpty ? kindIcon : "photo",
                tint: accent,
                board: true
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .topTrailing) {
                if note.imageNames.count > 1 {
                    NoteCountBadge(count: note.imageNames.count, tint: accent)
                        .padding(8)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: kindIcon)
                        .font(.system(size: 14, weight: .black))
                    Text(kindTitle)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                }
                .foregroundStyle(accent)

                Text(note.title)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .lineLimit(2)

                Text(note.body.isEmpty ? "메모 없음" : note.body)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .lineSpacing(2)
            }
        }
        .frame(width: 250, height: 260, alignment: .topLeading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(accent.opacity(0.10))
        }
    }
}

private struct NoteOverviewChip: View {
    var title: String
    var value: Int
    var unit: String
    var iconName: String
    var tint: Color

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: iconName)
                .foregroundStyle(tint)
                .font(.system(size: 17, weight: .black))
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(value)")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .monospacedDigit()
                    Text(unit)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(tint.opacity(0.075), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(tint.opacity(0.10))
        }
    }
}

struct AddNoteSheet: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""
    @State private var imageText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ScreenHeader(title: "자료 추가", subtitle: "시간표, 예약, 현장 정보를 한 묶음으로 저장합니다.")

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "제목")
                        TextField("예: 페리 시간표", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }
                    .appPanel()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "메모")
                        TextField("메모", text: $bodyText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(5...12)
                    }
                    .appPanel()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "이미지 묶음")
                        TextField("예: 페리 전체, 왕복 시간표, 버스 환승", text: $imageText)
                            .textFieldStyle(.roundedBorder)
                        Text("여러 장은 쉼표로 구분해두면 자료 상세에서 묶음으로 보입니다.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
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
                    Button("추가") {
                        store.addNote(title: title, body: bodyText, imageNames: parsedImages)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .appScreenBackground()
    }

    private var parsedImages: [String] {
        imageText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

struct NoteDetailView: View {
    @Environment(\.appTheme) private var theme
    var note: NoteGroup
    @State private var selectedImageIndex: Int?

    private var imageColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 148), spacing: 9)]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "doc.text.image")
                            .font(.title3.weight(.black))
                            .frame(width: 40, height: 40)
                            .background(theme.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 13))
                            .foregroundStyle(theme.accent)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.title)
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .lineLimit(2)
                            Text(note.imageNames.isEmpty ? "텍스트 자료" : "\(note.imageNames.count)장의 자료 묶음")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }

                    if !note.body.isEmpty {
                        Text(note.body)
                            .font(.subheadline)
                            .lineSpacing(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(11)
                            .background(.background.opacity(0.50), in: RoundedRectangle(cornerRadius: 13))
                    }
                }
                .appPanel(cornerRadius: 18)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        SectionLabel(title: "이미지 묶음")
                        Spacer()
                        if !note.imageNames.isEmpty {
                            Label("\(note.imageNames.count)장", systemImage: "photo.stack")
                                .font(.caption2.weight(.black))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(.secondary.opacity(0.10), in: Capsule())
                        }
                    }

                    if note.imageNames.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.largeTitle)
                                .foregroundStyle(theme.accent)
                            Text("시간표나 예약 캡처 이름을 추가하면 이곳에서 묶음 자료처럼 넘겨볼 수 있습니다.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 150)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    } else {
                        LazyVGrid(columns: imageColumns, spacing: 10) {
                            ForEach(Array(note.imageNames.enumerated()), id: \.offset) { index, imageName in
                                Button {
                                    selectedImageIndex = index
                                } label: {
                                    NoteImageTile(imageName: imageName, index: index)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .appPanel(cornerRadius: 18)
            }
            .readableWidth()
            .padding()
        }
        .navigationTitle("")
        .appScreenBackground()
        .sheet(isPresented: Binding(
            get: { selectedImageIndex != nil },
            set: { isPresented in
                if !isPresented {
                    selectedImageIndex = nil
                }
            }
        )) {
            if let selectedImageIndex {
                NoteImagePreview(note: note, initialIndex: selectedImageIndex)
            }
        }
    }
}

private struct MiniImageBadge: View {
    var title: String
    var index: Int
    var tint: Color
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: "photo")
                    .font(.caption2.weight(.black))
                Text("\(index + 1)")
                    .font(.caption2.weight(.black))
            }
            Text(title)
                .font(.system(size: 8, weight: .black))
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .frame(width: compact ? 36 : 42, height: compact ? 30 : 34, alignment: .leading)
        .padding(.horizontal, compact ? 6 : 7)
        .background(.background.opacity(index == 0 ? 0.86 : 0.70), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.background, lineWidth: 2)
        }
    }
}

private struct NoteImageTile: View {
    @Environment(\.appTheme) private var theme
    var imageName: String
    var index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RepresentativeNoteThumbnail(imageName: imageName, iconName: "photo", tint: theme.accent)
                .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .topTrailing) {
                Text(String(format: "%02d", index + 1))
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(theme.accent, in: Capsule())
                    .padding(10)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(imageName)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .lineLimit(2)
                Label("크게 보기", systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 304, maxHeight: 304, alignment: .topLeading)
        .padding(12)
        .background(.background.opacity(0.72), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(.quaternary)
        }
    }
}

private struct NoteImagePreview: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    var note: NoteGroup
    var initialIndex: Int
    @State private var index = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.title)
                        .font(.headline.weight(.black))
                    Text("\(index + 1) / \(note.imageNames.count)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(.regularMaterial)
                    VStack(spacing: 14) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundStyle(theme.accent)
                        Text(currentImageName)
                            .font(.title2.weight(.black))
                            .multilineTextAlignment(.center)
                        Text("자료 묶음 안에서 필요한 캡처를 빠르게 넘겨볼 수 있습니다.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                }
                .frame(maxWidth: .infinity, minHeight: 310)
                .overlay {
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(.quaternary)
                }

                if note.imageNames.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(note.imageNames.enumerated()), id: \.offset) { itemIndex, imageName in
                                Button {
                                    index = itemIndex
                                } label: {
                                    HStack(spacing: 6) {
                                        Text("\(itemIndex + 1)")
                                            .font(.caption2.weight(.black))
                                            .foregroundStyle(itemIndex == index ? .white : theme.accent)
                                            .frame(width: 20, height: 20)
                                            .background(itemIndex == index ? theme.accent : theme.accent.opacity(0.12), in: Circle())
                                        Text(imageName)
                                            .font(.caption.weight(.black))
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 7)
                                    .background(itemIndex == index ? theme.accent.opacity(0.12) : Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        index = max(index - 1, 0)
                    } label: {
                        Label("이전", systemImage: "chevron.left")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(index == 0)

                    Button {
                        index = min(index + 1, max(note.imageNames.count - 1, 0))
                    } label: {
                        Label("다음", systemImage: "chevron.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(index >= note.imageNames.count - 1)
                }
            }
            .padding()
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(Color.secondary.opacity(0.035))
            .navigationTitle("자료 보기")
            .onAppear {
                index = min(max(initialIndex, 0), max(note.imageNames.count - 1, 0))
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    private var currentImageName: String {
        guard note.imageNames.indices.contains(index) else { return "자료" }
        return note.imageNames[index]
    }
}
