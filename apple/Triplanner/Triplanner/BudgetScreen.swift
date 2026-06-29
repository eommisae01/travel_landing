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

    private var currency: String {
        store.trip?.budgetCurrency ?? "JPY"
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
                VStack(alignment: .leading, spacing: 24) {
                    ScreenHeader(title: "Budget", subtitle: "여행 지출과 예상 부담을 한눈에 확인")

                    VStack(alignment: .leading, spacing: 22) {
                        HStack(alignment: .top, spacing: 14) {
                            VStack(alignment: .leading, spacing: 7) {
                                HStack(spacing: 10) {
                                    Image(systemName: "creditcard.fill")
                                        .font(.title3.weight(.black))
                                        .foregroundStyle(.white)
                                        .frame(width: 48, height: 48)
                                        .background(spendingTint, in: RoundedRectangle(cornerRadius: 15))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("여행 한도")
                                            .font(.callout.weight(.black))
                                            .foregroundStyle(.secondary)
                                        Text(budget > 0 ? "\(Int(budget)) \(currency)" : "미설정")
                                            .font(.system(size: 31, weight: .black, design: .rounded))
                                            .monospacedDigit()
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.82)
                                    }
                                }
                                Text(budget > 0 ? "이 금액을 기준으로 사용률과 남은 금액을 계산해요" : "예산 설정에서 이번 여행 기준 금액을 정할 수 있어요")
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer(minLength: 10)
                            BudgetLimitButton(
                                budgetIsSet: budget > 0,
                                onEditLimit: { isEditingBudget = true }
                            )
                        }

                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .lastTextBaseline, spacing: 24) {
                                BudgetAmountBlock(title: "사용", amount: total, unit: currency, tint: spendingTint, isPrimary: true)
                                BudgetAmountBlock(title: budget > 0 && total > budget ? "초과" : "남음", amount: budget > 0 ? (total > budget ? overBudget : remainingBudget) : 0, unit: currency, tint: total > budget && budget > 0 ? .orange : theme.secondaryAccent, isPrimary: false)
                            }
                            VStack(alignment: .leading, spacing: 10) {
                                BudgetAmountBlock(title: "사용", amount: total, unit: currency, tint: spendingTint, isPrimary: true)
                                BudgetAmountBlock(title: budget > 0 && total > budget ? "초과" : "남음", amount: budget > 0 ? (total > budget ? overBudget : remainingBudget) : 0, unit: currency, tint: total > budget && budget > 0 ? .orange : theme.secondaryAccent, isPrimary: false)
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .firstTextBaseline) {
                                Text("사용률")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(budget > 0 ? "\(Int(progress * 100))%" : "한도 미정")
                                    .font(.headline.weight(.black))
                                    .foregroundStyle(spendingTint)
                                    .monospacedDigit()
                            }
                            BudgetProgressBar(progress: progress, tint: spendingTint)
                            HStack {
                                Text("0")
                                Spacer()
                                Text(budget > 0 ? "\(Int(budget)) \(currency)" : "예산 설정에서 한도를 정해요")
                            }
                            .font(.caption.weight(.black))
                            .foregroundStyle(.secondary)
                        }

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 12)], spacing: 12) {
                            BudgetStat(title: "한도", value: budget > 0 ? "\(Int(budget))" : "미정", unit: currency, tint: theme.accent)
                            BudgetStat(title: budget > 0 && total > budget ? "초과" : "남음", value: balanceValue, unit: currency, tint: total > budget && budget > 0 ? .orange : theme.secondaryAccent)
                            BudgetStat(title: "지출", value: "\(store.expenses.count)", unit: "개", tint: theme.warmAccent)
                        }
                    }
                    .appPanel(cornerRadius: 24)

                    if !categoryTotals.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("카테고리별 지출")
                                .font(.title3.weight(.black))
                            VStack(spacing: 10) {
                                ForEach(categoryTotals, id: \.0) { category, amount in
                                    CategoryBudgetRow(
                                        category: category,
                                        amount: amount,
                                        total: total,
                                        currency: currency
                                    )
                                }
                            }
                        }
                        .appPanel(cornerRadius: 18)
                    }

                    HStack {
                        Text("지출 내역")
                            .font(.title3.weight(.black))
                        Spacer()
                        Button {
                            isAddingExpense = true
                        } label: {
                            Label("지출 추가", systemImage: "plus")
                                .font(.headline.weight(.black))
                        }
                        .buttonStyle(.bordered)
                    }
                    if store.expenses.isEmpty {
                        EmptyStateView(
                            title: "지출이 비어있어요",
                            message: "항공권, 숙소, 식비처럼 함께 볼 비용을 추가하면 사용률이 계산됩니다.",
                            iconName: "creditcard"
                        )
                    } else {
                        VStack(spacing: 10) {
                            ForEach(store.expenses) { expense in
                                ExpenseRow(expense: expense)
                            }
                        }
                        .appPanel(cornerRadius: 18)
                    }
                }
                .readableWidth(980)
                .padding(28)
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
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

private struct BudgetLimitButton: View {
    @Environment(\.appTheme) private var theme
    var budgetIsSet: Bool
    var onEditLimit: () -> Void

    var body: some View {
        Button {
            onEditLimit()
        } label: {
            Label(budgetIsSet ? "예산 수정" : "예산 설정", systemImage: "slider.horizontal.3")
                .font(.callout.weight(.black))
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .padding(.horizontal, 13)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.accent)
        .background(theme.accent.opacity(0.12), in: Capsule())
        .accessibilityHint("여행 전체 예산 한도를 설정합니다")
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
                    ScreenHeader(title: "예산 설정", subtitle: "이번 여행에서 함께 확인할 총 금액")

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(title: "금액")
                        HStack(spacing: 10) {
                            TextField("예: 150000", text: $amount)
                                .textFieldStyle(.roundedBorder)
                            TextField("JPY", text: $currency)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 92)
                        }
                        Text("0으로 저장하면 한도 미정으로 표시됩니다.")
                            .font(.callout.weight(.semibold))
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
    var tint: Color

    var body: some View {
        HStack(spacing: 9) {
            Circle()
                .fill(tint.opacity(0.16))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(value)
                        .font(.headline.weight(.black))
                        .monospacedDigit()
                    Text(unit)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(tint.opacity(0.065), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(tint.opacity(0.11))
        }
    }
}

private struct BudgetProgressBar: View {
    var progress: Double
    var tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.12))
                Capsule()
                    .fill(tint)
                    .frame(width: max(8, proxy.size.width * min(max(progress, 0), 1)))
            }
        }
        .frame(height: 12)
        .overlay {
            Capsule()
                .stroke(Color.primary.opacity(0.045))
        }
    }
}

private struct BudgetAmountBlock: View {
    var title: String
    var amount: Double
    var unit: String
    var tint: Color
    var isPrimary: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(Int(amount))")
                    .font(.system(size: isPrimary ? 42 : 28, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isPrimary ? .primary : tint)
                Text(unit)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: isPrimary ? .infinity : 220, alignment: .leading)
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
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Label(category, systemImage: iconName)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(tint)
                Spacer()
                Text("\(Int(amount)) \(currency)")
                    .font(.subheadline.weight(.black))
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
            .frame(height: 9)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(.background.opacity(0.64), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(tint.opacity(0.10))
        }
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
    @State private var isEditing = false

    var body: some View {
        HStack(alignment: .center, spacing: 13) {
            categoryIcon

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(expense.title)
                        .font(.headline.weight(.black))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Label(expense.category, systemImage: iconName)
                        .font(.caption.weight(.black))
                        .foregroundStyle(categoryColor)
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

            amountControl
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .center)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.background.opacity(0.66), in: RoundedRectangle(cornerRadius: 15))
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(categoryColor.opacity(0.10))
        }
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(categoryColor)
                .frame(width: 3)
                .padding(.vertical, 12)
        }
        .sheet(isPresented: $isEditing) {
            ExpenseEditorSheet(existingExpense: expense)
                .environmentObject(store)
        }
    }

    private var categoryIcon: some View {
        Image(systemName: iconName)
            .font(.subheadline.weight(.black))
            .frame(width: 38, height: 38)
            .background(categoryColor.opacity(0.13), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(categoryColor)
    }

    private var amountControl: some View {
        HStack(spacing: 8) {
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(Int(expense.amount))")
                    .font(.title3.weight(.black))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(expense.currency)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 78, alignment: .trailing)

            Button {
                isEditing = true
            } label: {
                Image(systemName: "pencil")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("지출 수정")
        }
        .frame(width: 126, alignment: .center)
        .frame(minHeight: 60, alignment: .center)
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
