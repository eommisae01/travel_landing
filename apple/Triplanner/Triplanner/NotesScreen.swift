import SwiftUI

struct NotesScreen: View {
    @EnvironmentObject private var store: TripStore
    @State private var addSheetOpen = false

    private var selectedCityNotes: [NoteGroup] {
        store.notesForSelectedCity()
    }

    private var otherNotes: [NoteGroup] {
        store.notes.filter { note in
            !selectedCityNotes.contains(note)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ScreenHeader(title: "Notes", subtitle: "시간표, 예약, 현장 정보를 묶어두는 자료 보드")

                    notesOverview

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(title: store.currentCity.isEmpty ? "CURRENT CITY" : "\(displayCity(store.currentCity))")
                        if selectedCityNotes.isEmpty {
                            EmptyStateView(
                                title: "자료가 비어있어요",
                                message: "시간표, 예약 캡처, 현장 메모를 도시별 보드로 모아둘 수 있습니다.",
                                iconName: "doc.text.image"
                            )
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
                                ForEach(selectedCityNotes) { note in
                                    noteCard(note)
                                }
                            }
                        }
                    }
                    .appPanel(cornerRadius: 18)

                    if !otherNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel(title: "ALL NOTES")
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
                                ForEach(otherNotes) { note in
                                    noteCard(note)
                                }
                            }
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
    }

    private var notesOverview: some View {
        HStack(spacing: 10) {
            NotesMetricCard(title: "현재 도시", value: "\(selectedCityNotes.count)", unit: "개", iconName: "mappin.and.ellipse", tint: .teal)
            NotesMetricCard(title: "전체 자료", value: "\(store.notes.count)", unit: "개", iconName: "doc.text.image", tint: .blue)
            NotesMetricCard(title: "이미지 묶음", value: "\(store.notes.reduce(0) { $0 + $1.imageNames.count })", unit: "장", iconName: "photo.stack", tint: .purple)
        }
    }

    private func noteCard(_ note: NoteGroup) -> some View {
        NavigationLink {
            NoteDetailView(note: note)
        } label: {
            VStack(alignment: .leading, spacing: 11) {
                notePreviewStrip(note)

                Text(note.title)
                    .font(.headline.weight(.black))
                    .lineLimit(1)
                Text(note.body)
                    .lineLimit(3)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
                HStack {
                    Label(note.imageNames.isEmpty ? "텍스트" : "\(note.imageNames.count)장", systemImage: note.imageNames.isEmpty ? "text.alignleft" : "photo")
                        .font(.caption2.weight(.black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.secondary.opacity(0.10), in: Capsule())
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 172, alignment: .topLeading)
            .padding(12)
            .background(.background.opacity(0.70), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.quaternary)
            }
        }
        .buttonStyle(.plain)
    }

    private func notePreviewStrip(_ note: NoteGroup) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: note.imageNames.isEmpty
                            ? [Color.secondary.opacity(0.10), Color.secondary.opacity(0.05)]
                            : [Color.teal.opacity(0.22), Color.blue.opacity(0.13), Color.purple.opacity(0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            HStack(spacing: -8) {
                if note.imageNames.isEmpty {
                    Image(systemName: "doc.text")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 42, height: 42)
                        .background(.background.opacity(0.62), in: RoundedRectangle(cornerRadius: 12))
                } else {
                    ForEach(Array(note.imageNames.prefix(4).enumerated()), id: \.offset) { index, imageName in
                        MiniImageBadge(title: imageName, index: index)
                    }
                }
                Spacer()
            }
            .padding(12)
        }
        .frame(height: 68)
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

private struct NotesMetricCard: View {
    var title: String
    var value: String
    var unit: String
    var iconName: String
    var tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.headline.weight(.bold))
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
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
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .padding(11)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
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
                    ScreenHeader(title: "Note 추가", subtitle: "시간표, 예약, 현장 정보를 한 묶음으로 저장합니다.")

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "TITLE")
                        TextField("예: 페리 시간표", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }
                    .appPanel()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "BODY")
                        TextField("메모", text: $bodyText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(5...12)
                    }
                    .appPanel()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "IMAGE BUNDLE")
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "doc.text.image")
                            .font(.title3.weight(.black))
                            .frame(width: 44, height: 44)
                            .background(.teal.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.teal)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.title)
                                .font(.system(size: 28, weight: .black, design: .rounded))
                            Text(note.imageNames.isEmpty ? "텍스트 자료" : "\(note.imageNames.count)장의 자료 묶음")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                }
                .appPanel(cornerRadius: 18)

                Text(note.body)
                    .font(.body)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))

                SectionLabel(title: "IMAGE BUNDLE")

                if note.imageNames.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.largeTitle)
                            .foregroundStyle(.teal)
                        Text("페리 시간표, 예약 캡처, 현장 사진을 여러 장 묶어서 넘겨볼 수 있게 만들 예정입니다.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(note.imageNames.enumerated()), id: \.offset) { index, imageName in
                                Button {
                                    selectedImageIndex = index
                                } label: {
                                    NoteImageTile(imageName: imageName, index: index)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
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

    var body: some View {
        Text(String(title.prefix(1)))
            .font(.caption2.weight(.black))
            .foregroundStyle(.teal)
            .frame(width: 34, height: 34)
            .background(.background.opacity(index == 0 ? 0.84 : 0.68), in: RoundedRectangle(cornerRadius: 11))
            .overlay {
                RoundedRectangle(cornerRadius: 11)
                    .stroke(.background, lineWidth: 2)
            }
    }
}

private struct NoteImageTile: View {
    var imageName: String
    var index: Int

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 18)
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
                .overlay(alignment: .topTrailing) {
                    Text(String(format: "%02d", index + 1))
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)
                        .padding(10)
                }

            VStack(alignment: .leading, spacing: 9) {
                Image(systemName: "photo")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.teal)
                Text(imageName)
                    .font(.headline.weight(.black))
                    .lineLimit(2)
                Text("탭해서 크게 보기")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .frame(width: 250, height: 210)
        .overlay {
            RoundedRectangle(cornerRadius: 18)
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
            ZStack {
                LinearGradient(
                    colors: [Color.teal.opacity(0.20), Color.blue.opacity(0.10), Color.secondary.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    Text("\(index + 1) / \(note.imageNames.count)")
                        .font(.caption.weight(.black))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.background.opacity(0.60), in: Capsule())
                        .foregroundStyle(.secondary)
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 58, weight: .bold))
                        .foregroundStyle(.teal)
                    Text(currentImageName)
                        .font(.title.weight(.black))
                        .multilineTextAlignment(.center)
                    Text("나중에 실제 사진 파일을 연결하면 이 자리에서 크게 확인합니다.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 10) {
                        Button {
                            index = max(index - 1, 0)
                        } label: {
                            Label("이전", systemImage: "chevron.left")
                                .frame(width: 112)
                        }
                        .buttonStyle(.bordered)
                        .disabled(index == 0)

                        Button {
                            index = min(index + 1, max(note.imageNames.count - 1, 0))
                        } label: {
                            Label("다음", systemImage: "chevron.right")
                                .frame(width: 112)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(index >= note.imageNames.count - 1)
                    }
                }
                .padding()
            }
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
