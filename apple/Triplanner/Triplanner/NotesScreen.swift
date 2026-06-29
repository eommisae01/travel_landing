import SwiftUI

struct NotesScreen: View {
    @EnvironmentObject private var store: TripStore
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
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 238), spacing: 8)], spacing: 8) {
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
                    .appPanel(cornerRadius: 18)

                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader(title: store.currentCity.isEmpty ? "CURRENT CITY" : "\(displayCity(store.currentCity))", count: cityOnlyNotes.count)
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
                    .appPanel(cornerRadius: 18)

                    if !hiddenAllNotes.isEmpty {
                        DisclosureGroup(isExpanded: $showAllNotes) {
                            VStack(alignment: .leading, spacing: 10) {
                                noteGrid(hiddenAllNotes)
                            }
                            .padding(.top, 10)
                        } label: {
                            sectionHeader(title: "ALL NOTES", count: hiddenAllNotes.count)
                        }
                        .appPanel(cornerRadius: 18)
                    }
                }
                .readableWidth()
                .padding()
            }
            .navigationTitle("Notes")
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
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 136), spacing: 8)], spacing: 8) {
            NotesMetricCard(title: "현재 보기", value: "\(currentNoteCount)", unit: "개", iconName: "mappin.and.ellipse", tint: .teal)
            NotesMetricCard(title: "전체 자료", value: "\(store.notes.count)", unit: "개", iconName: "doc.text.image", tint: .blue)
            NotesMetricCard(title: "이미지 묶음", value: "\(store.notes.reduce(0) { $0 + $1.imageNames.count })", unit: "장", iconName: "photo.stack", tint: .purple)
        }
    }

    private var featuredNotesRail: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                SectionLabel(title: "QUICK BOARD")
                Spacer()
                Text(store.currentCity.isEmpty ? "현재 도시" : displayCity(store.currentCity))
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
            HStack(alignment: .top, spacing: 11) {
                notePreviewStrip(note)

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(note.title)
                            .font(.subheadline.weight(.black))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.secondary)
                    }

                    Text(note.body.isEmpty ? "메모 없음" : note.body)
                        .lineLimit(2)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        NoteKindPill(title: noteKindTitle(note), iconName: noteKindIcon(note), tint: noteAccent(note))
                        NoteKindPill(
                            title: note.imageNames.isEmpty ? "텍스트" : "\(note.imageNames.count)장",
                            iconName: note.imageNames.isEmpty ? "text.alignleft" : "photo.stack",
                            tint: .secondary
                        )
                        Spacer(minLength: 0)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
            .padding(9)
            .background(.background.opacity(0.62), in: RoundedRectangle(cornerRadius: 14))
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(noteAccent(note))
                    .frame(width: 4)
                    .padding(.vertical, 10)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.quaternary)
            }
        }
        .buttonStyle(.plain)
    }

    private func notePreviewStrip(_ note: NoteGroup) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13)
                .fill(
                    LinearGradient(
                        colors: note.imageNames.isEmpty
                            ? [Color.secondary.opacity(0.10), Color.secondary.opacity(0.05)]
                            : [noteAccent(note).opacity(0.24), Color.blue.opacity(0.12), Color.secondary.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if note.imageNames.isEmpty {
                Image(systemName: noteKindIcon(note))
                    .font(.title3.weight(.black))
                    .foregroundStyle(noteAccent(note))
                    .frame(width: 38, height: 38)
                    .background(.background.opacity(0.64), in: RoundedRectangle(cornerRadius: 12))
            } else {
                ZStack {
                    ForEach(Array(note.imageNames.prefix(3).enumerated()), id: \.offset) { index, imageName in
                        MiniImageBadge(title: imageName, index: index, tint: noteAccent(note))
                            .offset(x: CGFloat(index) * 8, y: CGFloat(index) * -7)
                    }
                }
                .offset(x: -8, y: 6)
            }
        }
        .frame(width: 66, height: 66)
        .overlay(alignment: .bottomTrailing) {
            if !note.imageNames.isEmpty {
                Text("\(note.imageNames.count)")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(noteAccent(note), in: Circle())
                    .padding(5)
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

    private func noteAccent(_ note: NoteGroup) -> Color {
        let value = (note.title + " " + note.body).lowercased()
        if value.contains("페리") || value.contains("버스") || value.contains("교통") { return .blue }
        if value.contains("예약") || value.contains("미술관") || value.contains("ticket") { return .purple }
        if value.contains("공항") || value.contains("atm") || value.contains("환전") { return .orange }
        if value.contains("식당") || value.contains("카페") { return .pink }
        return .teal
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

private struct FeaturedNoteTile: View {
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
                                accent.opacity(0.24),
                                Color.blue.opacity(0.12),
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
        .frame(width: 210, alignment: .topLeading)
        .frame(minHeight: 174, alignment: .topLeading)
        .padding(9)
        .background(.background.opacity(0.62), in: RoundedRectangle(cornerRadius: 17))
        .overlay {
            RoundedRectangle(cornerRadius: 17)
                .stroke(accent.opacity(0.12))
        }
    }
}

private struct NotesMetricCard: View {
    var title: String
    var value: String
    var unit: String
    var iconName: String
    var tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.bold))
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 9))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(value)
                        .font(.headline.weight(.black))
                    Text(unit)
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .padding(9)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 13))
        .overlay {
            RoundedRectangle(cornerRadius: 13)
                .stroke(.quaternary)
        }
    }
}

struct AddNoteSheet: View {
    @EnvironmentObject private var store: TripStore
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
    }

    private var parsedImages: [String] {
        imageText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

struct NoteDetailView: View {
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
                            .background(.teal.opacity(0.14), in: RoundedRectangle(cornerRadius: 13))
                            .foregroundStyle(.teal)

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
                                .foregroundStyle(.teal)
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
        .frame(width: 42, height: 34, alignment: .leading)
        .padding(.horizontal, 7)
        .background(.background.opacity(index == 0 ? 0.86 : 0.70), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.background, lineWidth: 2)
        }
    }
}

private struct NoteImageTile: View {
    var imageName: String
    var index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 13)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.teal.opacity(0.22),
                            Color.blue.opacity(0.14),
                            Color.secondary.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                Image(systemName: "photo")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.teal)
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
        .frame(maxWidth: .infinity, minHeight: 142, alignment: .topLeading)
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
                            .foregroundStyle(.teal)
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
                                            .foregroundStyle(itemIndex == index ? .white : .teal)
                                            .frame(width: 20, height: 20)
                                            .background(itemIndex == index ? Color.teal : Color.teal.opacity(0.12), in: Circle())
                                        Text(imageName)
                                            .font(.caption.weight(.black))
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 7)
                                    .background(itemIndex == index ? Color.teal.opacity(0.12) : Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
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
