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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ScreenHeader(title: "Budget", subtitle: "여행 지출과 예상 부담을 한눈에 확인")

                    VStack(alignment: .leading, spacing: 14) {
                        Text("TOTAL")
                            .font(.caption.weight(.black))
                            .foregroundStyle(.secondary)
                        HStack(alignment: .firstTextBaseline) {
                            Text("\(Int(total))")
                                .font(.system(size: 38, weight: .black, design: .rounded))
                            Text(store.trip?.budgetCurrency ?? "JPY")
                                .font(.headline.weight(.black))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(budget > 0 ? "\(Int(progress * 100))%" : "예산 미정")
                                .font(.title3.weight(.black))
                                .foregroundStyle(.teal)
                        }
                        ProgressView(value: progress)
                            .tint(.teal)
                        if budget > 0 {
                            Text("예산 \(Int(budget)) \(store.trip?.budgetCurrency ?? "JPY") 기준")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .appPanel()

                    SectionLabel(title: "EXPENSES")
                    VStack(spacing: 8) {
                        ForEach(store.expenses) { expense in
                            ExpenseRow(expense: expense)
                        }
                    }
                    .appPanel()
                }
                .padding()
            }
            .navigationTitle("예산")
        }
    }
}

private struct ExpenseRow: View {
    var expense: ExpenseItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
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
        .padding(.vertical, 6)
    }
}
