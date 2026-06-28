import SwiftUI

struct BudgetScreen: View {
    @EnvironmentObject private var store: TripStore
    @State private var isAddingExpense = false

    private var total: Double {
        store.expenses.reduce(0) { $0 + $1.amount }
    }

    private var budget: Double {
        store.trip?.budgetAmount ?? 0
    }

    private var progress: Double {
        guard budget > 0 else { return 0 }
        return min(total / budget, 1)
    }

    private var remainingBudget: Double {
        max(budget - total, 0)
    }

    private var overBudget: Double {
        max(total - budget, 0)
    }

    private var balanceTitle: String {
        budget > 0 && total > budget ? "초과 금액" : "남은 금액"
    }

    private var balanceValue: String {
        guard budget > 0 else { return "-" }
        return "\(Int(total > budget ? overBudget : remainingBudget))"
    }

    private var categoryTotals: [(String, Double)] {
        Dictionary(grouping: store.expenses, by: \.category)
            .map { category, items in
                (category, items.reduce(0) { $0 + $1.amount })
            }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ScreenHeader(title: "Budget", subtitle: "여행 지출과 예상 부담을 한눈에 확인")

                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "creditcard.fill")
                                .font(.title3.weight(.black))
                                .foregroundStyle(.white)
                                .frame(width: 46, height: 46)
                                .background(spendingTint, in: RoundedRectangle(cornerRadius: 15))

                            VStack(alignment: .leading, spacing: 4) {
                                SectionLabel(title: "SPENT")
                                HStack(alignment: .firstTextBaseline, spacing: 5) {
                                    Text("\(Int(total))")
                                        .font(.system(size: 40, weight: .black, design: .rounded))
                                    Text(store.trip?.budgetCurrency ?? "JPY")
                                        .font(.headline.weight(.black))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(budget > 0 ? "\(Int(progress * 100))%" : "미정")
                                    .font(.title3.weight(.black))
                                    .foregroundStyle(spendingTint)
                                Text("사용률")
                                    .font(.caption2.weight(.black))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            ProgressView(value: progress)
                                .tint(spendingTint)
                            HStack {
                                Text("0")
                                Spacer()
                                Text(budget > 0 ? "\(Int(budget)) \(store.trip?.budgetCurrency ?? "JPY")" : "예산 미정")
                            }
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.secondary)
                        }

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 8)], spacing: 8) {
                            BudgetStat(title: "예산", value: budget > 0 ? "\(Int(budget))" : "미정", unit: store.trip?.budgetCurrency ?? "JPY")
                            BudgetStat(title: balanceTitle, value: balanceValue, unit: store.trip?.budgetCurrency ?? "JPY")
                            BudgetStat(title: "사용률", value: budget > 0 ? "\(Int(progress * 100))" : "-", unit: "%")
                        }
                    }
                    .appPanel(cornerRadius: 18)

                    if !categoryTotals.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel(title: "CATEGORY")
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 136), spacing: 8)], spacing: 8) {
                                ForEach(categoryTotals, id: \.0) { category, amount in
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(category)
                                            .font(.caption.weight(.black))
                                            .foregroundStyle(.secondary)
                                        Text("\(Int(amount))")
                                            .font(.headline.weight(.black))
                                        Text(store.trip?.budgetCurrency ?? "JPY")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(10)
                                    .background(.background.opacity(0.58), in: RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                        .appPanel(cornerRadius: 18)
                    }

                    SectionLabel(title: "EXPENSES")
                    if store.expenses.isEmpty {
                        EmptyStateView(
                            title: "지출이 비어있어요",
                            message: "항공권, 숙소, 식비처럼 함께 볼 비용을 추가하면 예산 진행률이 계산됩니다.",
                            iconName: "creditcard"
                        )
                    } else {
                        VStack(spacing: 8) {
                            ForEach(store.expenses) { expense in
                                ExpenseRow(expense: expense)
                            }
                        }
                        .appPanel(cornerRadius: 18)
                    }
                }
                .readableWidth(900)
                .padding()
            }
            .navigationTitle("예산")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isAddingExpense = true
                    } label: {
                        Label("지출 추가", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingExpense) {
                ExpenseEditorSheet()
                    .environmentObject(store)
            }
        }
        .appScreenBackground()
    }

    private var spendingTint: Color {
        if budget <= 0 { return .teal }
        if progress >= 0.9 { return .orange }
        return .teal
    }
}

private struct BudgetStat: View {
    var title: String
    var value: String
    var unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.headline.weight(.black))
                Text(unit)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.background.opacity(0.58), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct ExpenseRow: View {
    @EnvironmentObject private var store: TripStore
    var expense: ExpenseItem
    @State private var isEditing = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconName)
                .font(.headline.weight(.bold))
                .frame(width: 34, height: 34)
                .background(categoryColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 11))
                .foregroundStyle(categoryColor)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Text(expense.title)
                        .font(.subheadline.weight(.black))
                        .lineLimit(2)
                    Text(expense.category)
                        .font(.caption2.weight(.black))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(categoryColor.opacity(0.12), in: Capsule())
                        .foregroundStyle(categoryColor)
                }

                VStack(alignment: .leading, spacing: 5) {
                    ExpenseMetaLine(title: "결제", value: expense.paidBy, iconName: "creditcard", tint: .teal)
                    ExpenseMetaLine(title: "부담", value: expense.intendedPayer, iconName: "person.crop.circle.badge.checkmark", tint: .blue)
                    ExpenseMetaLine(title: "사용", value: participantText, iconName: "person.2", tint: .secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(expense.amount))")
                        .font(.headline.weight(.black))
                        .monospacedDigit()
                    Text(expense.currency)
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)
                }
                Button {
                    isEditing = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))
                }
                .buttonStyle(.plain)
            }
            .frame(minWidth: 66, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, minHeight: 86, alignment: .topLeading)
        .padding(11)
        .background(.background.opacity(0.62), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(categoryColor.opacity(0.12))
        }
        .sheet(isPresented: $isEditing) {
            ExpenseEditorSheet(existingExpense: expense)
                .environmentObject(store)
        }
    }

    private var iconName: String {
        switch expense.category {
        case "교통": return "tram.fill"
        case "입장권": return "ticket.fill"
        case "식비": return "fork.knife"
        default: return "creditcard.fill"
        }
    }

    private var categoryColor: Color {
        switch expense.category {
        case "교통": return .blue
        case "입장권": return .teal
        case "식비": return .orange
        case "숙소": return .purple
        case "쇼핑": return .pink
        default: return .secondary
        }
    }

    private var participantText: String {
        if expense.participants.isEmpty { return "전체" }
        return expense.participants.joined(separator: ", ")
    }
}

private struct ExpenseMetaLine: View {
    var title: String
    var value: String
    var iconName: String
    var tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: iconName)
                .font(.caption2.weight(.black))
                .frame(width: 14)
            Text(title)
                .font(.caption2.weight(.black))
                .foregroundStyle(.secondary)
            Text(value.isEmpty ? "미정" : value)
                .font(.caption2.weight(.black))
                .foregroundStyle(tint == .secondary ? .secondary : tint)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ExpenseEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: TripStore
    var existingExpense: ExpenseItem?

    @State private var category = "교통"
    @State private var title = ""
    @State private var amount = ""
    @State private var currency = "JPY"
    @State private var paidBy = ""
    @State private var intendedPayer = ""
    @State private var selectedParticipants: Set<String> = []

    private let categories = ["교통", "식비", "숙소", "입장권", "쇼핑", "기타"]

    private var memberNames: [String] {
        store.members.map(\.name)
    }

    private var parsedAmount: Double {
        Double(amount.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedAmount > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ScreenHeader(title: existingExpense == nil ? "지출 추가" : "지출 수정", subtitle: "결제자와 사용자를 함께 기록")

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "CATEGORY")
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 8)], spacing: 8) {
                            ForEach(categories, id: \.self) { item in
                                Button {
                                    category = item
                                } label: {
                                    Text(item)
                                        .font(.caption.weight(.black))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 9)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(category == item ? .white : .primary)
                                .background(category == item ? .teal : .secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .appPanel(cornerRadius: 18)

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(title: "DETAIL")
                        LabeledExpenseField(title: "항목", iconName: "text.badge.plus", placeholder: "항목명", text: $title)
                        HStack(spacing: 10) {
                            LabeledExpenseField(title: "금액", iconName: "yensign", placeholder: "금액", text: $amount)
                            TextField("통화", text: $currency)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 96)
                        }
                    }
                    .appPanel(cornerRadius: 18)

                    if !memberNames.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            PersonChipSection(title: "PAID BY", names: memberNames, selection: $paidBy)
                            Divider()
                            PersonChipSection(title: "WILL PAY", names: memberNames, selection: $intendedPayer)
                            Divider()
                            ParticipantChipSection(title: "USED BY", names: memberNames, selection: $selectedParticipants)
                        }
                        .appPanel(cornerRadius: 18)
                    }
                }
                .readableWidth(620)
                .padding()
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingExpense == nil ? "저장" : "수정") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                syncInitialValues()
            }
        }
    }

    private func save() {
        let participants = memberNames.filter { selectedParticipants.contains($0) }
        if let existingExpense {
            store.updateExpense(
                existingExpense,
                category: category,
                title: title,
                amount: parsedAmount,
                currency: currency,
                paidBy: paidBy,
                intendedPayer: intendedPayer,
                participants: participants
            )
        } else {
            store.addExpense(
                category: category,
                title: title,
                amount: parsedAmount,
                currency: currency,
                paidBy: paidBy,
                intendedPayer: intendedPayer,
                participants: participants
            )
        }
        dismiss()
    }

    private func syncInitialValues() {
        if let existingExpense {
            category = existingExpense.category
            title = existingExpense.title
            amount = "\(Int(existingExpense.amount))"
            currency = existingExpense.currency
            paidBy = existingExpense.paidBy
            intendedPayer = existingExpense.intendedPayer
            selectedParticipants = Set(existingExpense.participants)
            return
        }
        if currency.isEmpty {
            currency = store.trip?.budgetCurrency ?? "JPY"
        }
        if paidBy.isEmpty {
            paidBy = memberNames.first ?? ""
        }
        if intendedPayer.isEmpty {
            intendedPayer = memberNames.first ?? ""
        }
        if selectedParticipants.isEmpty {
            selectedParticipants = Set(memberNames)
        }
    }
}

private struct LabeledExpenseField: View {
    var title: String
    var iconName: String
    var placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.teal)
                .frame(width: 32, height: 32)
                .background(.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            TextField(placeholder, text: $text)
                #if os(iOS)
                .keyboardType(title == "금액" ? .decimalPad : .default)
                #endif
                .textFieldStyle(.roundedBorder)
        }
    }
}

private struct PersonChipSection: View {
    var title: String
    var names: [String]
    @Binding var selection: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(title: title)
            FlowChips(names: names, selected: { selection == $0 }) { name in
                selection = name
            }
        }
    }
}

private struct ParticipantChipSection: View {
    var title: String
    var names: [String]
    @Binding var selection: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(title: title)
            FlowChips(names: names, selected: { selection.contains($0) }) { name in
                if selection.contains(name) {
                    selection.remove(name)
                } else {
                    selection.insert(name)
                }
            }
        }
    }
}

private struct FlowChips: View {
    var names: [String]
    var selected: (String) -> Bool
    var onTap: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
            ForEach(names, id: \.self) { name in
                Button {
                    onTap(name)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: selected(name) ? "checkmark.circle.fill" : "circle")
                            .font(.caption.weight(.bold))
                        Text(name)
                            .font(.caption.weight(.black))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                }
                .buttonStyle(.plain)
                .foregroundStyle(selected(name) ? .white : .primary)
                .background(selected(name) ? .teal : .secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
