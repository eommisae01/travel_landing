import SwiftUI

struct NotesScreen: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.appTheme) private var theme
    @State private var addSheetOpen = false
    @State private var showAllNotes = false

    private var selectedCityNotes: [NoteGroup] {
        store.notesForSelectedCity()
    }

    private var cityOnlyNotes: [NoteGroup] {
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
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 320, maximum: 420), spacing: 12)], spacing: 12) {
            ForEach(notes) { note in
                noteCard(note)
            }
        }
    }

    private var featuredNotes: [NoteGroup] {
        let imageNotes = visibleDefaultNotes.filter { !$0.imageNames.isEmpty }
        return Array((imageNotes.isEmpty ? visibleDefaultNotes : imageNotes).prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ScreenHeader(title: "Notes", subtitle: "시간표, 예약 캡처, 현장 메모를 도시별로 묶어두는 자료함")

                    notesOverview
                    if !featuredNotes.isEmpty {
                        featuredNotesRail
                    }

                    VStack(alignment: .leading, spacing: 12) {
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

                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader(title: store.currentCity.isEmpty ? "CITY NOTES" : "\(displayCity(store.currentCity))", count: cityOnlyNotes.count)
                        if cityOnlyNotes.isEmpty {
                            EmptyStateView(
                                title: "자료가 비어있어요",
                                message: "시간표, 예약 캡처, 현장 메모를 도시별 보드로 모아둘 수 있습니다.",
                                iconName: "doc.text.image"
                            )
                        } else {
                            noteGrid(cityOnlyNotes)
                        }
                    }
                    .padding(.top, 2)

                    if !hiddenAllNotes.isEmpty {
                        DisclosureGroup(isExpanded: $showAllNotes) {
                            VStack(alignment: .leading, spacing: 10) {
                                noteGrid(hiddenAllNotes)
                            }
                            .padding(.top, 10)
                        } label: {
                            sectionHeader(title: "ALL NOTES", count: hiddenAllNotes.count)
                        }
                        .padding(.top, 2)
                    }
                }
                .readableWidth()
                .padding()
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 11) {
                Image(systemName: "doc.text.image.fill")
                    .font(.headline.weight(.black))
                    .frame(width: 40, height: 40)
                    .background(theme.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 13))
                    .foregroundStyle(theme.accent)

                VStack(alignment: .leading, spacing: 3) {
                    Text(store.currentCity.isEmpty ? "All Trip Materials" : "\(displayCity(store.currentCity)) Materials")
                        .font(.headline.weight(.black))
                    Text("공통 자료와 현재 지역 자료를 먼저 보여줍니다.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text("\(currentNoteCount)")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(theme.accent)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    NoteOverviewChip(title: "공통", value: commonNotes.count, unit: "개", iconName: "tray.full", tint: theme.accent)
                    NoteOverviewChip(title: "지역", value: cityOnlyNotes.count, unit: "개", iconName: "mappin.and.ellipse", tint: theme.secondaryAccent)
                    NoteOverviewChip(title: "이미지", value: store.notes.reduce(0) { $0 + $1.imageNames.count }, unit: "장", iconName: "photo.stack", tint: theme.warmAccent)
                    NoteOverviewChip(title: "전체", value: store.notes.count, unit: "개", iconName: "square.grid.2x2", tint: .secondary)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 8)], spacing: 8) {
                    NoteOverviewChip(title: "공통", value: commonNotes.count, unit: "개", iconName: "tray.full", tint: theme.accent)
                    NoteOverviewChip(title: "지역", value: cityOnlyNotes.count, unit: "개", iconName: "mappin.and.ellipse", tint: theme.secondaryAccent)
                    NoteOverviewChip(title: "이미지", value: store.notes.reduce(0) { $0 + $1.imageNames.count }, unit: "장", iconName: "photo.stack", tint: theme.warmAccent)
                    NoteOverviewChip(title: "전체", value: store.notes.count, unit: "개", iconName: "square.grid.2x2", tint: .secondary)
                }
            }
        }
        .appPanel(cornerRadius: 18)
    }

    private var featuredNotesRail: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                SectionLabel(title: "QUICK BOARD")
                Spacer()
                Text(store.currentCity.isEmpty ? "All Trip" : displayCity(store.currentCity))
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.10), in: Capsule())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
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
        .appPanel(cornerRadius: 18)
    }

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack {
            SectionLabel(title: title)
            Spacer()
            Text("\(count)")
                .font(.caption2.weight(.black))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(.secondary.opacity(0.10), in: Capsule())
        }
    }

    private func noteCard(_ note: NoteGroup) -> some View {
        NavigationLink {
            NoteDetailView(note: note)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    NoteKindIconBadge(iconName: noteKindIcon(note), tint: noteAccent(note))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(note.title)
                            .font(.subheadline.weight(.black))
                            .lineLimit(2)
                            .minimumScaleFactor(0.86)
                        Text(noteKindTitle(note))
                            .font(.caption2.weight(.black))
                            .foregroundStyle(noteAccent(note))
                    }

                    Spacer(minLength: 0)

                    NoteCountBadge(count: note.imageNames.count, tint: noteAccent(note))
                }

                Text(note.body.isEmpty ? "메모 없음" : note.body)
                    .lineLimit(2)
                    .font(.caption.weight(.semibold))
                    .lineSpacing(2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 36, alignment: .topLeading)

                Spacer(minLength: 0)

                noteAttachmentStrip(note)
            }
            .frame(maxWidth: .infinity, minHeight: 158, maxHeight: 158, alignment: .topLeading)
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(noteAccent(note))
                    .frame(width: 3)
                    .padding(.vertical, 13)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(noteAccent(note).opacity(0.10))
            }
        }
        .buttonStyle(.plain)
    }

    private func noteAttachmentStrip(_ note: NoteGroup) -> some View {
        HStack(spacing: 6) {
            if note.imageNames.isEmpty {
                NoteKindPill(title: "텍스트 메모", iconName: "text.alignleft", tint: .secondary)
            } else {
                ForEach(Array(note.imageNames.prefix(3).enumerated()), id: \.offset) { index, imageName in
                    NoteSmallImageTile(title: imageName, index: index, tint: noteAccent(note))
                }
                if note.imageNames.count > 3 {
                    Text("+\(note.imageNames.count - 3)")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(noteAccent(note), in: Circle())
                }
            }
            Spacer(minLength: 0)
            Label("열기", systemImage: "chevron.right")
                .font(.caption2.weight(.black))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(.secondary.opacity(0.08), in: Capsule())
        }
        .frame(maxWidth: .infinity, minHeight: 34, alignment: .center)
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
}

private struct NoteKindPill: View {
    var title: String
    var iconName: String
    var tint: Color

    var body: some View {
        Label(title, systemImage: iconName)
            .font(.caption2.weight(.black))
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
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
            .frame(width: 34, height: 34)
            .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(tint)
    }
}

private struct NoteCountBadge: View {
    var count: Int
    var tint: Color

    var body: some View {
        Label(count == 0 ? "Text" : "\(count)", systemImage: count == 0 ? "doc.text" : "photo.stack")
            .font(.caption2.weight(.black))
            .labelStyle(.titleAndIcon)
            .foregroundStyle(count == 0 ? .secondary : tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background((count == 0 ? Color.secondary : tint).opacity(0.10), in: Capsule())
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
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.22), Color.secondary.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
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
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                accent.opacity(0.22),
                                theme.secondaryAccent.opacity(0.12),
                                Color.secondary.opacity(0.07)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                HStack(alignment: .bottom, spacing: -8) {
                    if note.imageNames.isEmpty {
                        Image(systemName: kindIcon)
                            .font(.title2.weight(.black))
                            .foregroundStyle(accent)
                            .frame(width: 48, height: 48)
                            .background(.background.opacity(0.72), in: RoundedRectangle(cornerRadius: 14))
                    } else {
                        ForEach(Array(note.imageNames.prefix(3).enumerated()), id: \.offset) { index, imageName in
                            MiniImageBadge(title: imageName, index: index, tint: accent)
                                .rotationEffect(.degrees(Double(index - 1) * 3))
                                .offset(y: CGFloat(2 - index) * 4)
                        }
                    }
                }
                .padding(10)
            }
            .frame(height: 88)
            .overlay(alignment: .topTrailing) {
                Label(note.imageNames.isEmpty ? "Text" : "\(note.imageNames.count)", systemImage: note.imageNames.isEmpty ? "text.alignleft" : "photo.stack")
                    .font(.caption2.weight(.black))
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(accent, in: Capsule())
                    .padding(7)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: kindIcon)
                        .font(.caption2.weight(.black))
                    Text(kindTitle)
                        .font(.caption2.weight(.black))
                }
                .foregroundStyle(accent)

                Text(note.title)
                    .font(.subheadline.weight(.black))
                    .lineLimit(2)

                Text(note.body.isEmpty ? "메모 없음" : note.body)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(width: 210, height: 174, alignment: .topLeading)
        .padding(9)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17))
        .overlay {
            RoundedRectangle(cornerRadius: 17)
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
        HStack(spacing: 7) {
            Image(systemName: iconName)
                .foregroundStyle(tint)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(value)")
                        .font(.caption.weight(.black))
                        .monospacedDigit()
                    Text(unit)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
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
            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.accent.opacity(0.22),
                                theme.secondaryAccent.opacity(0.14),
                                Color.secondary.opacity(0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "photo")
                    .font(.title.weight(.bold))
                    .foregroundStyle(theme.accent)
            }
            .frame(height: 88)
            .overlay(alignment: .topTrailing) {
                Text(String(format: "%02d", index + 1))
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(.background.opacity(0.66), in: Capsule())
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(imageName)
                    .font(.subheadline.weight(.black))
                    .lineLimit(2)
                Label("크게 보기", systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 142, maxHeight: 142, alignment: .topLeading)
        .padding(9)
        .background(.background.opacity(0.62), in: RoundedRectangle(cornerRadius: 15))
        .overlay {
            RoundedRectangle(cornerRadius: 15)
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
