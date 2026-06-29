import SwiftUI

struct BudgetScreen: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.appTheme) private var theme
    @State private var isAddingExpense = false
    @State private var isEditingBudget = false

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
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "creditcard.fill")
                                .font(.title3.weight(.black))
                                .foregroundStyle(.white)
                                .frame(width: 46, height: 46)
                                .background(spendingTint, in: RoundedRectangle(cornerRadius: 15))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("현재 지출")
                                    .font(.headline.weight(.black))
                                    .lineLimit(1)
                                Text(budget > 0 ? "사용률과 남은 금액을 바로 확인" : "Budget을 설정하면 진행률이 계산됩니다")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.78)
                                HStack(alignment: .firstTextBaseline, spacing: 5) {
                                    Text("\(Int(total))")
                                        .font(.system(size: 40, weight: .black, design: .rounded))
                                    Text(store.trip?.budgetCurrency ?? "JPY")
                                        .font(.headline.weight(.black))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 8) {
                                Text(budget > 0 ? "\(Int(progress * 100))%" : "미정")
                                    .font(.title3.weight(.black))
                                    .foregroundStyle(spendingTint)
                                Text("사용률")
                                    .font(.caption2.weight(.black))
                                    .foregroundStyle(.secondary)
                                Button {
                                    isEditingBudget = true
                                } label: {
                                    Label(budget > 0 ? "수정" : "설정", systemImage: "slider.horizontal.3")
                                        .font(.caption.weight(.black))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(spendingTint)
                                .background(spendingTint.opacity(0.12), in: Capsule())
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            ProgressView(value: progress)
                                .tint(spendingTint)
                            HStack {
                                Text("0")
                                Spacer()
                                Text(budget > 0 ? "\(Int(budget)) \(store.trip?.budgetCurrency ?? "JPY")" : "Budget 미정")
                            }
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.secondary)
                        }

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 8)], spacing: 8) {
                            BudgetStat(title: "설정 금액", value: budget > 0 ? "\(Int(budget))" : "미정", unit: store.trip?.budgetCurrency ?? "JPY")
                            BudgetStat(title: balanceTitle, value: balanceValue, unit: store.trip?.budgetCurrency ?? "JPY")
                            BudgetStat(title: "사용률", value: budget > 0 ? "\(Int(progress * 100))" : "-", unit: "%")
                        }
                    }
                    .appPanel(cornerRadius: 18)

                    if !categoryTotals.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel(title: "CATEGORY")
                            VStack(spacing: 8) {
                                ForEach(categoryTotals, id: \.0) { category, amount in
                                    CategoryBudgetRow(
                                        category: category,
                                        amount: amount,
                                        total: total,
                                        currency: store.trip?.budgetCurrency ?? "JPY"
                                    )
                                }
                            }
                        }
                        .appPanel(cornerRadius: 18)
                    }

                    SectionLabel(title: "EXPENSES")
                    if store.expenses.isEmpty {
                        EmptyStateView(
                            title: "지출이 비어있어요",
                            message: "항공권, 숙소, 식비처럼 함께 볼 비용을 추가하면 Budget 진행률이 계산됩니다.",
                            iconName: "creditcard"
                        )
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(store.expenses.enumerated()), id: \.element.id) { index, expense in
                                ExpenseRow(expense: expense, showsDivider: index < store.expenses.count - 1)
                            }
                        }
                        .appPanel(cornerRadius: 18)
                    }
                }
                .readableWidth(900)
                .padding()
            }
            .navigationTitle("Budget")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        isEditingBudget = true
                    } label: {
                        Label("Budget 설정", systemImage: "slider.horizontal.3")
                    }
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
            .sheet(isPresented: $isEditingBudget) {
                BudgetLimitSheet()
                    .environmentObject(store)
            }
        }
        .appScreenBackground()
    }

    private var spendingTint: Color {
        if budget <= 0 { return theme.accent }
        if progress >= 0.9 { return .orange }
        return theme.accent
    }
}

private struct BudgetLimitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: TripStore
    @State private var amount = ""
    @State private var currency = "JPY"

    private var parsedAmount: Double {
        Double(amount.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ScreenHeader(title: "Budget 설정", subtitle: "이번 여행에서 함께 확인할 총 한도")

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(title: "BUDGET")
                        HStack(spacing: 10) {
                            TextField("예: 150000", text: $amount)
                                .textFieldStyle(.roundedBorder)
                            TextField("JPY", text: $currency)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 92)
                        }
                        Text("0으로 저장하면 Budget 화면에는 Budget 미정으로 표시됩니다.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .appPanel(cornerRadius: 18)
                }
                .readableWidth(520)
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
                    Button("저장") {
                        store.updateBudget(amount: parsedAmount, currency: currency)
                        dismiss()
                    }
                }
            }
            .onAppear {
                let currentAmount = store.trip?.budgetAmount ?? 0
                amount = currentAmount > 0 ? "\(Int(currentAmount))" : ""
                currency = store.trip?.budgetCurrency ?? "JPY"
            }
        }
        .appScreenBackground()
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

private struct CategoryBudgetRow: View {
    @Environment(\.appTheme) private var theme
    var category: String
    var amount: Double
    var total: Double
    var currency: String

    private var ratio: Double {
        guard total > 0 else { return 0 }
        return min(amount / total, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Label(category, systemImage: iconName)
                    .font(.caption.weight(.black))
                    .foregroundStyle(tint)
                Spacer()
                Text("\(Int(amount)) \(currency)")
                    .font(.caption.weight(.black))
                    .monospacedDigit()
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.10))
                    Capsule()
                        .fill(tint.opacity(0.78))
                        .frame(width: max(8, proxy.size.width * ratio))
                }
            }
            .frame(height: 7)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(.background.opacity(0.58), in: RoundedRectangle(cornerRadius: 12))
    }

    private var tint: Color {
        switch category {
        case "교통": return .blue
        case "입장권": return theme.accent
        case "식비": return .orange
        case "숙소": return theme.secondaryAccent
        case "쇼핑": return .pink
        default: return .secondary
        }
    }

    private var iconName: String {
        switch category {
        case "교통": return "tram.fill"
        case "입장권": return "ticket.fill"
        case "식비": return "fork.knife"
        case "숙소": return "bed.double"
        case "쇼핑": return "bag.fill"
        default: return "creditcard.fill"
        }
    }
}

private struct ExpenseRow: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.appTheme) private var theme
    var expense: ExpenseItem
    var showsDivider = false
    @State private var isEditing = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            categoryIcon

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(expense.title)
                            .font(.subheadline.weight(.black))
                            .lineLimit(1)
                        Text(expense.category)
                            .font(.caption2.weight(.black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(categoryColor.opacity(0.12), in: Capsule())
                            .foregroundStyle(categoryColor)
                    }
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(Int(expense.amount))")
                            .font(.headline.weight(.black))
                            .monospacedDigit()
                        Text(expense.currency)
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.secondary)
                    }
                    .frame(minWidth: 70, alignment: .trailing)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 6) {
                        expenseMetaChips
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        expenseMetaChips
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                isEditing = true
            } label: {
                Image(systemName: "pencil")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 66, alignment: .top)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(.background.opacity(0.50))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(categoryColor)
                .frame(width: 3)
                .padding(.vertical, 10)
        }
        .overlay(alignment: .bottom) {
            if showsDivider {
                Rectangle()
                    .fill(Color.secondary.opacity(0.10))
                    .frame(height: 0.5)
                    .padding(.leading, 48)
            }
        }
        .sheet(isPresented: $isEditing) {
            ExpenseEditorSheet(existingExpense: expense)
                .environmentObject(store)
        }
    }

    private var categoryIcon: some View {
        Image(systemName: iconName)
            .font(.caption.weight(.black))
            .frame(width: 30, height: 30)
            .background(categoryColor.opacity(0.13), in: RoundedRectangle(cornerRadius: 9))
            .foregroundStyle(categoryColor)
    }

    private var iconName: String {
        switch expense.category {
        case "교통": return "tram.fill"
        case "입장권": return "ticket.fill"
        case "식비": return "fork.knife"
        case "숙소": return "bed.double"
        case "쇼핑": return "bag.fill"
        default: return "creditcard.fill"
        }
    }

    private var categoryColor: Color {
        switch expense.category {
        case "교통": return .blue
        case "입장권": return theme.accent
        case "식비": return .orange
        case "숙소": return theme.secondaryAccent
        case "쇼핑": return .pink
        default: return .secondary
        }
    }

    private var expenseMetaChips: some View {
        Group {
            ExpenseMetaText(title: "결제", value: expense.paidBy, tint: theme.accent)
            ExpenseMetaText(title: "부담", value: expense.intendedPayer, tint: theme.secondaryAccent)
            ExpenseMetaText(title: "사용", value: participantText, tint: .secondary)
        }
    }

    private var participantText: String {
        if expense.participants.isEmpty { return "전체" }
        return expense.participants.joined(separator: ", ")
    }
}

private struct ExpenseMetaText: View {
    var title: String
    var value: String
    var tint: Color

    var body: some View {
        HStack(spacing: 2) {
            Text(title)
                .foregroundStyle(.secondary)
            Text(value.isEmpty ? "미정" : value)
                .foregroundStyle(tint == .secondary ? .secondary : tint)
                .lineLimit(1)
        }
        .font(.caption2.weight(.black))
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(tint.opacity(0.09), in: Capsule())
    }
}

private struct ExpenseEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: TripStore
    @Environment(\.appTheme) private var theme
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
                                .background(category == item ? categoryTint(item) : .secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
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

    private func categoryTint(_ value: String) -> Color {
        switch value {
        case "교통": return .blue
        case "입장권": return theme.accent
        case "식비": return .orange
        case "숙소": return theme.secondaryAccent
        case "쇼핑": return .pink
        default: return theme.warmAccent
        }
    }
}

private struct LabeledExpenseField: View {
    @Environment(\.appTheme) private var theme
    var title: String
    var iconName: String
    var placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(theme.accent)
                .frame(width: 32, height: 32)
                .background(theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
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
    @Environment(\.appTheme) private var theme
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
                .background(selected(name) ? theme.accent : .secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
