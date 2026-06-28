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

    private var remainingItems: [ChecklistItem] {
        sortedItems.filter { !$0.isDone }
    }

    private var completedItems: [ChecklistItem] {
        sortedItems.filter(\.isDone)
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

                    ChecklistSection(title: "남은 준비", subtitle: "\(remainingItems.count)개", items: remainingItems, tint: .teal) { item in
                        store.toggleChecklist(item)
                    }

                    if !completedItems.isEmpty {
                        ChecklistSection(title: "완료", subtitle: "\(completedItems.count)개", items: completedItems, tint: .secondary) { item in
                            store.toggleChecklist(item)
                        }
                    }
                }
                .readableWidth(900)
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
                ChecklistEditorSheet()
                    .environmentObject(store)
            }
        }
    }
}

private struct ChecklistSection: View {
    var title: String
    var subtitle: String
    var items: [ChecklistItem]
    var tint: Color
    var action: (ChecklistItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline.weight(.black))
                    Text(subtitle)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if items.isEmpty {
                EmptyStateView(
                    title: "항목 없음",
                    message: "새 준비 항목을 추가하면 여기서 바로 체크할 수 있습니다.",
                    iconName: "checklist"
                )
            } else {
                VStack(spacing: 4) {
                    ForEach(items) { item in
                        ChecklistItemRow(item: item, tint: tint) {
                            action(item)
                        }
                    }
                }
            }
        }
        .appPanel()
    }
}

private struct ChecklistItemRow: View {
    @EnvironmentObject private var store: TripStore
    var item: ChecklistItem
    var tint: Color = .teal
    var action: () -> Void
    @State private var isEditing = false

    var body: some View {
        HStack(spacing: 10) {
            Button(action: action) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(item.isDone ? tint : .secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)

            Button(action: action) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .strikethrough(item.isDone)
                    .foregroundStyle(item.isDone ? .secondary : .primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Text(item.owner)
                .font(.caption.weight(.black))
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(ownerTint.opacity(0.12), in: Capsule())
                .foregroundStyle(ownerTint)

            Button {
                isEditing = true
            } label: {
                Image(systemName: "pencil")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 42, alignment: .center)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.background.opacity(0.58), in: RoundedRectangle(cornerRadius: 11))
        .opacity(item.isDone ? 0.58 : 1)
        .sheet(isPresented: $isEditing) {
            ChecklistEditorSheet(existingItem: item)
                .environmentObject(store)
        }
    }

    private var ownerTint: Color {
        switch item.owner {
        case "공통": return .teal
        case "예지": return .pink
        case "승환": return .blue
        case "민지": return .orange
        default: return .secondary
        }
    }
}

struct ChecklistEditorSheet: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.dismiss) private var dismiss
    var existingItem: ChecklistItem?

    @State private var title = ""
    @State private var owner = "공통"

    private var owners: [String] {
        ["공통"] + store.members.map(\.name)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ScreenHeader(title: existingItem == nil ? "준비 추가" : "준비 수정", subtitle: "담당자를 정해두면 가족별로 챙기기 쉽습니다.")

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(title: "ITEM")
                        HStack(spacing: 10) {
                            Label("항목", systemImage: "checklist")
                                .font(.caption.weight(.black))
                                .foregroundStyle(.secondary)
                                .frame(width: 70, alignment: .leading)
                            TextField("예: 항공권 확인", text: $title)
                                .textFieldStyle(.roundedBorder)
                        }
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
                                        .font(.caption.weight(.black))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 9)
                                        .background(owner == name ? Color.teal : Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
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
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingItem == nil ? "추가" : "저장") {
                        if let existingItem {
                            store.updateChecklist(existingItem, title: title, owner: owner)
                        } else {
                            store.addChecklist(title: title, owner: owner)
                        }
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                guard let existingItem else { return }
                title = existingItem.title
                owner = existingItem.owner
            }
        }
    }
}
