import SwiftUI

struct ScheduleScreen: View {
    @EnvironmentObject private var store: TripStore
    @State private var selectedDate: Date?
    @State private var calendarMode = false

    private var dates: [Date] {
        let unique = Set(store.scheduleItems.map { Calendar.current.startOfDay(for: $0.date) })
        return unique.sorted()
    }

    private var visibleItems: [ScheduleItem] {
        guard let selectedDate else { return store.scheduleItems.sorted { $0.date < $1.date } }
        return store.scheduleItems.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    filterBar

                    Toggle("Calendar view", isOn: $calendarMode)
                        .font(.subheadline.weight(.bold))

                    if calendarMode {
                        calendarGrid
                    } else {
                        ForEach(visibleItems) { item in
                            ScheduleRow(item: item)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("일정")
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button("전체") { selectedDate = nil }
                    .buttonStyle(.borderedProminent)
                ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                    Button("Day \(index + 1) · \(date.dayLabel)") {
                        selectedDate = date
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 170))], spacing: 12) {
            ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                let count = store.scheduleItems.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }.count
                Button {
                    selectedDate = date
                    calendarMode = false
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Day \(index + 1)")
                            .font(.caption.weight(.black))
                            .foregroundStyle(.teal)
                        Text(date.dayLabel)
                            .font(.headline.weight(.black))
                        Text("\(count)개 일정")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ScheduleRow: View {
    var item: ScheduleItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .trailing) {
                Text(item.startTime.isEmpty ? item.kind.rawValue : item.startTime)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.teal)
                if !item.endTime.isEmpty {
                    Text(item.endTime)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 58)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline.weight(.black))
                if !item.placeName.isEmpty {
                    Text(item.placeName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.subheadline)
                }
            }
            Spacer()
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(item.kind == .move ? .blue : item.kind == .food ? .orange : .teal)
                .frame(width: 4)
        }
    }
}

