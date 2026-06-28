import SwiftUI

struct ScheduleScreen: View {
    @EnvironmentObject private var store: TripStore
    @State private var selectedDate: Date?
    @State private var viewMode: ScheduleViewMode = .timeline

    private var dates: [Date] {
        let unique = Set(store.scheduleItemsForSelectedCity().map { Calendar.current.startOfDay(for: $0.date) })
        return unique.sorted()
    }

    private var visibleItems: [ScheduleItem] {
        let items = store.scheduleItemsForSelectedCity()
        guard let selectedDate else { return items }
        return items.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ScreenHeader(title: scheduleTitle, subtitle: scheduleSubtitle)

                    VStack(alignment: .leading, spacing: 12) {
                        filterBar

                        Picker("보기", selection: $viewMode) {
                            Text("Timeline").tag(ScheduleViewMode.timeline)
                            Text("Calendar").tag(ScheduleViewMode.calendar)
                        }
                        .pickerStyle(.segmented)
                    }
                    .appPanel(cornerRadius: 18)

                    if viewMode == .calendar {
                        calendarGrid
                    } else {
                        if visibleItems.isEmpty {
                            EmptyStateView(
                                title: "일정이 비어있어요",
                                message: "지도나 장소 후보에서 바로 일정에 추가할 수 있습니다.",
                                iconName: "calendar.badge.plus"
                            )
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                                    ScheduleRow(item: item, isLast: index == visibleItems.count - 1)
                                }
                            }
                            .appPanel()
                        }
                    }
                }
                .readableWidth()
                .padding()
            }
            .navigationTitle("일정")
        }
    }

    private var scheduleTitle: String {
        store.currentCity.isEmpty ? "Schedule" : "\(displayCity(store.currentCity)) Schedule"
    }

    private var scheduleSubtitle: String {
        if let selectedDate {
            return "\(compactDayLabel(selectedDate)) · \(visibleItems.count)개 일정"
        }
        return "\(dates.count)일 · \(visibleItems.count)개 일정"
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
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: "CALENDAR")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 10)], spacing: 10) {
                ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                    let dayItems = store.scheduleItemsForSelectedCity().filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
                    let isSelected = selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
                    Button {
                        selectedDate = date
                        viewMode = .timeline
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Day \(index + 1)")
                                        .font(.caption.weight(.black))
                                        .foregroundStyle(isSelected ? .white.opacity(0.82) : .teal)
                                    Text(compactDayLabel(date))
                                        .font(.title3.weight(.black))
                                }
                                Spacer()
                                Text("\(dayItems.count)")
                                    .font(.caption.weight(.black))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(isSelected ? .white.opacity(0.20) : .secondary.opacity(0.12), in: Capsule())
                            }

                            VStack(alignment: .leading, spacing: 5) {
                                ForEach(dayItems.prefix(3)) { item in
                                    HStack(spacing: 6) {
                                        Text(item.startTime.isEmpty ? item.kind.rawValue : item.startTime)
                                            .font(.caption2.weight(.black))
                                            .foregroundStyle(isSelected ? .white.opacity(0.82) : .secondary)
                                            .frame(width: 36, alignment: .leading)
                                        Text(item.title)
                                            .font(.caption.weight(.bold))
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 48, alignment: .topLeading)

                            Text("탭하면 타임라인으로 보기")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(isSelected ? .white.opacity(0.75) : .secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 138, alignment: .topLeading)
                        .padding(12)
                        .background(isSelected ? Color.blue : Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(isSelected ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func compactDayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M.d E"
        return formatter.string(from: date)
    }

    private func displayCity(_ city: String) -> String {
        switch city {
        case "타카마쓰": return "Takamatsu"
        case "나오시마": return "Naoshima"
        case "도쿄": return "Tokyo"
        default: return city
        }
    }
}

private enum ScheduleViewMode: Hashable {
    case timeline
    case calendar
}

struct ScheduleRow: View {
    var item: ScheduleItem
    var isLast = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.startTime.isEmpty ? item.kind.rawValue : item.startTime)
                    .font(.caption.weight(.black))
                    .foregroundStyle(kindColor)
                if !item.endTime.isEmpty {
                    Text(item.endTime)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 58)

            ZStack(alignment: .top) {
                if !isLast {
                    Rectangle()
                        .fill(kindColor.opacity(0.28))
                        .frame(width: 2, height: 78)
                        .padding(.top, 16)
                }
                Circle()
                    .fill(.background)
                    .frame(width: 14, height: 14)
                    .overlay {
                        Circle()
                            .stroke(kindColor, lineWidth: 3)
                    }
                    .padding(.top, 1)
            }
            .frame(minHeight: 74, alignment: .top)
            .frame(width: 18)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(item.title)
                        .font(.headline.weight(.black))
                    Text(item.kind.rawValue)
                        .font(.caption2.weight(.black))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(kindColor.opacity(0.14), in: Capsule())
                        .foregroundStyle(kindColor)
                }
                if !item.placeName.isEmpty {
                    Text(item.placeName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 14)
            .overlay(alignment: .bottom) {
                if !isLast {
                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 1)
                }
            }
            Spacer()
        }
        .padding(.vertical, 10)
    }

    private var kindColor: Color {
        switch item.kind {
        case .move: return .blue
        case .food: return .orange
        case .flight: return .purple
        case .place: return .teal
        }
    }
}
