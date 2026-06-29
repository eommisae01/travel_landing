import SwiftUI

struct ChecklistScreen: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.appTheme) private var theme
    @State private var addSheetOpen = false
    @State private var selectedOwner = "전체"

    private var remainingCount: Int {
        filteredItems.filter { !$0.isDone }.count
    }

    private var doneCount: Int {
        filteredItems.filter(\.isDone).count
    }

    private var progress: Double {
        guard !filteredItems.isEmpty else { return 0 }
        return Double(doneCount) / Double(filteredItems.count)
    }

    private var filterOwners: [String] {
        let knownOwners = ["공통"] + store.members.map(\.name)
        let extraOwners = Set(store.checklist.map(\.owner))
            .subtracting(knownOwners)
            .sorted()
        return ["전체"] + (knownOwners + extraOwners).filter { owner in
            store.checklist.contains { $0.owner == owner }
        }
    }

    private var filteredItems: [ChecklistItem] {
        guard selectedOwner != "전체" else { return store.checklist }
        return store.checklist.filter { $0.owner == selectedOwner }
    }

    private var sortedItems: [ChecklistItem] {
        filteredItems.sorted { lhs, rhs in
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
                    ScreenHeader(title: "체크리스트", subtitle: "남은 준비 \(remainingCount)개 · 완료 \(doneCount)개")

                    VStack(alignment: .leading, spacing: 10) {
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
                                .foregroundStyle(progress >= 1 ? theme.accent : .primary)
                        }
                        ProgressView(value: progress)
                            .tint(theme.accent)

                        ownerFilterBar
                    }
                    .appPanel(cornerRadius: 18)

                    ChecklistSection(title: "남은 준비", subtitle: "\(remainingItems.count)개", items: remainingItems, tint: theme.accent) { item in
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
            .navigationTitle("")
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

    private var ownerFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(filterOwners, id: \.self) { owner in
                    let summary = ownerSummary(for: owner)
                    let isSelected = selectedOwner == owner
                    Button {
                        selectedOwner = owner
                    } label: {
                        HStack(spacing: 7) {
                            Text(owner)
                                .font(.caption.weight(.black))
                                .lineLimit(1)
                            Text("\(summary.remaining)/\(summary.total)")
                                .font(.caption2.weight(.black).monospacedDigit())
                                .foregroundStyle(isSelected ? .white.opacity(0.82) : .secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(isSelected ? theme.accent : Color.secondary.opacity(0.10), in: Capsule())
                        .foregroundStyle(isSelected ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func ownerSummary(for owner: String) -> (remaining: Int, total: Int) {
        let items = owner == "전체" ? store.checklist : store.checklist.filter { $0.owner == owner }
        return (items.filter { !$0.isDone }.count, items.count)
    }
}

private struct ChecklistSection: View {
    var title: String
    var subtitle: String
    var items: [ChecklistItem]
    var tint: Color
    var action: (ChecklistItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
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
                .background(.background.opacity(0.46), in: RoundedRectangle(cornerRadius: 14))
                .clipShape(RoundedRectangle(cornerRadius: 14))
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
    @Environment(\.appTheme) private var theme
    var item: ChecklistItem
    var tint: Color = .teal
    var showsDivider = false
    var action: () -> Void
    @State private var isEditing = false

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Button(action: action) {
                checkmarkIcon
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isDone ? "완료 해제" : "완료")

            Button(action: action) {
                titleLabel
            }
            .buttonStyle(.plain)

            Text(item.owner)
                .font(.caption2.weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(width: 56, height: 26)
                .background(ownerTint.opacity(0.11), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(ownerTint)

            Button {
                isEditing = true
            } label: {
                editIcon
            }
            .buttonStyle(.plain)
            .accessibilityLabel("항목 수정")
        }
        .frame(maxWidth: .infinity, minHeight: 38, alignment: .center)
        .padding(.horizontal, 9)
        .padding(.vertical, 3)
        .background(rowBackground)
        .overlay(alignment: .bottom) {
            if showsDivider {
                Rectangle()
                    .fill(Color.secondary.opacity(0.11))
                    .frame(height: 0.5)
                    .padding(.leading, 42)
            }
        }
        .opacity(item.isDone ? 0.66 : 1)
        .sheet(isPresented: $isEditing) {
            ChecklistEditorSheet(existingItem: item)
                .environmentObject(store)
        }
    }

    private var checkmarkIcon: some View {
        Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(item.isDone ? tint : .secondary)
            .frame(width: 28, height: 28)
            .contentShape(Circle())
    }

    private var titleLabel: some View {
        Text(item.title)
            .font(.subheadline.weight(.semibold))
            .strikethrough(item.isDone)
            .foregroundStyle(item.isDone ? .secondary : .primary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
            .contentShape(Rectangle())
    }

    private var editIcon: some View {
        Image(systemName: "pencil")
            .font(.caption2.weight(.black))
            .foregroundStyle(.secondary)
            .frame(width: 28, height: 28)
            .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    private var ownerTint: Color {
        switch item.owner {
        case "공통": return theme.accent
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

struct ChecklistEditorSheet: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.appTheme) private var theme
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
                                .foregroundStyle(theme.accent)
                                .frame(width: 34, height: 34)
                                .background(theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
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
                                        .background(owner == name ? theme.accent : Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
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
