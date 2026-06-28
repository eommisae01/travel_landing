import Combine
import Foundation

@MainActor
final class TripStore: ObservableObject {
    struct Snapshot: Codable {
        var trip: Trip?
        var selectedCity: String?
        var members: [TripMember]
        var scheduleItems: [ScheduleItem]
        var places: [PlaceCandidate]
        var notes: [NoteGroup]
        var checklist: [ChecklistItem]
        var expenses: [ExpenseItem]
    }

    private let storageKey = "travelplanner.snapshot.v3"

    @Published var trip: Trip?
    @Published var selectedCity = ""
    @Published var members: [TripMember] = []
    @Published var scheduleItems: [ScheduleItem] = []
    @Published var places: [PlaceCandidate] = []
    @Published var notes: [NoteGroup] = []
    @Published var checklist: [ChecklistItem] = []
    @Published var expenses: [ExpenseItem] = []

    var hasTrip: Bool {
        trip != nil
    }

    init() {
        if !loadSaved() {
            loadDemo()
            save()
        }
    }

    func createTrip(
        country: String,
        destination: String,
        startDate: Date?,
        endDate: Date?,
        flightNumber: String,
        myMapsURL: String
    ) {
        trip = Trip(
            name: "\(destination) 여행",
            country: country,
            cities: [destination],
            startDate: startDate,
            endDate: endDate,
            accommodation: "",
            accommodationAddress: nil,
            myMapsURL: myMapsURL,
            outbound: FlightInfo(flightNumber: flightNumber, origin: "", destination: destination, localDeparture: "", localArrival: ""),
            inbound: FlightInfo(flightNumber: "", origin: destination, destination: "", localDeparture: "", localArrival: ""),
            budgetAmount: 0,
            budgetCurrency: "JPY"
        )
        seedStarterContent(destination: destination)
        save()
    }

    func addCity(_ city: String) {
        guard var current = trip, !city.isEmpty else { return }
        if !current.cities.contains(city) {
            current.cities.append(city)
        }
        trip = current
        selectedCity = city
        save()
    }

    func selectCity(_ city: String) {
        guard !city.isEmpty else { return }
        selectedCity = city
        save()
    }

    func scheduleItemsForSelectedCity() -> [ScheduleItem] {
        scheduleItems
            .filter { isRelevant($0.title + " " + $0.placeName + " " + $0.note + " " + $0.sourceMapNote, to: currentCity) }
            .sorted { lhs, rhs in
                if lhs.date != rhs.date { return lhs.date < rhs.date }
                return lhs.startTime < rhs.startTime
            }
    }

    func placesForSelectedCity() -> [PlaceCandidate] {
        places.filter { isRelevant($0.name + " " + $0.category + " " + $0.mapNote + " " + $0.appNote, to: currentCity) }
    }

    func notesForSelectedCity() -> [NoteGroup] {
        notes.filter { isRelevant($0.title + " " + $0.body, to: currentCity) }
    }

    var currentCity: String {
        if !selectedCity.isEmpty { return selectedCity }
        return trip?.cities.first ?? ""
    }

    func toggleChecklist(_ item: ChecklistItem) {
        guard let index = checklist.firstIndex(of: item) else { return }
        checklist[index].isDone.toggle()
        save()
    }

    func toggleFavorite(_ place: PlaceCandidate) {
        guard let index = places.firstIndex(of: place) else { return }
        places[index].isFavorite.toggle()
        save()
    }

    func addSchedule(from place: PlaceCandidate, date: Date) {
        scheduleItems.append(
            ScheduleItem(
                date: date,
                startTime: "",
                endTime: "",
                title: place.name,
                note: place.appNote,
                placeName: place.name,
                sourceMapNote: place.mapNote,
                kind: place.category.contains("식") || place.category.contains("카페") ? .food : .place
            )
        )
        save()
    }

    func addPlace(name: String, category: String, mapURL: String, mapNote: String, appNote: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        places.append(
            PlaceCandidate(
                name: trimmedName,
                category: category.isEmpty ? "장소" : category,
                mapURL: mapURL,
                mapNote: mapNote,
                appNote: appNote,
                isFavorite: false
            )
        )
        save()
    }

    func addNote(title: String, body: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        notes.insert(NoteGroup(title: trimmedTitle, body: body, imageNames: []), at: 0)
        save()
    }

    func addChecklist(title: String, owner: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        checklist.insert(ChecklistItem(title: trimmedTitle, owner: owner.isEmpty ? "공통" : owner, isDone: false), at: 0)
        save()
    }

    func addExpense(
        category: String,
        title: String,
        amount: Double,
        currency: String,
        paidBy: String,
        intendedPayer: String,
        participants: [String]
    ) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, amount > 0 else { return }
        expenses.insert(
            ExpenseItem(
                category: category.isEmpty ? "기타" : category,
                title: trimmedTitle,
                amount: amount,
                currency: currency.isEmpty ? trip?.budgetCurrency ?? "JPY" : currency,
                paidBy: paidBy.isEmpty ? "미정" : paidBy,
                intendedPayer: intendedPayer.isEmpty ? "미정" : intendedPayer,
                participants: participants.isEmpty ? members.map(\.name) : participants
            ),
            at: 0
        )
        save()
    }

    func updateAccommodation(_ value: String) {
        guard var current = trip else { return }
        current.accommodation = value
        trip = current
        save()
    }

    func updateAccommodationAddress(_ value: String) {
        guard var current = trip else { return }
        current.accommodationAddress = value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : value
        trip = current
        save()
    }

    func updateMyMapsURL(_ value: String) {
        guard var current = trip else { return }
        current.myMapsURL = value
        trip = current
        save()
    }

    func updateOutboundFlight(_ flight: FlightInfo) {
        guard var current = trip else { return }
        current.outbound = flight
        trip = current
        save()
    }

    func updateInboundFlight(_ flight: FlightInfo) {
        guard var current = trip else { return }
        current.inbound = flight
        trip = current
        save()
    }

    func resetDemo() {
        loadDemo()
        save()
    }

    private func loadSaved() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return false }
        do {
            let snapshot = try JSONDecoder().decode(Snapshot.self, from: data)
            trip = snapshot.trip
            selectedCity = snapshot.selectedCity ?? snapshot.trip?.cities.first ?? ""
            members = snapshot.members
            scheduleItems = snapshot.scheduleItems
            places = snapshot.places
            notes = snapshot.notes
            checklist = snapshot.checklist
            expenses = snapshot.expenses
            return snapshot.trip != nil
        } catch {
            return false
        }
    }

    private func save() {
        let snapshot = Snapshot(
            trip: trip,
            selectedCity: selectedCity.isEmpty ? trip?.cities.first : selectedCity,
            members: members,
            scheduleItems: scheduleItems,
            places: places,
            notes: notes,
            checklist: checklist,
            expenses: expenses
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func seedStarterContent(destination: String) {
        members = [
            TripMember(name: "나", tintName: "teal"),
            TripMember(name: "친구", tintName: "coral")
        ]
        scheduleItems = []
        places = [
            PlaceCandidate(name: "\(destination) 숙소", category: "숙소", mapURL: "", mapNote: "직접 입력", appNote: "체크인/짐보관 시간을 넣어두세요.", isFavorite: true)
        ]
        notes = [
            NoteGroup(title: "교통", body: "공항/역/항구 이동 방법, 티켓 사는 곳, 막차 시간을 정리하세요.", imageNames: []),
            NoteGroup(title: "예약", body: "미술관, 레스토랑, 액티비티 예약 시간과 QR 위치를 정리하세요.", imageNames: [])
        ]
        checklist = [
            ChecklistItem(title: "여권", owner: "공통", isDone: false),
            ChecklistItem(title: "항공권 확인", owner: "공통", isDone: false),
            ChecklistItem(title: "숙소 예약 확인", owner: "공통", isDone: false)
        ]
        expenses = []
    }

    private func loadDemo() {
        let demoTrip = Trip(
            name: "Takamatsu",
            country: "일본",
            cities: ["타카마쓰", "나오시마", "도쿄"],
            startDate: Date.from("2026-06-22"),
            endDate: Date.from("2026-06-24"),
            accommodation: "리쓰린코엔 기타구치역 근처 숙소",
            accommodationAddress: "Kagawa, Takamatsu, Ritsurincho area",
            myMapsURL: "https://www.google.com/maps/d/u/0/viewer?mid=1njIQAzxY74XFmaChyqYaY-q7t1KsC-M",
            outbound: FlightInfo(flightNumber: "RS0741", origin: "서울", destination: "타카마쓰", localDeparture: "08:20", localArrival: "10:30"),
            inbound: FlightInfo(flightNumber: "RS0742", origin: "타카마쓰", destination: "서울", localDeparture: "11:40", localArrival: "13:30"),
            budgetAmount: 150000,
            budgetCurrency: "JPY"
        )
        trip = demoTrip
        selectedCity = demoTrip.cities.first ?? ""
        members = [
            TripMember(name: "예지", tintName: "teal"),
            TripMember(name: "승환", tintName: "coral"),
            TripMember(name: "민지", tintName: "yellow")
        ]
        scheduleItems = [
            ScheduleItem(date: Date.from("2026-06-22"), startTime: "10:30", endTime: "12:00", title: "타카마쓰 도착 / 숙소 짐보관", note: "공항에서 무리하지 않고 12:00 짐보관 시간에 맞춰 이동", placeName: "타카마쓰 공항", sourceMapNote: "", kind: .flight),
            ScheduleItem(date: Date.from("2026-06-22"), startTime: "14:00", endTime: "16:00", title: "리쓰린 공원", note: "첫날은 무리하지 않고 산책 중심. 날씨 좋으면 핵심 일정.", placeName: "리쓰린 공원", sourceMapNote: "My Maps 장소", kind: .place),
            ScheduleItem(date: Date.from("2026-06-23"), startTime: "10:14", endTime: "11:04", title: "페리: 타카마쓰항 → 나오시마", note: "성인 편도 520엔, 추천편", placeName: "타카마쓰항", sourceMapNote: "", kind: .move),
            ScheduleItem(date: Date.from("2026-06-23"), startTime: "11:05", endTime: "11:45", title: "미야노우라항 → 츠츠지소 → 지중미술관", note: "2번 정류장으로 이동. 시내버스 100엔 후 베네세 무료 셔틀 환승.", placeName: "미야노우라항 2번 정류장", sourceMapNote: "버스 대기 시간이 핵심", kind: .move),
            ScheduleItem(date: Date.from("2026-06-23"), startTime: "12:00", endTime: "13:30", title: "지중미술관 예약", note: "성인 3명, 각 ¥2,500", placeName: "지중미술관", sourceMapNote: "My Maps에서 가져온 장소", kind: .place),
            ScheduleItem(date: Date.from("2026-06-25"), startTime: "09:30", endTime: "11:00", title: "도쿄역 주변 산책", note: "가상 도쿄 일정. 도시 드롭다운 전환 확인용.", placeName: "도쿄역", sourceMapNote: "테스트 데이터", kind: .place),
            ScheduleItem(date: Date.from("2026-06-25"), startTime: "12:00", endTime: "13:00", title: "긴자 점심 후보", note: "식당 후보에서 확정 예정.", placeName: "긴자", sourceMapNote: "테스트 데이터", kind: .food),
            ScheduleItem(date: Date.from("2026-06-25"), startTime: "15:00", endTime: "17:00", title: "시부야 이동", note: "패드 가로 화면 확인용 이동 일정.", placeName: "시부야", sourceMapNote: "테스트 데이터", kind: .move)
        ]
        places = [
            PlaceCandidate(name: "지중미술관", category: "미술관", mapURL: "https://www.google.com/maps/search/?api=1&query=Chichu%20Art%20Museum", mapNote: "예약 필요", appNote: "12:00 예약 완료", isFavorite: true),
            PlaceCandidate(name: "나오시마 커피", category: "카페", mapURL: "https://www.google.com/maps/search/?api=1&query=Naoshima%20coffee", mapNote: "항구 근처", appNote: "버스 대기 시간이 길면 들를 후보", isFavorite: false),
            PlaceCandidate(name: "미야노우라항 2번 버스정류장", category: "환승", mapURL: "https://www.google.com/maps/search/?api=1&query=Miyanoura%20Port%20Naoshima", mapNote: "츠츠지소행 100엔 버스", appNote: "페리 하차 후 바로 이동", isFavorite: true),
            PlaceCandidate(name: "츠츠지소", category: "환승", mapURL: "https://www.google.com/maps/search/?api=1&query=Tsutsuji-so%20Naoshima", mapNote: "베네세 무료 셔틀 환승", appNote: "셔틀 놓치면 대기 길어짐", isFavorite: true),
            PlaceCandidate(name: "이우환 미술관", category: "미술관", mapURL: "https://www.google.com/maps/search/?api=1&query=Lee%20Ufan%20Museum", mapNote: "10:00-17:00", appNote: "관람 약 50분", isFavorite: false),
            PlaceCandidate(name: "베네세 하우스 뮤지엄", category: "미술관", mapURL: "https://www.google.com/maps/search/?api=1&query=Benesse%20House%20Museum", mapNote: "08:00-21:00", appNote: "관람 1시간 30분 후보", isFavorite: false),
            PlaceCandidate(name: "우동 바카이치다이", category: "우동", mapURL: "https://www.google.com/maps/search/?api=1&query=Udon%20Bakaichidai%20Takamatsu", mapNote: "My Maps 식당", appNote: "오픈런 후보", isFavorite: true),
            PlaceCandidate(name: "호네츠키도리 잇카쿠", category: "식당", mapURL: "https://www.google.com/maps/search/?api=1&query=Ikkaku%20Takamatsu", mapNote: "My Maps 식당", appNote: "저녁 후보", isFavorite: false),
            PlaceCandidate(name: "As canele &. 瓦町店", category: "디저트", mapURL: "https://www.google.com/maps/search/?api=1&query=As%20canele%20Takamatsu", mapNote: "까눌레", appNote: "간식 후보", isFavorite: false),
            PlaceCandidate(name: "도쿄역", category: "도쿄 · 장소", mapURL: "https://www.google.com/maps/search/?api=1&query=Tokyo%20Station", mapNote: "가상 도쿄 여행", appNote: "도시 전환 확인용 출발점", isFavorite: true),
            PlaceCandidate(name: "긴자 식당 후보", category: "도쿄 · 식당", mapURL: "https://www.google.com/maps/search/?api=1&query=Ginza%20restaurant", mapNote: "가상 도쿄 여행", appNote: "점심 후보", isFavorite: false),
            PlaceCandidate(name: "시부야 스카이", category: "도쿄 · 전망", mapURL: "https://www.google.com/maps/search/?api=1&query=Shibuya%20Sky", mapNote: "가상 도쿄 여행", appNote: "저녁 전후 후보", isFavorite: false)
        ]
        notes = [
            NoteGroup(title: "페리시간표", body: "다카마쓰 → 나오시마: 10:14 → 11:04 추천.\n나오시마 → 다카마쓰: 17:00 → 17:50 추천.\n페리 약 50분, 성인 편도 520엔. 고속선은 약 30분, 성인 1,220엔.", imageNames: []),
            NoteGroup(title: "나오시마 버스", body: "미야노우라항 2번 정류장 → 츠츠지소. 시내버스 100엔, 하차할 때 지불.\n츠츠지소에서 베네세 구역 무료 셔틀버스 탑승.\n버스 기다리는 시간과의 싸움이라 페리 도착 후 바로 정류장으로 이동.", imageNames: []),
            NoteGroup(title: "미술관 운영시간", body: "지중미술관: 10:00-17:00, 예약 필요.\n이우환 미술관: 10:00-17:00.\n베네세 하우스 뮤지엄: 08:00-21:00.\nValley Gallery: 09:30-16:00.", imageNames: []),
            NoteGroup(title: "공항 환전/ATM", body: "타카마쓰 공항 국제선 쪽 114Bank Money Exchange와 은행 ATM 위치 확인. 사진 기준 9:00-21:00. 트래블카드 출금/환전 확인.", imageNames: []),
            NoteGroup(title: "도쿄 테스트 Notes", body: "도쿄 도시 드롭다운을 눌렀을 때 홈의 TODAY NOTES가 바뀌는지 확인하기 위한 가상 자료입니다.", imageNames: [])
        ]
        checklist = [
            ChecklistItem(title: "여권", owner: "공통", isDone: false),
            ChecklistItem(title: "지중미술관 QR", owner: "예지", isDone: true),
            ChecklistItem(title: "eSIM / 로밍", owner: "민지", isDone: false),
            ChecklistItem(title: "항공권 확인", owner: "공통", isDone: false),
            ChecklistItem(title: "호텔 예약 확인", owner: "공통", isDone: false),
            ChecklistItem(title: "페리 시간표 저장", owner: "예지", isDone: true),
            ChecklistItem(title: "공항 리무진버스 확인", owner: "승환", isDone: false),
            ChecklistItem(title: "보조배터리", owner: "민지", isDone: false)
        ]
        expenses = [
            ExpenseItem(category: "입장권", title: "지중미술관", amount: 7500, currency: "JPY", paidBy: "예지", intendedPayer: "예지", participants: ["예지", "승환", "민지"]),
            ExpenseItem(category: "교통", title: "나오시마 왕복 페리 예상", amount: 3120, currency: "JPY", paidBy: "예지", intendedPayer: "예지", participants: ["예지", "승환", "민지"])
        ]
    }

    private func isRelevant(_ text: String, to city: String) -> Bool {
        if city == "도쿄" {
            return text.contains("도쿄") || text.contains("긴자") || text.contains("시부야")
        }
        if city == "나오시마" {
            return text.contains("나오시마") || text.contains("지중") || text.contains("미야노우라") || text.contains("츠츠지소") || text.contains("베네세") || text.contains("이우환")
        }
        return !text.contains("도쿄") && !text.contains("긴자") && !text.contains("시부야")
    }
}
