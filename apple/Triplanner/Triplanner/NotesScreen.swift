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

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(title: store.currentCity.isEmpty ? "CURRENT CITY" : "\(displayCity(store.currentCity))")
                        if selectedCityNotes.isEmpty {
                            Text("선택한 도시와 연결된 자료가 아직 없습니다.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 80)
                                .background(.background.opacity(0.52), in: RoundedRectangle(cornerRadius: 12))
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
                                ForEach(selectedCityNotes) { note in
                                    noteCard(note)
                                }
                            }
                        }
                    }
                    .appPanel()

                    if !otherNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel(title: "ALL NOTES")
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
                                ForEach(otherNotes) { note in
                                    noteCard(note)
                                }
                            }
                        }
                        .appPanel()
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

    private func noteCard(_ note: NoteGroup) -> some View {
        NavigationLink {
            NoteDetailView(note: note)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "doc.text.image")
                        .font(.headline.weight(.bold))
                        .frame(width: 34, height: 34)
                        .background(.teal.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.teal)
                    Spacer()
                    if !note.imageNames.isEmpty {
                        Label("\(note.imageNames.count)", systemImage: "photo")
                            .font(.caption2.weight(.black))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(.secondary.opacity(0.10), in: Capsule())
                    }
                }
                Text(note.title)
                    .font(.headline.weight(.black))
                Text(note.body)
                    .lineLimit(3)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text("열기")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.teal)
            }
            .frame(maxWidth: .infinity, minHeight: 142, alignment: .topLeading)
            .padding(12)
            .background(.background.opacity(0.62), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.quaternary)
            }
        }
        .buttonStyle(.plain)
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

struct AddNoteSheet: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""

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
                }
                .readableWidth(680)
                .padding()
            }
            .navigationTitle("Note 추가")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        store.addNote(title: title, body: bodyText)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct NoteDetailView: View {
    var note: NoteGroup

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenHeader(title: note.title, subtitle: "자료 상세")

                Text(note.body)
                    .font(.body)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

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
                        HStack {
                            ForEach(note.imageNames, id: \.self) { imageName in
                                Image(imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 260, height: 220)
                                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
                            }
                        }
                    }
                }
            }
            .readableWidth()
            .padding()
        }
        .navigationTitle("")
    }
}
