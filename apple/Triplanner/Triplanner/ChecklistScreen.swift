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

    private var ownerSummaries: [(name: String, remaining: Int, total: Int)] {
        let knownOwners = ["공통"] + store.members.map(\.name)
        let extraOwners = Set(store.checklist.map(\.owner))
            .subtracting(knownOwners)
            .sorted()
        let owners = (knownOwners + extraOwners).filter { owner in
            store.checklist.contains { $0.owner == owner }
        }
        return owners.map { owner in
            let ownerItems = store.checklist.filter { $0.owner == owner }
            return (
                name: owner,
                remaining: ownerItems.filter { !$0.isDone }.count,
                total: ownerItems.count
            )
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ScreenHeader(title: "Checklist", subtitle: "남은 준비 \(remainingCount)개 · 완료 \(doneCount)개")

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("READY")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(.secondary)
                                Text("\(remainingCount)개 남음")
                                    .font(.title3.weight(.black))
                            }
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .font(.title2.weight(.black))
                                .foregroundStyle(progress >= 1 ? .teal : .primary)
                        }
                        ProgressView(value: progress)
                            .tint(.teal)

                        if !ownerSummaries.isEmpty {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], spacing: 8) {
                                ForEach(ownerSummaries, id: \.name) { summary in
                                    OwnerProgressChip(
                                        name: summary.name,
                                        remaining: summary.remaining,
                                        total: summary.total
                                    )
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                    .appPanel(cornerRadius: 18)

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
        .appScreenBackground()
    }
}

private struct ChecklistSection: View {
    var title: String
    var subtitle: String
    var items: [ChecklistItem]
    var tint: Color
    var action: (ChecklistItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.black))
                Spacer()
                Text(subtitle)
                    .font(.caption.weight(.black))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tint.opacity(0.12), in: Capsule())
                    .foregroundStyle(tint)
            }

            if items.isEmpty {
                EmptyStateView(
                    title: "항목 없음",
                    message: "새 준비 항목을 추가하면 여기서 바로 체크할 수 있습니다.",
                    iconName: "checklist"
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        ChecklistItemRow(item: item, tint: tint, showsDivider: index < items.count - 1) {
                            action(item)
                        }
                    }
                }
                .background(.background.opacity(0.50), in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.quaternary)
                }
            }
        }
        .appPanel(cornerRadius: 18)
    }
}

private struct ChecklistItemRow: View {
    @EnvironmentObject private var store: TripStore
    var item: ChecklistItem
    var tint: Color = .teal
    var showsDivider = false
    var action: () -> Void
    @State private var isEditing = false

    var body: some View {
        HStack(alignment: .center, spacing: 9) {
            Button(action: action) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(item.isDone ? tint : .secondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: action) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .strikethrough(item.isDone)
                    .foregroundStyle(item.isDone ? .secondary : .primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(alignment: .center, spacing: 6) {
                Text(item.owner)
                    .font(.caption2.weight(.black))
                    .lineLimit(1)
                    .frame(minWidth: 38)
                    .padding(.horizontal, 6)
                    .frame(height: 26)
                    .background(ownerTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
                    .foregroundStyle(ownerTint)

                Button {
                    isEditing = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 7))
                }
                .buttonStyle(.plain)
            }
            .frame(height: 30)
        }
        .frame(maxWidth: .infinity, minHeight: 38, alignment: .center)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(rowBackground)
        .overlay(alignment: .bottom) {
            if showsDivider {
                Rectangle()
                    .fill(Color.secondary.opacity(0.13))
                    .frame(height: 0.5)
                    .padding(.leading, 47)
            }
        }
        .opacity(item.isDone ? 0.66 : 1)
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

    private var rowBackground: Color {
        item.isDone ? Color.secondary.opacity(0.035) : Color.clear
    }
}

private struct OwnerProgressChip: View {
    var name: String
    var remaining: Int
    var total: Int

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(tint.opacity(0.22))
                .frame(width: 9, height: 9)
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text("\(remaining)/\(total)")
                    .font(.caption.weight(.black))
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
    }

    private var tint: Color {
        switch name {
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
                            Image(systemName: "checklist")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.teal)
                                .frame(width: 34, height: 34)
                                .background(.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
                            TextField("예: 항공권 확인", text: $title)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .appPanel(cornerRadius: 18)

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
                    .appPanel(cornerRadius: 18)
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
