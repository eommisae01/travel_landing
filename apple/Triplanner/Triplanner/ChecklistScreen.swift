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
                VStack(alignment: .leading, spacing: 36) {
                    ScreenHeader(title: "체크리스트", subtitle: "남은 준비 \(remainingCount)개 · 완료 \(doneCount)개")

                    VStack(alignment: .leading, spacing: 32) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(selectedOwner == "전체" ? "전체 준비" : selectedOwner)
                                    .font(.system(size: 48, weight: .black, design: .rounded))
                                    .foregroundStyle(.secondary)
                                Text("\(remainingCount)개 남음")
                                    .font(.system(size: 86, weight: .black, design: .rounded))
                            }
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 86, weight: .black, design: .rounded))
                                .foregroundStyle(progress >= 1 ? theme.accent : .primary)
                        }
                        ProgressView(value: progress)
                            .tint(theme.accent)
                            .scaleEffect(x: 1, y: 1.55, anchor: .center)

                        ownerFilterBar
                    }
                    .appPanel(cornerRadius: 24)

                    ChecklistSection(title: "남은 준비", subtitle: "\(remainingItems.count)개", items: remainingItems, tint: theme.accent) { item in
                        store.toggleChecklist(item)
                    }

                    if !completedItems.isEmpty {
                        ChecklistSection(title: "완료", subtitle: "\(completedItems.count)개", items: completedItems, tint: .secondary) { item in
                            store.toggleChecklist(item)
                        }
                    }
                }
                .readableWidth(1320)
                .padding(48)
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
            HStack(spacing: 12) {
                ForEach(filterOwners, id: \.self) { owner in
                    let summary = ownerSummary(for: owner)
                    let isSelected = selectedOwner == owner
                    Button {
                        selectedOwner = owner
                    } label: {
                        HStack(spacing: 8) {
                            if isSelected {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 9, height: 9)
                            }
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 32, weight: .black))
                            Text(owner)
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .lineLimit(1)
                            Text("\(summary.remaining)/\(summary.total)")
                                .font(.system(size: 36, weight: .black, design: .rounded).monospacedDigit())
                                .foregroundStyle(isSelected ? .white.opacity(0.82) : .secondary)
                        }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 21)
                        .background(isSelected ? theme.accent : Color.clear, in: Capsule())
                        .foregroundStyle(isSelected ? .white : .primary)
                        .overlay {
                            Capsule()
                                .stroke(isSelected ? theme.accent.opacity(0.34) : Color.secondary.opacity(0.13))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 1)
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
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(title)
                    .font(.system(size: 54, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                Text(subtitle)
                    .font(.system(size: 36, weight: .black, design: .rounded).monospacedDigit())
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
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
                .background(.background.opacity(0.87), in: RoundedRectangle(cornerRadius: 20))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.055))
                }
            }
        }
        .padding(.top, 2)
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
        HStack(alignment: .center, spacing: 18) {
            Button(action: action) {
                HStack(alignment: .center, spacing: 14) {
                    checkmarkIcon
                    titleLabel
                }
                .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight, alignment: .leading)
            .accessibilityLabel(item.isDone ? "완료 해제" : "완료")

            controlCluster
        }
        .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight, alignment: .center)
        .padding(.horizontal, 18)
        .padding(.vertical, 0)
        .background(rowBackground)
        .overlay(alignment: .bottom) {
            if showsDivider {
                Rectangle()
                    .fill(Color.secondary.opacity(0.11))
                    .frame(height: 0.5)
                    .padding(.leading, 72)
            }
        }
        .opacity(item.isDone ? 0.66 : 1)
        .sheet(isPresented: $isEditing) {
            ChecklistEditorSheet(existingItem: item)
                .environmentObject(store)
        }
    }

    private var rowHeight: CGFloat { 154 }

    private var checkmarkIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(item.isDone ? tint.opacity(0.14) : Color.secondary.opacity(0.045))
            RoundedRectangle(cornerRadius: 8)
                .stroke(item.isDone ? tint.opacity(0.42) : Color.secondary.opacity(0.16), lineWidth: 1)
            if item.isDone {
                Image(systemName: "checkmark")
                    .font(.system(size: 23, weight: .black))
                    .foregroundStyle(tint)
            }
        }
        .frame(width: 78, height: 78)
        .contentShape(RoundedRectangle(cornerRadius: 8))
    }

    private var titleLabel: some View {
        Text(item.title)
            .font(.system(size: 64, weight: .semibold, design: .rounded))
            .strikethrough(item.isDone)
            .foregroundStyle(item.isDone ? .secondary : .primary)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var ownerPill: some View {
        Text(item.owner)
            .font(.system(size: 37, weight: .black, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .frame(width: 194, height: 76)
            .background(ownerTint.opacity(0.11), in: Capsule())
            .foregroundStyle(ownerTint)
    }

    private var controlCluster: some View {
        HStack(spacing: 12) {
            ownerPill

            Button {
                isEditing = true
            } label: {
                editIcon
            }
            .buttonStyle(.plain)
            .accessibilityLabel("항목 수정")
        }
        .frame(width: 242, height: rowHeight, alignment: .center)
    }

    private var editIcon: some View {
        Image(systemName: "pencil")
            .font(.system(size: 31, weight: .black))
            .foregroundStyle(.secondary)
            .frame(width: 76, height: 76)
            .background(.secondary.opacity(0.070), in: RoundedRectangle(cornerRadius: 15))
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
