import SwiftUI

struct ChecklistScreen: View {
    @EnvironmentObject private var store: TripStore
    @State private var addSheetOpen = false

    private var sortedItems: [ChecklistItem] {
        store.checklist.sorted { lhs, rhs in
            if lhs.isDone != rhs.isDone { return !lhs.isDone && rhs.isDone }
            return lhs.title < rhs.title
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedItems) { item in
                    Button {
                        store.toggleChecklist(item)
                    } label: {
                        HStack {
                            Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.isDone ? .teal : .secondary)
                            Text(item.title)
                                .strikethrough(item.isDone)
                            Spacer()
                            Text(item.owner)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("체크리스트")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        addSheetOpen = true
                    } label: {
                        Label("추가", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $addSheetOpen) {
                AddChecklistSheet()
                    .environmentObject(store)
            }
        }
    }
}

struct AddChecklistSheet: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var owner = "공통"

    private var owners: [String] {
        ["공통"] + store.members.map(\.name)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("항목") {
                    TextField("예: 항공권 확인", text: $title)
                    Picker("담당", selection: $owner) {
                        ForEach(owners, id: \.self) { Text($0) }
                    }
                }
            }
            .navigationTitle("체크리스트 추가")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        store.addChecklist(title: title, owner: owner)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
