import SwiftUI

struct ScheduleScreen: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.appTheme) private var theme
    @State private var selectedDate: Date?
    @State private var viewMode: ScheduleViewMode = .timeline
    @State private var isAddingSchedule = false
    @State private var scheduleDraftDate = Date()

    private var dates: [Date] {
        let scheduleDates = store.scheduleItemsForSelectedCity().map { Calendar.current.startOfDay(for: $0.date) }
        let unique = Set(scheduleDates + tripDateRange)
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

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            SectionLabel(title: "DATE")
                            Spacer()
                            Text(viewMode == .timeline ? "Timeline" : "Calendar")
                                .font(.caption2.weight(.black))
                                .foregroundStyle(viewMode == .calendar ? theme.accent : .secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background((viewMode == .calendar ? theme.accent : Color.secondary).opacity(0.10), in: Capsule())
                        }
                        filterBar

                        Picker("보기 방식", selection: $viewMode) {
                            Label("Timeline", systemImage: "list.bullet.rectangle")
                                .tag(ScheduleViewMode.timeline)
                            Label("Calendar", systemImage: "calendar")
                                .tag(ScheduleViewMode.calendar)
                        }
                        .pickerStyle(.segmented)

                        if !dates.isEmpty && viewMode == .timeline {
                            calendarPreview
                        }
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
                            timelineList
                        }
                    }
                }
                .readableWidth()
                .padding()
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        openScheduleEditor(for: selectedDate ?? dates.first ?? Date())
                    } label: {
                        Label("일정 추가", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingSchedule) {
                ScheduleEditorSheet(defaultDate: scheduleDraftDate)
                    .environmentObject(store)
            }
        }
        .appScreenBackground()
    }

    private var scheduleTitle: String {
        store.currentCity.isEmpty ? "\(store.trip?.name ?? "Trip") Schedule" : "\(displayCity(store.currentCity)) Schedule"
    }

    private var scheduleSubtitle: String {
        if let selectedDate {
            return "\(compactDayLabel(selectedDate)) · \(visibleItems.count)개 일정"
        }
        return "\(store.currentCity.isEmpty ? "전체 여행" : "현재 도시") \(dates.count)일 · \(visibleItems.count)개 일정"
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                dayFilterButton(title: "전체", subtitle: "\(store.scheduleItemsForSelectedCity().count)개", isSelected: selectedDate == nil) {
                    selectedDate = nil
                }
                ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                    dayFilterButton(
                        title: "Day \(index + 1)",
                        subtitle: compactDayLabel(date),
                        isSelected: selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
                    ) {
                        selectedDate = date
                    }
                }
            }
        }
    }

    private func dayFilterButton(title: String, subtitle: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.caption.weight(.black))
                    Text(subtitle)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(isSelected ? .white.opacity(0.82) : .secondary)
                }
                Spacer(minLength: 0)
                if isSelected {
                    Circle()
                        .fill(.white.opacity(0.92))
                        .frame(width: 7, height: 7)
                }
            }
            .frame(width: title == "전체" ? 92 : 112, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isSelected ? theme.accent : Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(isSelected ? .white : .primary)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? theme.accent.opacity(0.44) : Color.secondary.opacity(0.10), lineWidth: isSelected ? 1.5 : 1)
            }
            .shadow(color: isSelected ? theme.accent.opacity(0.16) : .clear, radius: 7, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var calendarPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("CALENDAR")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    viewMode = .calendar
                } label: {
                    Label("전체 보기", systemImage: "calendar")
                        .font(.caption2.weight(.black))
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.accent)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 7)], spacing: 7) {
                ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                    let isSelected = selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
                    Button {
                        selectedDate = date
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Day \(index + 1)")
                                .font(.caption2.weight(.black))
                            Text(compactDayLabel(date))
                                .font(.caption.weight(.black))
                        }
                        .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 7)
                        .background(isSelected ? theme.accent : Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(isSelected ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(10)
        .background(.background.opacity(0.50), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.quaternary)
        }
    }

    private var calendarGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    SectionLabel(title: "CALENDAR")
                    Text(calendarTitle)
                        .font(.headline.weight(.black))
                }
                Spacer()
                Button {
                    selectedDate = nil
                    viewMode = .timeline
                } label: {
                    Label("Timeline", systemImage: "list.bullet")
                        .font(.caption.weight(.black))
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.accent)
            }

            HStack(spacing: 0) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 6)

            LazyVGrid(columns: calendarColumns, spacing: 7) {
                ForEach(calendarDisplayDates, id: \.self) { date in
                    let dayItems = items(on: date)
                    let index = dayIndex(for: date)
                    let isSelected = selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
                    let isTripDay = index != nil
                    Button {
                        guard isTripDay else { return }
                        selectedDate = date
                    } label: {
                        CalendarDayCell(
                            dayNumber: dayNumber(date),
                            dayLabel: index.map { "Day \($0 + 1)" },
                            firstItemTitle: dayItems.first?.title,
                            itemCount: dayItems.count,
                            isTripDay: isTripDay,
                            isSelected: isSelected
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!isTripDay)
                }
            }

            calendarDaySummaryStrip
            calendarDetailPanels
        }
        .appPanel(cornerRadius: 18)
    }

    private var calendarDetailPanels: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 10) {
                calendarTimeGridPanel
                    .frame(minWidth: 420)
                calendarAgendaPanel
                    .frame(width: 300)
            }

            VStack(alignment: .leading, spacing: 10) {
                calendarTimeGridPanel
                calendarAgendaPanel
            }
        }
    }

    private var calendarDaySummaryStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionLabel(title: "DAY SUMMARY")
                Spacer()
                Text(selectedDate.map(compactDayLabel) ?? "전체 날짜")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.10), in: Capsule())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                        let dayItems = items(on: date)
                        let isSelected = selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
                        Button {
                            selectedDate = date
                        } label: {
                            CalendarSummaryCard(
                                dayTitle: "Day \(index + 1)",
                                dateTitle: compactDayLabel(date),
                                itemCount: dayItems.count,
                                firstTitle: dayItems.first?.title,
                                isSelected: isSelected
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 1)
            }
        }
        .padding(10)
        .background(.background.opacity(0.46), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.quaternary)
        }
    }

    private var calendarTimeGridPanel: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                SectionLabel(title: "TIME GRID")
                Spacer()
                Text(selectedDate.map(compactDayLabel) ?? "전체 날짜")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.10), in: Capsule())
            }

            if selectedDate == nil && dates.count > 1 {
                MultiDayCalendarGrid(dates: timelineDates.isEmpty ? dates : timelineDates, itemsForDate: items(on:))
            } else if let focusDate = calendarFocusDate {
                CalendarTimeGrid(date: focusDate, items: items(on: focusDate), dayLabel: dayTitle(for: focusDate))
            } else {
                EmptyStateView(
                    title: "표시할 날짜가 없어요",
                    message: "여행 기간이나 일정을 추가하면 시간표가 나타납니다.",
                    iconName: "calendar"
                )
            }
        }
        .padding(10)
        .background(.background.opacity(0.46), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.quaternary)
        }
    }

    private var calendarAgendaPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionLabel(title: selectedDate.map { compactDayLabel($0) } ?? "ALL SCHEDULE")
                Spacer()
                if selectedDate != nil {
                    Button {
                        selectedDate = nil
                    } label: {
                        Label("전체", systemImage: "xmark")
                            .font(.caption2.weight(.black))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }

            let agendaItems = selectedDate.map { items(on: $0) } ?? allVisibleItemsSorted
            if agendaItems.isEmpty {
                Text("이 날짜에는 일정이 없습니다.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
                    .padding(.horizontal, 10)
                    .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 6) {
                    ForEach(agendaItems.prefix(5)) { item in
                        CalendarAgendaRow(item: item)
                    }
                    if agendaItems.count > 5 {
                        Text("+ \(agendaItems.count - 5)개 더 있음")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 2)
                    }
                }
            }
        }
        .padding(10)
        .background(.background.opacity(0.46), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.quaternary)
        }
    }

    private var calendarFocusDate: Date? {
        selectedDate ?? timelineDates.first ?? dates.first
    }

    private var timelineList: some View {
        VStack(alignment: .leading, spacing: 10) {
            if selectedDate == nil {
                ForEach(timelineDates, id: \.self) { date in
                    timelineSection(date: date, items: items(on: date))
                }
            } else {
                timelineSection(date: selectedDate ?? Date(), items: visibleItems)
            }
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(.quaternary)
        }
    }

    private var timelineDates: [Date] {
        dates.filter { !items(on: $0).isEmpty }
    }

    private var allVisibleItemsSorted: [ScheduleItem] {
        store.scheduleItemsForSelectedCity().sorted(by: scheduleSort)
    }

    private var calendarColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 38), spacing: 7), count: 7)
    }

    private var calendarDisplayDates: [Date] {
        guard let first = dates.first, let last = dates.last else { return [] }
        let calendar = Calendar.current
        let firstWeekday = calendar.component(.weekday, from: first)
        let leadingDays = firstWeekday - calendar.firstWeekday
        let normalizedLeadingDays = leadingDays >= 0 ? leadingDays : leadingDays + 7
        let start = calendar.date(byAdding: .day, value: -normalizedLeadingDays, to: first) ?? first

        let lastWeekday = calendar.component(.weekday, from: last)
        let trailingDays = 6 - ((lastWeekday - calendar.firstWeekday + 7) % 7)
        let end = calendar.date(byAdding: .day, value: trailingDays, to: last) ?? last
        let dayCount = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return (0...max(dayCount, 0)).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private var calendarTitle: String {
        guard let first = dates.first else { return "여행 날짜" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: first)
    }

    private var weekdayLabels: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        var labels = formatter.shortWeekdaySymbols ?? ["일", "월", "화", "수", "목", "금", "토"]
        let firstIndex = max(Calendar.current.firstWeekday - 1, 0)
        if firstIndex > 0 {
            labels = Array(labels[firstIndex...]) + Array(labels[..<firstIndex])
        }
        return labels
    }

    private func timelineSection(date: Date, items: [ScheduleItem]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .center, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(dayTitle(for: date))
                        .font(.headline.weight(.black))
                    Text(compactDayLabel(date))
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(items.count)")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.10), in: Capsule())
                Button {
                    openScheduleEditor(for: date)
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.black))
                        .frame(width: 28, height: 28)
                        .background(theme.accent.opacity(0.13), in: RoundedRectangle(cornerRadius: 9))
                        .foregroundStyle(theme.accent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(dayTitle(for: date)) 일정 추가")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.background.opacity(0.38), in: RoundedRectangle(cornerRadius: 13))
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(theme.accent)
                    .frame(width: 3)
                    .padding(.vertical, 10)
            }

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    ScheduleRow(item: item, isLast: index == items.count - 1)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func items(on date: Date) -> [ScheduleItem] {
        store.scheduleItemsForSelectedCity()
            .filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .sorted(by: scheduleSort)
    }

    private func scheduleSort(_ lhs: ScheduleItem, _ rhs: ScheduleItem) -> Bool {
        if !Calendar.current.isDate(lhs.date, inSameDayAs: rhs.date) {
            return lhs.date < rhs.date
        }
        if lhs.startTime != rhs.startTime {
            return lhs.startTime < rhs.startTime
        }
        return lhs.title < rhs.title
    }

    private func dayIndex(for date: Date) -> Int? {
        dates.firstIndex { Calendar.current.isDate($0, inSameDayAs: date) }
    }

    private func dayNumber(_ date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        return "\(day)"
    }

    private func openScheduleEditor(for date: Date) {
        scheduleDraftDate = date
        isAddingSchedule = true
    }

    private var tripDateRange: [Date] {
        guard let trip = store.trip, let start = trip.startDate, let end = trip.endDate else { return [] }
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        let dayCount = calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
        return (0...max(dayCount, 0)).compactMap { calendar.date(byAdding: .day, value: $0, to: startDay) }
    }

    private func compactDayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M.d E"
        return formatter.string(from: date)
    }

    private func dayTitle(for date: Date) -> String {
        guard let index = dates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: date) }) else {
            return "Day"
        }
        return "Day \(index + 1)"
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

private struct MultiDayCalendarGrid: View {
    var dates: [Date]
    var itemsForDate: (Date) -> [ScheduleItem]

    private var displayHours: [Int] {
        let allHours = dates
            .flatMap { itemsForDate($0) }
            .compactMap { startHour(from: $0.startTime) }
        guard let first = allHours.min(), let last = allHours.max() else {
            return Array(8...20)
        }
        return Array(max(6, first - 1)...min(23, last + 2))
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Text("GMT+9")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.secondary)
                        .frame(width: 54, alignment: .trailing)
                        .padding(.trailing, 9)
                    ForEach(dates, id: \.self) { date in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(shortWeekday(date))
                                .font(.caption2.weight(.black))
                                .foregroundStyle(.secondary)
                            Text(compactDate(date))
                                .font(.subheadline.weight(.black))
                        }
                        .frame(width: 164, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .background(.secondary.opacity(0.045))
                    }
                }

                Divider().opacity(0.45)

                ForEach(displayHours, id: \.self) { hour in
                    HStack(alignment: .top, spacing: 0) {
                        Text("\(hour):00")
                            .font(.caption2.weight(.black).monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 54, alignment: .trailing)
                            .padding(.trailing, 9)
                            .padding(.top, 10)

                        ForEach(dates, id: \.self) { date in
                            let items = items(on: date, at: hour)
                            MultiDayHourCell(items: items, minHeight: rowHeight(for: items))
                        }
                    }
                }
            }
            .frame(minWidth: CGFloat(max(dates.count, 1)) * 180 + 54, alignment: .leading)
        }
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.quaternary)
        }
    }

    private func rowHeight(for items: [ScheduleItem]) -> CGFloat {
        items.isEmpty ? 42 : CGFloat(max(items.count, 1)) * 50 + 8
    }

    private func items(on date: Date, at hour: Int) -> [ScheduleItem] {
        let isFirstHour = hour == displayHours.first
        return itemsForDate(date).filter { item in
            guard let start = startHour(from: item.startTime) else { return isFirstHour }
            return start == hour
        }
    }

    private func startHour(from value: String) -> Int? {
        let pieces = value.split(separator: ":")
        guard let first = pieces.first, let hour = Int(first) else { return nil }
        return hour
    }

    private func compactDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M.d"
        return formatter.string(from: date)
    }

    private func shortWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

private struct MultiDayHourCell: View {
    var items: [ScheduleItem]
    var minHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if items.isEmpty {
                Rectangle()
                    .fill(Color.secondary.opacity(0.10))
                    .frame(height: 1)
                    .padding(.top, 15)
            } else {
                ForEach(items) { item in
                    CalendarTimeBlock(item: item)
                }
                .padding(.vertical, 4)
            }
        }
        .frame(width: 164, alignment: .topLeading)
        .frame(minHeight: minHeight, alignment: .topLeading)
        .padding(.horizontal, 8)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.secondary.opacity(0.12))
                .frame(width: 0.5)
        }
    }
}

private struct CalendarTimeGrid: View {
    @Environment(\.appTheme) private var theme
    var date: Date
    var items: [ScheduleItem]
    var dayLabel: String

    private var displayHours: [Int] {
        let itemHours = items.compactMap { startHour(from: $0.startTime) }
        guard let first = itemHours.min(), let last = itemHours.max() else {
            return Array(8...20)
        }
        return Array(max(6, first - 1)...min(23, last + 2))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayLabel)
                        .font(.caption.weight(.black))
                    Text(compactDate)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(items.count)개")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.accent.opacity(0.10), in: Capsule())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)

            Divider().opacity(0.45)

            VStack(spacing: 0) {
                ForEach(displayHours, id: \.self) { hour in
                    CalendarHourRow(
                        hour: hour,
                        items: itemsForHour(hour),
                        isLast: hour == displayHours.last
                    )
                }
            }
        }
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.quaternary)
        }
    }

    private var compactDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M.d E"
        return formatter.string(from: date)
    }

    private func itemsForHour(_ hour: Int) -> [ScheduleItem] {
        items.filter { item in
            guard let start = startHour(from: item.startTime) else { return hour == displayHours.first }
            return start == hour
        }
    }

    private func startHour(from value: String) -> Int? {
        let pieces = value.split(separator: ":")
        guard let first = pieces.first, let hour = Int(first) else { return nil }
        return hour
    }
}

private struct CalendarHourRow: View {
    @Environment(\.appTheme) private var theme
    var hour: Int
    var items: [ScheduleItem]
    var isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(hourLabel)
                .font(.caption2.weight(.black).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .trailing)
                .padding(.top, 10)

            ZStack(alignment: .top) {
                Rectangle()
                    .fill(Color.secondary.opacity(isLast ? 0 : 0.18))
                    .frame(width: 1)
                Circle()
                    .fill(items.isEmpty ? Color.secondary.opacity(0.28) : theme.accent)
                    .frame(width: items.isEmpty ? 5 : 8, height: items.isEmpty ? 5 : 8)
                    .padding(.top, 14)
            }
            .frame(width: 10)
            .frame(minHeight: rowHeight)

            VStack(alignment: .leading, spacing: 6) {
                if items.isEmpty {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.09))
                        .frame(height: 1)
                        .padding(.top, 17)
                } else {
                    ForEach(items) { item in
                        CalendarTimeBlock(item: item)
                    }
                    .padding(.vertical, 5)
                }
            }
            .frame(maxWidth: .infinity, minHeight: rowHeight, alignment: .topLeading)
        }
        .padding(.horizontal, 6)
    }

    private var rowHeight: CGFloat {
        items.isEmpty ? 42 : CGFloat(max(1, items.count)) * 48 + 8
    }

    private var hourLabel: String {
        "\(hour):00"
    }
}

private struct CalendarTimeBlock: View {
    @Environment(\.appTheme) private var theme
    var item: ScheduleItem

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(timeText)
                        .font(.caption2.weight(.black).monospacedDigit())
                    Text(item.kind.rawValue)
                        .font(.caption2.weight(.black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(tint.opacity(0.12), in: Capsule())
                }
                .foregroundStyle(tint)

                Text(item.title)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if !item.placeName.isEmpty {
                    Text(item.placeName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 42, alignment: .center)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(tint.opacity(0.075), in: RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(tint)
                .frame(width: 3)
                .padding(.vertical, 8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(tint.opacity(0.12))
        }
    }

    private var timeText: String {
        if item.startTime.isEmpty { return "--:--" }
        if item.endTime.isEmpty { return item.startTime }
        return "\(item.startTime)-\(item.endTime)"
    }

    private var tint: Color {
        switch item.kind {
        case .food: return .orange
        case .move: return .blue
        case .flight: return .purple
        case .place: return theme.accent
        }
    }
}

private struct CalendarAgendaRow: View {
    @Environment(\.appTheme) private var theme
    var item: ScheduleItem

    var body: some View {
        HStack(spacing: 9) {
            Text(item.startTime.isEmpty ? item.kind.rawValue : item.startTime)
                .font(.caption.weight(.black).monospacedDigit())
                .foregroundStyle(kindColor)
                .frame(width: 48, alignment: .trailing)

            Circle()
                .fill(kindColor)
                .frame(width: 7, height: 7)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.caption.weight(.black))
                    .lineLimit(1)
                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 38, alignment: .center)
        .padding(.horizontal, 9)
        .background(kindColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 11))
    }

    private var kindColor: Color {
        switch item.kind {
        case .food: return .orange
        case .move: return .blue
        case .flight: return .purple
        case .place: return theme.accent
        }
    }
}

private struct CalendarSummaryCard: View {
    @Environment(\.appTheme) private var theme
    var dayTitle: String
    var dateTitle: String
    var itemCount: Int
    var firstTitle: String?
    var isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayTitle)
                        .font(.caption.weight(.black))
                    Text(dateTitle)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(isSelected ? .white.opacity(0.78) : .secondary)
                }
                Spacer(minLength: 8)
                Text("\(itemCount)")
                    .font(.caption2.weight(.black))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(isSelected ? .white.opacity(0.18) : Color.secondary.opacity(0.10), in: Capsule())
                    .foregroundStyle(isSelected ? .white : .secondary)
            }

            Text(firstTitle ?? "일정 없음")
                .font(.caption.weight(.black))
                .foregroundStyle(isSelected ? .white : .primary)
                .lineLimit(1)

            Rectangle()
                .fill(isSelected ? .white.opacity(0.46) : theme.accent.opacity(itemCount > 0 ? 0.28 : 0.10))
                .frame(height: 3)
                .clipShape(Capsule())
        }
        .frame(width: 150, height: 82, alignment: .topLeading)
        .padding(10)
        .background(isSelected ? theme.accent : Color.secondary.opacity(0.065), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? theme.accent.opacity(0.36) : Color.secondary.opacity(0.12), lineWidth: isSelected ? 1.5 : 1)
        }
        .shadow(color: isSelected ? theme.accent.opacity(0.16) : .clear, radius: 8, x: 0, y: 4)
    }
}

private struct CalendarDayCell: View {
    @Environment(\.appTheme) private var theme
    var dayNumber: String
    var dayLabel: String?
    var firstItemTitle: String?
    var itemCount: Int
    var isTripDay: Bool
    var isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(dayNumber)
                    .font(.headline.weight(.black).monospacedDigit())
                    .foregroundStyle(dayNumberForeground)
                    .frame(width: 30, height: 30)
                    .background(dayNumberBackground, in: Circle())
                Spacer(minLength: 4)
                if itemCount > 0 {
                    Text("\(itemCount)")
                        .font(.caption2.weight(.black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(counterBackground, in: Capsule())
                        .foregroundStyle(counterForeground)
                }
            }

            if let dayLabel {
                Text(dayLabel)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(dayLabelForeground)
                    .lineLimit(1)
            } else {
                Text(" ")
                    .font(.caption2.weight(.black))
            }

            if let firstItemTitle, isTripDay {
                Text(firstItemTitle)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(secondaryForeground)
                    .lineLimit(2)
            } else if isTripDay {
                Text("일정 없음")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(secondaryForeground)
                    .lineLimit(1)
            } else {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 88, maxHeight: 88, alignment: .topLeading)
        .padding(8)
        .background(cellBackground, in: RoundedRectangle(cornerRadius: 13))
        .overlay {
            RoundedRectangle(cornerRadius: 13)
                .stroke(borderColor, lineWidth: isSelected ? 1.5 : 1)
        }
        .shadow(color: isSelected ? theme.accent.opacity(0.14) : .clear, radius: 8, x: 0, y: 4)
        .opacity(isTripDay ? 1 : 0.36)
    }

    private var cellBackground: Color {
        if isSelected { return theme.accent.opacity(0.10) }
        return isTripDay ? Color.secondary.opacity(0.065) : Color.secondary.opacity(0.035)
    }

    private var borderColor: Color {
        if isSelected { return theme.accent.opacity(0.48) }
        return isTripDay ? Color.secondary.opacity(0.12) : Color.clear
    }

    private var primaryForeground: Color {
        isTripDay ? .primary : .secondary
    }

    private var dayNumberForeground: Color {
        isSelected ? .white : primaryForeground
    }

    private var dayNumberBackground: Color {
        isSelected ? theme.accent : .clear
    }

    private var secondaryForeground: Color {
        isSelected ? .primary : .secondary
    }

    private var dayLabelForeground: Color {
        isSelected ? theme.accent : theme.accent
    }

    private var counterBackground: Color {
        isSelected ? theme.accent.opacity(0.16) : .secondary.opacity(0.12)
    }

    private var counterForeground: Color {
        isSelected ? theme.accent : .secondary
    }
}

struct ScheduleRow: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.appTheme) private var theme
    var item: ScheduleItem
    var isLast = false
    @State private var isEditing = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.startTime.isEmpty ? item.kind.rawValue : item.startTime)
                    .font(.caption.weight(.black).monospacedDigit())
                    .foregroundStyle(kindColor)
                    .lineLimit(1)
                if !item.endTime.isEmpty {
                    Text(item.endTime)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 52)
            .padding(.top, 6)

            ZStack(alignment: .top) {
                if !isLast {
                    Rectangle()
                        .fill(kindColor.opacity(0.20))
                        .frame(width: 2, height: 76)
                        .padding(.top, 23)
                }
                Image(systemName: kindIcon)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(kindColor, in: Circle())
                    .shadow(color: kindColor.opacity(0.22), radius: 6, x: 0, y: 3)
            }
            .frame(width: 22)
            .frame(minHeight: 76, alignment: .top)

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 6) {
                            Text(item.kind.rawValue)
                                .font(.caption2.weight(.black))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(kindColor.opacity(0.12), in: Capsule())
                                .foregroundStyle(kindColor)
                            if !item.placeName.isEmpty {
                                Text(item.placeName)
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Text(item.title)
                            .font(.headline.weight(.black))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 4)
                    Button {
                        isEditing = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption.weight(.black))
                            .frame(width: 25, height: 25)
                            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("일정 수정")
                }
                if !item.sourceMapNote.isEmpty {
                    Label(item.sourceMapNote, systemImage: "mappin.and.ellipse")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(kindColor)
                        .lineLimit(1)
                }
                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(rowBackground)
            }
            .overlay(alignment: .leading) {
                if item.kind == .move || item.kind == .flight {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(kindColor)
                        .frame(width: 3)
                        .padding(.vertical, 10)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(kindColor.opacity(item.kind == .move || item.kind == .flight ? 0.16 : 0.04))
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $isEditing) {
            ScheduleEditorSheet(existingItem: item, defaultDate: item.date)
                .environmentObject(store)
        }
    }

    private var kindColor: Color {
        switch item.kind {
        case .move: return .blue
        case .food: return .orange
        case .flight: return .purple
        case .place: return theme.accent
        }
    }

    private var kindIcon: String {
        switch item.kind {
        case .move: return "arrow.triangle.swap"
        case .food: return "fork.knife"
        case .flight: return "airplane"
        case .place: return "mappin"
        }
    }

    private var rowBackground: Color {
        switch item.kind {
        case .move, .flight:
            return kindColor.opacity(0.08)
        case .food, .place:
            return Color.secondary.opacity(0.018)
        }
    }
}

struct ScheduleEditorSheet: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    var existingItem: ScheduleItem?
    var defaultDate: Date

    @State private var date = Date()
    @State private var startTime = ""
    @State private var endTime = ""
    @State private var title = ""
    @State private var placeName = ""
    @State private var sourceMapNote = ""
    @State private var note = ""
    @State private var kind: ScheduleKind = .place
    @State private var didLoad = false

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ScreenHeader(
                        title: existingItem == nil ? "일정 추가" : "일정 수정",
                        subtitle: "시간, 장소, 메모를 한 번에 정리"
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "WHEN")
                        DatePicker("날짜", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact)

                        HStack(spacing: 10) {
                            ScheduleEditorField(title: "시작", text: $startTime, placeholder: "10:30")
                            ScheduleEditorField(title: "종료", text: $endTime, placeholder: "12:00")
                        }
                    }
                    .appPanel(cornerRadius: 18)

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "TYPE")
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                            ForEach(ScheduleKind.allCases, id: \.self) { itemKind in
                                Button {
                                    kind = itemKind
                                } label: {
                                    Text(itemKind.rawValue)
                                        .font(.caption.weight(.black))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 9)
                                        .background(kind == itemKind ? kindColor(itemKind) : Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                                        .foregroundStyle(kind == itemKind ? .white : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .appPanel(cornerRadius: 18)

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "DETAIL")
                        ScheduleEditorField(title: "일정명", text: $title, placeholder: "예: 리쓰린 공원")
                        ScheduleEditorField(title: "장소명", text: $placeName, placeholder: "예: Ritsurin Garden")
                        ScheduleEditorField(title: "지도 메모", text: $sourceMapNote, placeholder: "My Maps/지도에서 가져온 메모")
                    }
                    .appPanel(cornerRadius: 18)

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "MEMO")
                        TextField("앱에서 추가로 적어둘 메모", text: $note, axis: .vertical)
                            .lineLimit(4...8)
                            .textFieldStyle(.roundedBorder)
                    }
                    .appPanel(cornerRadius: 18)
                }
                .readableWidth(620)
                .padding()
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear(perform: loadItem)
        }
    }

    private func loadItem() {
        guard !didLoad else { return }
        didLoad = true
        guard let existingItem else {
            date = defaultDate
            return
        }
        date = existingItem.date
        startTime = existingItem.startTime
        endTime = existingItem.endTime
        title = existingItem.title
        placeName = existingItem.placeName
        sourceMapNote = existingItem.sourceMapNote
        note = existingItem.note
        kind = existingItem.kind
    }

    private func save() {
        if let existingItem {
            store.updateScheduleItem(
                existingItem,
                date: date,
                startTime: startTime,
                endTime: endTime,
                title: title,
                note: note,
                placeName: placeName,
                sourceMapNote: sourceMapNote,
                kind: kind
            )
        } else {
            store.addScheduleItem(
                date: date,
                startTime: startTime,
                endTime: endTime,
                title: title,
                note: note,
                placeName: placeName,
                sourceMapNote: sourceMapNote,
                kind: kind
            )
        }
        dismiss()
    }

    private func kindColor(_ itemKind: ScheduleKind) -> Color {
        switch itemKind {
        case .move: return .blue
        case .food: return .orange
        case .flight: return .purple
        case .place: return theme.accent
        }
    }
}

private struct ScheduleEditorField: View {
    var title: String
    @Binding var text: String
    var placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}
