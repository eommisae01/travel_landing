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
                            if isSelected {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 6, height: 6)
                            }
                            Image(systemName: "person.crop.circle")
                                .font(.caption2.weight(.black))
                            Text(owner)
                                .font(.caption.weight(.black))
                                .lineLimit(1)
                            Text("\(summary.remaining)/\(summary.total)")
                                .font(.caption2.weight(.black).monospacedDigit())
                                .foregroundStyle(isSelected ? .white.opacity(0.82) : .secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
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
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                SectionLabel(title: title)
                Spacer()
                Text(subtitle)
                    .font(.caption2.weight(.black))
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
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 13))
                .clipShape(RoundedRectangle(cornerRadius: 13))
                .overlay {
                    RoundedRectangle(cornerRadius: 13)
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
        HStack(spacing: 9) {
            Button(action: action) {
                checkmarkIcon
            }
            .buttonStyle(.plain)
            .frame(width: 32, height: rowHeight)
            .accessibilityLabel(item.isDone ? "완료 해제" : "완료")

            Button(action: action) {
                titleLabel
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight, alignment: .leading)

            HStack(spacing: 6) {
                ownerPill

                Button {
                    isEditing = true
                } label: {
                    editIcon
                }
                .buttonStyle(.plain)
                .accessibilityLabel("항목 수정")
            }
            .frame(height: rowHeight, alignment: .center)
        }
        .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight, alignment: .center)
        .padding(.horizontal, 10)
        .padding(.vertical, 0)
        .background(rowBackground)
        .overlay(alignment: .bottom) {
            if showsDivider {
                Rectangle()
                    .fill(Color.secondary.opacity(0.11))
                    .frame(height: 0.5)
                    .padding(.leading, 51)
            }
        }
        .opacity(item.isDone ? 0.66 : 1)
        .sheet(isPresented: $isEditing) {
            ChecklistEditorSheet(existingItem: item)
                .environmentObject(store)
        }
    }

    private var rowHeight: CGFloat { 40 }

    private var checkmarkIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(item.isDone ? tint.opacity(0.15) : Color.secondary.opacity(0.08))
            RoundedRectangle(cornerRadius: 8)
                .stroke(item.isDone ? tint.opacity(0.42) : Color.secondary.opacity(0.16), lineWidth: 1)
            Image(systemName: item.isDone ? "checkmark" : "circle.fill")
                .font(.system(size: item.isDone ? 11 : 6, weight: .black))
                .foregroundStyle(item.isDone ? tint : .secondary)
        }
        .frame(width: 26, height: 26)
        .contentShape(RoundedRectangle(cornerRadius: 8))
    }

    private var titleLabel: some View {
        Text(item.title)
            .font(.subheadline.weight(.semibold))
            .strikethrough(item.isDone)
            .foregroundStyle(item.isDone ? .secondary : .primary)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight, alignment: .leading)
            .contentShape(Rectangle())
    }

    private var ownerPill: some View {
        Text(item.owner)
            .font(.caption2.weight(.black))
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .frame(width: 54, height: 24)
            .background(ownerTint.opacity(0.11), in: Capsule())
            .foregroundStyle(ownerTint)
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
