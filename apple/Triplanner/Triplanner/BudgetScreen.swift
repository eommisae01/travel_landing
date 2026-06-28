import SwiftUI

struct BudgetScreen: View {
    @EnvironmentObject private var store: TripStore

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
                        SectionLabel(title: "SPENT")
                        HStack(alignment: .firstTextBaseline) {
                            Text("\(Int(total))")
                                .font(.system(size: 44, weight: .black, design: .rounded))
                            Text(store.trip?.budgetCurrency ?? "JPY")
                                .font(.headline.weight(.black))
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        ProgressView(value: progress)
                            .tint(.teal)

                        HStack(spacing: 8) {
                            BudgetStat(title: "예산", value: budget > 0 ? "\(Int(budget))" : "미정", unit: store.trip?.budgetCurrency ?? "JPY")
                            BudgetStat(title: "남은 금액", value: budget > 0 ? "\(Int(remainingBudget))" : "-", unit: store.trip?.budgetCurrency ?? "JPY")
                            BudgetStat(title: "사용률", value: budget > 0 ? "\(Int(progress * 100))" : "-", unit: "%")
                        }
                    }
                    .appPanel()

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
                        .appPanel()
                    }

                    SectionLabel(title: "EXPENSES")
                    if store.expenses.isEmpty {
                        Text("아직 입력된 지출이 없습니다.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 88)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    } else {
                        VStack(spacing: 6) {
                            ForEach(store.expenses) { expense in
                                ExpenseRow(expense: expense)
                            }
                        }
                        .appPanel()
                    }
                }
                .readableWidth(900)
                .padding()
            }
            .navigationTitle("예산")
        }
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
    var expense: ExpenseItem

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: iconName)
                .font(.headline.weight(.bold))
                .frame(width: 34, height: 34)
                .background(.teal.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.teal)

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.subheadline.weight(.black))
                Text("\(expense.category) · 결제 \(expense.paidBy) · 예정 \(expense.intendedPayer)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(expense.participants.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(expense.amount))")
                    .font(.headline.weight(.black))
                Text(expense.currency)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(.background.opacity(0.52), in: RoundedRectangle(cornerRadius: 12))
    }

    private var iconName: String {
        switch expense.category {
        case "교통": return "tram.fill"
        case "입장권": return "ticket.fill"
        case "식비": return "fork.knife"
        default: return "creditcard.fill"
        }
    }
}
