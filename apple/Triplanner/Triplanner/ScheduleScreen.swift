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
                VStack(alignment: .leading, spacing: 24) {
                    ScreenHeader(title: scheduleTitle, subtitle: scheduleSubtitle)

                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Text("날짜 선택")
                                .font(.system(size: 27, weight: .black, design: .rounded))
                            Spacer()
                            Text(selectedDate.map(compactDayLabel) ?? "전체")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(theme.accent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 9)
                                .background(theme.accent.opacity(0.10), in: Capsule())
                        }
                        filterBar

                        ScheduleModeSwitch(viewMode: $viewMode)

                        if !dates.isEmpty && viewMode == .timeline {
                            calendarPreview
                        }
                    }
                    .appPanel(cornerRadius: 20)

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
                .readableWidth(1280)
                .padding(28)
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
            HStack(spacing: 12) {
                dayFilterButton(title: "전체", subtitle: "\(store.scheduleItemsForSelectedCity().count)개", isSelected: selectedDate == nil) {
                    selectedDate = nil
                }
                ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                    dayFilterButton(
                        title: "Day \(index + 1)",
                        subtitle: "\(compactDayLabel(date)) · \(items(on: date).count)개",
                        isSelected: selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
                    ) {
                        selectedDate = date
                    }
                }
            }
            .padding(8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.primary.opacity(0.055))
            }
        }
    }

    private func dayFilterButton(title: String, subtitle: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .center, spacing: 8) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .black))
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 25, weight: .black, design: .rounded))
                        Text(subtitle)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(isSelected ? .white.opacity(0.86) : .secondary)
                            .lineLimit(1)
                    }
                }

                Capsule()
                    .fill(isSelected ? .white.opacity(0.95) : theme.accent.opacity(0.18))
                    .frame(width: isSelected ? 54 : 28, height: 5)
            }
            .frame(width: title == "전체" ? 150 : 198, alignment: .leading)
            .frame(minHeight: 92, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(isSelected ? theme.accent : Color.secondary.opacity(0.045), in: RoundedRectangle(cornerRadius: 20))
            .foregroundStyle(isSelected ? .white : .primary)
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? theme.accent.opacity(0.56) : Color.secondary.opacity(0.13), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var calendarPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("캘린더 미리보기")
                    .font(.title3.weight(.black))
                Spacer()
                Button {
                    viewMode = .calendar
                } label: {
                    Label("캘린더 보기", systemImage: "calendar")
                        .font(.headline.weight(.black))
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.accent)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 154), spacing: 12)], spacing: 12) {
                ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                    let isSelected = selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
                    Button {
                        selectedDate = date
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Day \(index + 1)")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                            Text(compactDayLabel(date))
                                .font(.system(size: 24, weight: .black, design: .rounded))
                        }
                        .frame(maxWidth: .infinity, minHeight: 78, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(isSelected ? theme.accent : Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(isSelected ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.055))
        }
    }

    private var calendarGrid: some View {
        VStack(alignment: .leading, spacing: 18) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 12) {
                    calendarHeaderCopy
                    Spacer(minLength: 12)
                    calendarHeaderActions
                }

                VStack(alignment: .leading, spacing: 10) {
                    calendarHeaderCopy
                    calendarHeaderActions
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(title: "날짜")

                HStack(spacing: 0) {
                    ForEach(weekdayLabels, id: \.self) { label in
                        Text(label)
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.primary.opacity(0.045))
                }

                LazyVGrid(columns: calendarColumns, spacing: 0) {
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
                                itemTitles: Array(dayItems.prefix(2).map(\.title)),
                                itemCount: dayItems.count,
                                isTripDay: isTripDay,
                                isSelected: isSelected,
                                isToday: Calendar.current.isDateInToday(date)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!isTripDay)
                    }
                }
                .background(.background.opacity(0.64), in: RoundedRectangle(cornerRadius: 18))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.primary.opacity(0.065), lineWidth: 0.75)
                }
            }
            .padding(.top, 2)

            calendarDetailPanels
        }
        .appPanel(cornerRadius: 20)
    }

    private var calendarHeaderCopy: some View {
        VStack(alignment: .leading, spacing: 3) {
            SectionLabel(title: "캘린더")
            Text(calendarTitle)
                .font(.system(size: 32, weight: .black, design: .rounded))
            Text(selectedDate.map { "\(compactDayLabel($0)) 선택됨" } ?? "전체 날짜를 한 번에 보는 중")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var calendarHeaderActions: some View {
        HStack(spacing: 7) {
            Button {
                selectedDate = nil
            } label: {
                CalendarHeaderButtonLabel(title: "전체", iconName: "square.grid.2x2", tint: selectedDate == nil ? .secondary : theme.accent)
            }
            .buttonStyle(.plain)
            .disabled(selectedDate == nil)

            Button {
                openScheduleEditor(for: selectedDate ?? dates.first ?? Date())
            } label: {
                CalendarHeaderButtonLabel(title: "추가", iconName: "plus", tint: theme.accent)
            }
            .buttonStyle(.plain)

            Button {
                selectedDate = nil
                viewMode = .timeline
            } label: {
                CalendarHeaderButtonLabel(title: "타임라인", iconName: "list.bullet", tint: theme.accent)
            }
            .buttonStyle(.plain)
        }
    }

    private var calendarDetailPanels: some View {
        Group {
            if selectedDate == nil {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        calendarTimeGridPanel
                            .frame(minWidth: 560)
                        calendarAgendaPanel
                            .frame(width: 350)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        calendarTimeGridPanel
                        calendarAgendaPanel
                    }
                }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        calendarTimeGridPanel
                            .frame(minWidth: 460)
                        calendarAgendaPanel
                            .frame(width: 340)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        calendarTimeGridPanel
                        calendarAgendaPanel
                    }
                }
            }
        }
    }

    private var calendarTimeGridPanel: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                SectionLabel(title: selectedDate == nil && dates.count > 1 ? "시간표" : "하루 시간표")
                Spacer()
                Text(selectedDate.map(compactDayLabel) ?? "전체 날짜")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.secondary.opacity(0.10), in: Capsule())
            }

            if selectedDate == nil && dates.count > 1 {
                MultiDayCalendarGrid(dates: dates, itemsForDate: items(on:))
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
    }

    private var calendarAgendaPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionLabel(title: selectedDate.map { compactDayLabel($0) } ?? "전체 일정")
                Spacer()
                if selectedDate != nil {
                    Button {
                        selectedDate = nil
                    } label: {
                        Label("전체", systemImage: "xmark")
                            .font(.caption.weight(.black))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }

            let agendaItems = selectedDate.map { items(on: $0) } ?? allVisibleItemsSorted
            if agendaItems.isEmpty {
                Text("이 날짜에는 일정이 없습니다.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    .padding(.horizontal, 12)
                    .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 9) {
                    ForEach(agendaItems.prefix(selectedDate == nil ? 8 : 5)) { item in
                        CalendarAgendaRow(item: item)
                    }
                    if agendaItems.count > (selectedDate == nil ? 8 : 5) {
                        Text("+ \(agendaItems.count - (selectedDate == nil ? 8 : 5))개 더 있음")
                            .font(.caption.weight(.black))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 2)
                    }
                }
            }
        }
        .padding(14)
        .background(.background.opacity(0.66), in: RoundedRectangle(cornerRadius: 17))
        .overlay {
            RoundedRectangle(cornerRadius: 17)
                .stroke(.quaternary)
        }
    }

    private var calendarFocusDate: Date? {
        selectedDate ?? timelineDates.first ?? dates.first
    }

    private var timelineList: some View {
        VStack(alignment: .leading, spacing: 12) {
            if selectedDate == nil {
                ForEach(timelineDates, id: \.self) { date in
                    timelineSection(date: date, items: items(on: date))
                }
            } else {
                timelineSection(date: selectedDate ?? Date(), items: visibleItems)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
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
        Array(repeating: GridItem(.flexible(minimum: 54), spacing: 0), count: 7)
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
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .center, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(dayTitle(for: date))
                        .font(.system(size: 31, weight: .black, design: .rounded))
                    Text(compactDayLabel(date))
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(items.count)")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.secondary.opacity(0.10), in: Capsule())
                Button {
                    openScheduleEditor(for: date)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 19, weight: .black))
                        .frame(width: 40, height: 40)
                        .background(theme.accent.opacity(0.13), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(theme.accent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(dayTitle(for: date)) 일정 추가")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(.background.opacity(0.48), in: RoundedRectangle(cornerRadius: 17))
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

    var title: String {
        switch self {
        case .timeline: return "타임라인"
        case .calendar: return "캘린더"
        }
    }

    var iconName: String {
        switch self {
        case .timeline: return "list.bullet.rectangle"
        case .calendar: return "calendar"
        }
    }
}

private struct ScheduleModeSwitch: View {
    @Environment(\.appTheme) private var theme
    @Binding var viewMode: ScheduleViewMode

    var body: some View {
        HStack(spacing: 8) {
            modeButton(.timeline)
            modeButton(.calendar)
        }
        .padding(5)
        .background(.secondary.opacity(0.075), in: RoundedRectangle(cornerRadius: 17))
        .overlay {
            RoundedRectangle(cornerRadius: 17)
                .stroke(Color.primary.opacity(0.045))
        }
    }

    private func modeButton(_ mode: ScheduleViewMode) -> some View {
        let isSelected = viewMode == mode
        return Button {
            viewMode = mode
        } label: {
            Label(mode.title, systemImage: mode.iconName)
                .font(.headline.weight(.black))
                .frame(maxWidth: .infinity, minHeight: 48)
                .foregroundStyle(isSelected ? .white : .primary)
                .background(isSelected ? theme.accent : Color.clear, in: RoundedRectangle(cornerRadius: 15))
                .overlay {
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isSelected ? theme.accent.opacity(0.38) : Color.secondary.opacity(0.10))
                }
        }
        .buttonStyle(.plain)
    }
}

private struct CalendarHeaderButtonLabel: View {
    var title: String
    var iconName: String
    var tint: Color

    var body: some View {
        Label(title, systemImage: iconName)
            .font(.system(size: 18, weight: .black, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(tint.opacity(0.11), in: Capsule())
            .foregroundStyle(tint)
    }
}

private struct MultiDayCalendarGrid: View {
    @Environment(\.appTheme) private var theme
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
                    Text("현지")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 78, alignment: .trailing)
                        .padding(.trailing, 16)
                    ForEach(dates, id: \.self) { date in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(shortWeekday(date))
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .foregroundStyle(.secondary)
                            Text(compactDate(date))
                                .font(.system(size: 29, weight: .black, design: .rounded))
                        }
                        .frame(width: 260, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(theme.accent.opacity(0.055))
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.12))
                                .frame(width: 0.5)
                        }
                    }
                }

                Divider().opacity(0.45)

                ForEach(displayHours, id: \.self) { hour in
                    let hourHeight = rowHeight(forHour: hour)
                    HStack(alignment: .top, spacing: 0) {
                        Text("\(hour):00")
                            .font(.system(size: 17, weight: .black, design: .rounded).monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 78, alignment: .trailing)
                            .padding(.trailing, 16)
                            .padding(.top, 12)

                        ForEach(dates, id: \.self) { date in
                            let items = items(on: date, at: hour)
                            MultiDayHourCell(items: items, rowHeight: hourHeight)
                        }
                    }
                    .background(hour.isMultiple(of: 2) ? Color.primary.opacity(0.012) : Color.clear)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.085))
                            .frame(height: 0.5)
                    }
                }
            }
            .frame(minWidth: CGFloat(max(dates.count, 1)) * 280 + 78, alignment: .leading)
        }
        .background(.background.opacity(0.64), in: RoundedRectangle(cornerRadius: 17))
        .overlay {
            RoundedRectangle(cornerRadius: 17)
                .stroke(.quaternary)
        }
    }

    private func rowHeight(forHour hour: Int) -> CGFloat {
        let maxItems = dates
            .map { items(on: $0, at: hour).count }
            .max() ?? 0
        return maxItems == 0 ? 82 : CGFloat(maxItems) * 104 + 22
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
    var rowHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if items.isEmpty {
                Rectangle()
                    .fill(Color.secondary.opacity(0.045))
                    .frame(height: 1)
                    .padding(.top, 16)
            } else {
                ForEach(items) { item in
                    CalendarTimeBlock(item: item)
                }
                .padding(.vertical, 4)
            }
        }
        .frame(width: 260, alignment: .topLeading)
        .frame(height: rowHeight, alignment: .topLeading)
        .padding(.horizontal, 12)
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
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayLabel)
                        .font(.system(size: 29, weight: .black, design: .rounded))
                    Text(compactDate)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(items.count)개")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(theme.accent.opacity(0.10), in: Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(theme.accent.opacity(0.055))

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
        .background(.background.opacity(0.64), in: RoundedRectangle(cornerRadius: 17))
        .overlay {
            RoundedRectangle(cornerRadius: 17)
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
        HStack(alignment: .top, spacing: 18) {
            Text(hourLabel)
                .font(.system(size: 18, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 78, alignment: .trailing)
                .padding(.top, 16)

            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(Color.secondary.opacity(isLast ? 0.055 : 0.10))
                    .frame(height: 0.7)
                    .padding(.bottom, items.isEmpty ? 0 : 5)

                if items.isEmpty {
                    Spacer(minLength: 0)
                } else {
                    ForEach(items) { item in
                        CalendarTimeBlock(item: item)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: rowHeight, alignment: .topLeading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
    }

    private var rowHeight: CGFloat {
        items.isEmpty ? 78 : CGFloat(max(1, items.count)) * 106 + 20
    }

    private var hourLabel: String {
        "\(hour):00"
    }
}

private struct CalendarTimeBlock: View {
    @Environment(\.appTheme) private var theme
    var item: ScheduleItem

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .center, spacing: 8) {
                Text(timeText)
                    .font(.system(size: 18, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(tint)
                    .lineLimit(1)

                Text(item.kind.rawValue)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tint.opacity(0.12), in: Capsule())

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 23, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if !item.placeName.isEmpty {
                    Label(item.placeName, systemImage: "mappin")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .minimumScaleFactor(0.88)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .background(tint.opacity(0.055), in: RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(tint)
                .frame(width: 4)
                .padding(.vertical, 10)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(tint.opacity(0.16))
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
        HStack(spacing: 12) {
            Text(item.startTime.isEmpty ? item.kind.rawValue : item.startTime)
                .font(.system(size: 18, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(kindColor)
                .frame(width: 72, alignment: .trailing)

            Circle()
                .fill(kindColor)
                .frame(width: 7, height: 7)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .lineLimit(1)
                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .center)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(kindColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
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

private struct CalendarDayCell: View {
    @Environment(\.appTheme) private var theme
    var dayNumber: String
    var dayLabel: String?
    var itemTitles: [String]
    var itemCount: Int
    var isTripDay: Bool
    var isSelected: Bool
    var isToday: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 5) {
                Text(dayNumber)
                    .font(.system(size: 22, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(dayNumberForeground)
                    .frame(width: 40, height: 40)
                    .background(dayNumberBackground, in: RoundedRectangle(cornerRadius: 12))
                Spacer(minLength: 4)
                if itemCount > 0 {
                    Label("\(itemCount)", systemImage: "list.bullet")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(counterBackground, in: Capsule())
                        .foregroundStyle(counterForeground)
                }
            }

            if let dayLabel {
                Text(dayLabel)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(dayLabelForeground)
                    .lineLimit(1)
            } else {
                Text(" ")
                    .font(.caption2.weight(.black))
            }

            if isTripDay && !itemTitles.isEmpty {
                VStack(spacing: 3) {
                    ForEach(itemTitles, id: \.self) { title in
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(eventDotColor)
                                .frame(width: 4, height: 14)
                            Text(title)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .minimumScaleFactor(0.86)
                                .foregroundStyle(secondaryForeground)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 5)
                        .background(eventBackground, in: RoundedRectangle(cornerRadius: 9))
                    }
                }
            } else {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 156, maxHeight: 156, alignment: .topLeading)
        .padding(14)
        .background(cellBackground)
        .overlay {
            Rectangle()
                .stroke(borderColor, lineWidth: isSelected ? 1.4 : 0.7)
        }
        .overlay(alignment: .leading) {
            if isSelected {
                Rectangle()
                    .fill(theme.accent)
                    .frame(width: 3)
            }
        }
        .opacity(isTripDay ? 1 : 0.36)
    }

    private var cellBackground: Color {
        if isSelected { return theme.accent.opacity(0.12) }
        if isToday { return theme.secondaryAccent.opacity(0.08) }
        return isTripDay ? Color.primary.opacity(0.012) : Color.clear
    }

    private var borderColor: Color {
        if isSelected { return theme.accent.opacity(0.62) }
        if isToday { return theme.secondaryAccent.opacity(0.42) }
        return isTripDay ? Color.primary.opacity(0.070) : Color.primary.opacity(0.040)
    }

    private var primaryForeground: Color {
        isTripDay ? .primary : .secondary
    }

    private var dayNumberForeground: Color {
        isSelected ? .white : primaryForeground
    }

    private var dayNumberBackground: Color {
        if isSelected { return theme.accent }
        if isToday { return theme.secondaryAccent.opacity(0.14) }
        return .clear
    }

    private var secondaryForeground: Color {
        isSelected ? .primary : .secondary
    }

    private var dayLabelForeground: Color {
        isSelected ? theme.accent : (isTripDay ? .secondary : .secondary)
    }

    private var counterBackground: Color {
        isSelected ? theme.accent.opacity(0.18) : .secondary.opacity(0.12)
    }

    private var counterForeground: Color {
        isSelected ? theme.accent : .secondary
    }

    private var eventBackground: Color {
        isSelected ? theme.accent.opacity(0.13) : theme.accent.opacity(0.075)
    }

    private var eventDotColor: Color {
        isSelected ? theme.accent : theme.secondaryAccent
    }
}

struct ScheduleRow: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.appTheme) private var theme
    var item: ScheduleItem
    var isLast = false
    @State private var isEditing = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.startTime.isEmpty ? item.kind.rawValue : item.startTime)
                    .font(.system(size: 18, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(kindColor)
                    .lineLimit(1)
                if !item.endTime.isEmpty {
                    Text(item.endTime)
                        .font(.system(size: 15, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 72)
            .padding(.top, 10)

            ZStack(alignment: .top) {
                if !isLast {
                    Rectangle()
                        .fill(kindColor.opacity(0.20))
                        .frame(width: 2.5, height: 104)
                        .padding(.top, 31)
                }
                Image(systemName: kindIcon)
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(kindColor, in: Circle())
                    .shadow(color: kindColor.opacity(0.22), radius: 6, x: 0, y: 3)
            }
            .frame(width: 34)
            .frame(minHeight: 102, alignment: .top)

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 6) {
                            Text(item.kind.rawValue)
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(kindColor.opacity(0.12), in: Capsule())
                                .foregroundStyle(kindColor)
                            if !item.placeName.isEmpty {
                                Text(item.placeName)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Text(item.title)
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 4)
                    Button {
                        isEditing = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 17, weight: .black))
                            .frame(width: 38, height: 38)
                            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("일정 수정")
                }
                if !item.sourceMapNote.isEmpty {
                    Label(item.sourceMapNote, systemImage: "mappin.and.ellipse")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(kindColor)
                        .lineLimit(1)
                }
                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 16)
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
                RoundedRectangle(cornerRadius: 16)
                    .stroke(kindColor.opacity(item.kind == .move || item.kind == .flight ? 0.16 : 0.04))
            }
        }
        .padding(.vertical, 7)
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
