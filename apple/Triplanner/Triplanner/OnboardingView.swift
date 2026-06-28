import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: TripStore
    @State private var country = "일본"
    @State private var cityPreset = "도쿄"
    @State private var customCity = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var useDates = false
    @State private var flightNumber = ""
    @State private var myMapsURL = ""

    private let countries = ["일본", "한국", "대만", "태국", "프랑스", "이탈리아", "미국", "기타"]
    private let cities = ["도쿄", "오사카", "후쿠오카", "삿포로", "교토", "타카마쓰", "기타"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Destination") {
                    Picker("국가", selection: $country) {
                        ForEach(countries, id: \.self) { Text($0) }
                    }
                    Picker("도시", selection: $cityPreset) {
                        ForEach(cities, id: \.self) { Text($0) }
                    }
                    if cityPreset == "기타" {
                        TextField("도시 직접 입력", text: $customCity)
                    }
                }

                Section("기간") {
                    Toggle("기간 입력", isOn: $useDates)
                    if useDates {
                        DatePicker("시작", selection: $startDate, displayedComponents: .date)
                        DatePicker("종료", selection: $endDate, displayedComponents: .date)
                    }
                }

                Section("비행편") {
                    TextField("편명", text: $flightNumber)
                }

                Section("Google My Maps") {
                    TextField("공유 지도 링크", text: $myMapsURL)
                }
            }
            .navigationTitle("새 여행 만들기")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("시작") {
                        let destination = cityPreset == "기타" ? customCity : cityPreset
                        store.createTrip(
                            country: country,
                            destination: destination.isEmpty ? "여행지" : destination,
                            startDate: useDates ? startDate : nil,
                            endDate: useDates ? endDate : nil,
                            flightNumber: flightNumber,
                            myMapsURL: myMapsURL
                        )
                    }
                    .disabled(cityPreset == "기타" && customCity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
