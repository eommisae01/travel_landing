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
            List {
                Section("예산") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(Int(total)) \(store.trip?.budgetCurrency ?? "JPY")")
                                .font(.headline.weight(.black))
                            Spacer()
                            Text(budget > 0 ? "\(Int(progress * 100))%" : "예산 미정")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: progress)
                    }
                    .padding(.vertical, 6)
                }

                Section("지출") {
                    ForEach(store.expenses) { expense in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(expense.category) · \(expense.title)")
                                .font(.headline.weight(.black))
                            Text("\(Int(expense.amount)) \(expense.currency) · 결제 \(expense.paidBy) · 예정 \(expense.intendedPayer)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            Text("사용자: \(expense.participants.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("예산")
        }
    }
}

