import SwiftUI

struct NotesScreen: View {
    @EnvironmentObject private var store: TripStore
    @State private var addSheetOpen = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.notes) { note in
                    NavigationLink {
                        NoteDetailView(note: note)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.title)
                                .font(.headline.weight(.black))
                            Text(note.body)
                                .lineLimit(2)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
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
