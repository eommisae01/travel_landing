import SwiftUI

struct ScheduleScreen: View {
    @EnvironmentObject private var store: TripStore
    @State private var selectedDate: Date?
    @State private var viewMode: ScheduleViewMode = .timeline
    @State private var isAddingSchedule = false

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

                        HStack(spacing: 8) {
                            modeButton(.timeline, title: "Timeline", iconName: "list.bullet.rectangle")
                            modeButton(.calendar, title: "Calendar View", iconName: "calendar")
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
            VStack(spacing: 0) {
                ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                    ScheduleRow(item: item, isLast: index == visibleItems.count - 1)
                }
            }
            .padding(10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(.quaternary)
            }
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
                        isAddingSchedule = true
                    } label: {
                        Label("일정 추가", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingSchedule) {
                ScheduleEditorSheet(defaultDate: selectedDate ?? dates.first ?? Date())
                    .environmentObject(store)
            }
        }
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
                    let dayItems = items(on: date)
                    dayFilterButton(
                        title: "Day \(index + 1) (\(compactDayLabel(date)))",
                        subtitle: "\(dayItems.count)개 일정",
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
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.black))
                Text(subtitle)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isSelected ? .white.opacity(0.82) : .secondary)
            }
            .frame(width: title == "전체" ? 96 : 142, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(isSelected ? Color.blue : Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(isSelected ? .white : .primary)
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.blue.opacity(0.45) : Color.secondary.opacity(0.14), lineWidth: isSelected ? 1.5 : 1)
            }
            .shadow(color: isSelected ? Color.blue.opacity(0.18) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func modeButton(_ mode: ScheduleViewMode, title: String, iconName: String) -> some View {
        let isSelected = viewMode == mode
        return Button {
            viewMode = mode
        } label: {
            Label(title, systemImage: iconName)
                .font(.caption.weight(.black))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.teal : Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private var calendarGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionLabel(title: "CALENDAR")
                Spacer()
                Text("날짜를 누르면 해당 Day 타임라인으로 이동")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 154), spacing: 10)], spacing: 10) {
                ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                    let dayItems = items(on: date)
                    let isSelected = selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
                    Button {
                        selectedDate = date
                        viewMode = .timeline
                    } label: {
                        VStack(alignment: .leading, spacing: 9) {
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

                            Text(isSelected ? "선택됨" : "탭해서 타임라인 보기")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(isSelected ? .white.opacity(0.75) : .secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
                        .padding(11)
                        .background(isSelected ? Color.blue : Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(isSelected ? .white : .primary)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isSelected ? Color.blue.opacity(0.3) : Color.secondary.opacity(0.12))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .appPanel(cornerRadius: 18)
    }

    private func items(on date: Date) -> [ScheduleItem] {
        store.scheduleItemsForSelectedCity().filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
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
    @EnvironmentObject private var store: TripStore
    var item: ScheduleItem
    var isLast = false
    @State private var isEditing = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .center, spacing: 5) {
                Text(item.startTime.isEmpty ? item.kind.rawValue : item.startTime)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if !item.endTime.isEmpty {
                    Text(item.endTime)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 54)
            .padding(.vertical, 8)
            .background(.background.opacity(0.70), in: RoundedRectangle(cornerRadius: 13))
            .overlay {
                RoundedRectangle(cornerRadius: 13)
                    .stroke(kindColor.opacity(0.18))
            }

            ZStack(alignment: .top) {
                if !isLast {
                    Rectangle()
                        .fill(kindColor.opacity(0.22))
                        .frame(width: 2, height: 118)
                        .padding(.top, 25)
                }
                Image(systemName: kindIcon)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(kindColor, in: Circle())
                    .shadow(color: kindColor.opacity(0.22), radius: 6, x: 0, y: 3)
            }
            .frame(minHeight: 96, alignment: .top)
            .frame(width: 26)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(item.kind.rawValue)
                                .font(.caption2.weight(.black))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(kindColor.opacity(0.13), in: Capsule())
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
                            .frame(width: 30, height: 30)
                            .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
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
            .padding(12)
            .background(kindColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(kindColor.opacity(0.12))
            }
        }
        .padding(.vertical, 6)
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
