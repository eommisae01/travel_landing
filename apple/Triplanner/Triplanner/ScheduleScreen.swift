import SwiftUI

struct ScheduleScreen: View {
    @EnvironmentObject private var store: TripStore
    @State private var selectedDate: Date?
    @State private var viewMode: ScheduleViewMode = .timeline

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

                    Picker("보기", selection: $viewMode) {
                        Text("Timeline").tag(ScheduleViewMode.timeline)
                        Text("Calendar").tag(ScheduleViewMode.calendar)
                    }
                    .pickerStyle(.segmented)

                    if viewMode == .calendar {
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
            HStack(spacing: 8) {
                dayFilterButton(title: "전체", isSelected: selectedDate == nil) {
                    selectedDate = nil
                }
                ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                    dayFilterButton(title: "Day \(index + 1) (\(compactDayLabel(date)))", isSelected: selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false) {
                        selectedDate = date
                    }
                }
            }
        }
    }

    private func dayFilterButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.black))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.secondary.opacity(0.12), in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 10) {
            ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                let count = store.scheduleItems.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }.count
                Button {
                    selectedDate = date
                    viewMode = .timeline
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Day \(index + 1)")
                            .font(.caption.weight(.black))
                            .foregroundStyle(.teal)
                        Text(compactDayLabel(date))
                            .font(.headline.weight(.black))
                        Text("\(count)개 일정")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Calendar.current.isDate(date, inSameDayAs: selectedDate ?? Date.distantPast) ? Color.blue.opacity(0.16) : Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func compactDayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M.d E"
        return formatter.string(from: date)
    }
}

private enum ScheduleViewMode: Hashable {
    case timeline
    case calendar
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
