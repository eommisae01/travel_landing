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

    private var destination: String {
        cityPreset == "기타" ? customCity.trimmingCharacters(in: .whitespacesAndNewlines) : cityPreset
    }

    private var canStart: Bool {
        !destination.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ScreenHeader(title: "새 여행", subtitle: "여행지는 먼저 정하고, 기간/항공/지도는 나중에 채워도 됩니다.")

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                        OnboardingSummaryChip(title: "Destination", value: destination.isEmpty ? "미정" : destination, iconName: "mappin.and.ellipse")
                        OnboardingSummaryChip(title: "Dates", value: useDates ? "선택됨" : "Skip", iconName: "calendar")
                        OnboardingSummaryChip(title: "Map", value: myMapsURL.isEmpty ? "Skip" : "Linked", iconName: "map")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "01 DESTINATION")
                        Picker("국가", selection: $country) {
                            ForEach(countries, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.menu)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                            ForEach(cities, id: \.self) { city in
                                Button {
                                    cityPreset = city
                                } label: {
                                    Text(city)
                                        .font(.subheadline.weight(.black))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 9)
                                        .background(cityPreset == city ? Color.teal : Color.secondary.opacity(0.12), in: Capsule())
                                        .foregroundStyle(cityPreset == city ? .white : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if cityPreset == "기타" {
                            TextField("도시 직접 입력", text: $customCity)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .appPanel()

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            SectionLabel(title: "02 DATES")
                            Toggle("", isOn: $useDates)
                                .labelsHidden()
                        }

                        if useDates {
                            DatePicker("시작", selection: $startDate, displayedComponents: .date)
                            DatePicker("종료", selection: $endDate, displayedComponents: .date)
                        } else {
                            Text("기간은 건너뛰고 나중에 설정할 수 있습니다.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .appPanel()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "03 FLIGHT")
                        TextField("편명, 예: RS0741", text: $flightNumber)
                            .textFieldStyle(.roundedBorder)
                        Text("도착/출발 시간은 여행 생성 후 설정에서 정리합니다.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .appPanel()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "04 MAP")
                        TextField("Google My Maps 공유 링크", text: $myMapsURL)
                            .textFieldStyle(.roundedBorder)
                        Text("My Maps 링크를 넣어두면 나중에 지도 동기화 기능으로 연결할 수 있습니다.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .appPanel()

                    Button {
                        startTrip()
                    } label: {
                        Label(destination.isEmpty ? "여행지 입력 필요" : "\(destination) 여행 시작", systemImage: "arrow.right")
                            .font(.headline.weight(.black))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canStart)
                }
                .readableWidth(760)
                .padding()
            }
            .navigationTitle("")
        }
    }

    private func startTrip() {
        store.createTrip(
            country: country,
            destination: destination.isEmpty ? "여행지" : destination,
            startDate: useDates ? startDate : nil,
            endDate: useDates ? endDate : nil,
            flightNumber: flightNumber,
            myMapsURL: myMapsURL
        )
    }
}

private struct OnboardingSummaryChip: View {
    var title: String
    var value: String
    var iconName: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.caption.weight(.black))
                .foregroundStyle(.teal)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.weight(.black))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
        .padding(.horizontal, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
