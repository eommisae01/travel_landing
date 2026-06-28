import SwiftUI

struct ChecklistScreen: View {
    @EnvironmentObject private var store: TripStore
    @State private var addSheetOpen = false

    private var remainingCount: Int {
        store.checklist.filter { !$0.isDone }.count
    }

    private var doneCount: Int {
        store.checklist.filter(\.isDone).count
    }

    private var progress: Double {
        guard !store.checklist.isEmpty else { return 0 }
        return Double(doneCount) / Double(store.checklist.count)
    }

    private var sortedItems: [ChecklistItem] {
        store.checklist.sorted { lhs, rhs in
            if lhs.isDone != rhs.isDone { return !lhs.isDone && rhs.isDone }
            if lhs.owner != rhs.owner { return lhs.owner < rhs.owner }
            return lhs.title < rhs.title
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ScreenHeader(title: "Checklist", subtitle: "남은 준비 \(remainingCount)개 · 완료 \(doneCount)개")

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("준비 진행률")
                                .font(.caption.weight(.black))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .font(.headline.weight(.black))
                        }
                        ProgressView(value: progress)
                    }
                    .appPanel()

                    SectionLabel(title: "ITEMS")
                    VStack(spacing: 6) {
                        ForEach(sortedItems) { item in
                            ChecklistItemRow(item: item) {
                                store.toggleChecklist(item)
                            }
                        }
                    }
                    .appPanel()
                }
                .readableWidth(860)
                .padding()
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

private struct ChecklistItemRow: View {
    var item: ChecklistItem
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(item.isDone ? .teal : .secondary)
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .strikethrough(item.isDone)
                    .foregroundStyle(item.isDone ? .secondary : .primary)
                Spacer()
                Text(item.owner)
                    .font(.caption.weight(.black))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.10), in: Capsule())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 34)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(item.isDone ? 0.58 : 1)
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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ScreenHeader(title: "준비 추가", subtitle: "담당자를 정해두면 가족별로 챙기기 쉽습니다.")

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "ITEM")
                        TextField("예: 항공권 확인", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }
                    .appPanel()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "OWNER")
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
                            ForEach(owners, id: \.self) { name in
                                Button {
                                    owner = name
                                } label: {
                                    Text(name)
                                        .font(.subheadline.weight(.black))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(owner == name ? Color.teal : Color.secondary.opacity(0.12), in: Capsule())
                                        .foregroundStyle(owner == name ? .white : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .appPanel()
                }
                .readableWidth(620)
                .padding()
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
