import SwiftUI

struct ScheduleScreen: View {
    @EnvironmentObject private var store: TripStore
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

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "DAYS")
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
            .navigationTitle("일정")
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
        store.currentCity.isEmpty ? "Schedule" : "\(displayCity(store.currentCity)) Schedule"
    }

    private var scheduleSubtitle: String {
        if let selectedDate {
            return "\(compactDayLabel(selectedDate)) · \(visibleItems.count)개 일정"
        }
        return "전체 \(dates.count)일 · \(visibleItems.count)개 일정"
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
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(isSelected ? Color.teal : Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
            .foregroundStyle(isSelected ? .white : .primary)
            .overlay {
                RoundedRectangle(cornerRadius: 13)
                    .stroke(isSelected ? Color.teal.opacity(0.45) : Color.secondary.opacity(0.14), lineWidth: isSelected ? 1.5 : 1)
            }
            .shadow(color: isSelected ? Color.teal.opacity(0.18) : .clear, radius: 8, x: 0, y: 4)
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
                .foregroundStyle(.teal)
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
                        .background(isSelected ? Color.blue : Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
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
                    Label("전체", systemImage: "list.bullet")
                        .font(.caption.weight(.black))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.teal)
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
                        viewMode = .timeline
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
        }
        .appPanel(cornerRadius: 18)
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
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(.quaternary)
        }
    }

    private var timelineDates: [Date] {
        dates.filter { !items(on: $0).isEmpty }
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
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayTitle(for: date))
                        .font(.headline.weight(.black))
                    Text(compactDayLabel(date))
                        .font(.caption.weight(.bold))
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
                        .background(.teal.opacity(0.13), in: RoundedRectangle(cornerRadius: 9))
                        .foregroundStyle(.teal)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(dayTitle(for: date)) 일정 추가")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.background.opacity(0.55), in: RoundedRectangle(cornerRadius: 14))
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.teal)
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
        store.scheduleItemsForSelectedCity().filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
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

private struct CalendarDayCell: View {
    var dayNumber: String
    var dayLabel: String?
    var firstItemTitle: String?
    var itemCount: Int
    var isTripDay: Bool
    var isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(dayNumber)
                    .font(.title3.weight(.black).monospacedDigit())
                    .foregroundStyle(primaryForeground)
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
                    .fixedSize(horizontal: false, vertical: true)
            } else if isTripDay {
                Text("일정 없음")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(secondaryForeground)
                    .lineLimit(1)
            } else {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
        .padding(9)
        .background(cellBackground, in: RoundedRectangle(cornerRadius: 13))
        .overlay {
            RoundedRectangle(cornerRadius: 13)
                .stroke(borderColor, lineWidth: isSelected ? 1.5 : 1)
        }
        .opacity(isTripDay ? 1 : 0.36)
    }

    private var cellBackground: Color {
        if isSelected { return .teal }
        return isTripDay ? Color.secondary.opacity(0.065) : Color.secondary.opacity(0.035)
    }

    private var borderColor: Color {
        if isSelected { return Color.teal.opacity(0.36) }
        return isTripDay ? Color.secondary.opacity(0.12) : Color.clear
    }

    private var primaryForeground: Color {
        isSelected ? .white : (isTripDay ? .primary : .secondary)
    }

    private var secondaryForeground: Color {
        isSelected ? .white.opacity(0.78) : .secondary
    }

    private var dayLabelForeground: Color {
        isSelected ? .white.opacity(0.82) : .teal
    }

    private var counterBackground: Color {
        isSelected ? .white.opacity(0.20) : .secondary.opacity(0.12)
    }

    private var counterForeground: Color {
        isSelected ? .white : .secondary
    }
}

struct ScheduleRow: View {
    @EnvironmentObject private var store: TripStore
    var item: ScheduleItem
    var isLast = false
    @State private var isEditing = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
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
            .frame(width: 58)
            .padding(.top, 7)

            ZStack(alignment: .top) {
                if !isLast {
                    Rectangle()
                        .fill(kindColor.opacity(0.24))
                        .frame(width: 2, height: 88)
                        .padding(.top, 26)
                }
                Image(systemName: kindIcon)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(kindColor, in: Circle())
                    .shadow(color: kindColor.opacity(0.22), radius: 6, x: 0, y: 3)
            }
            .frame(width: 24)
            .frame(minHeight: 86, alignment: .top)

            VStack(alignment: .leading, spacing: 8) {
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
                            .frame(width: 26, height: 26)
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
            .padding(.vertical, 9)
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
                    .stroke(kindColor.opacity(item.kind == .move || item.kind == .flight ? 0.16 : 0.08))
            }
        }
        .padding(.vertical, 5)
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
        case .place: return .teal
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
            return Color.secondary.opacity(0.035)
        }
    }
}

struct ScheduleEditorSheet: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.dismiss) private var dismiss

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
            .navigationTitle(existingItem == nil ? "추가" : "수정")
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
        case .place: return .teal
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
