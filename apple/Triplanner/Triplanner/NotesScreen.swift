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

                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(title: store.currentCity.isEmpty ? "CURRENT CITY" : "\(displayCity(store.currentCity))")
                        if selectedCityNotes.isEmpty {
                            Text("선택한 도시와 연결된 자료가 아직 없습니다.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 80)
                        }
                        ForEach(selectedCityNotes) { note in
                            noteLink(note)
                        }
                    }
                    .appPanel()

                    if !otherNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionLabel(title: "ALL NOTES")
                            ForEach(otherNotes) { note in
                                noteLink(note)
                            }
                        }
                        .appPanel()
                    }
                }
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

    private func noteLink(_ note: NoteGroup) -> some View {
        NavigationLink {
            NoteDetailView(note: note)
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                Text(note.title)
                    .font(.headline.weight(.black))
                Text(note.body)
                    .lineLimit(2)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(.background.opacity(0.62), in: RoundedRectangle(cornerRadius: 12))
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
            Form {
                Section("Notes") {
                    TextField("제목", text: $title)
                    TextField("메모", text: $bodyText, axis: .vertical)
                        .lineLimit(5...12)
                }
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
                Text(note.body)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.background, in: RoundedRectangle(cornerRadius: 18))

                Text("사진 묶음")
                    .font(.headline.weight(.black))

                if note.imageNames.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.largeTitle)
                            .foregroundStyle(.teal)
                        Text("여기에 페리시간표처럼 여러 장을 한 묶음으로 넣을 예정")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
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
            .padding()
        }
        .navigationTitle(note.title)
    }
}
