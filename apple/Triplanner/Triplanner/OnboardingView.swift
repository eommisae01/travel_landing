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
                    OnboardingHero()

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                        OnboardingSummaryChip(title: "Destination", value: destination.isEmpty ? "미정" : destination, iconName: "mappin.and.ellipse")
                        OnboardingSummaryChip(title: "Dates", value: useDates ? "선택됨" : "Skip", iconName: "calendar")
                        OnboardingSummaryChip(title: "Map", value: myMapsURL.isEmpty ? "Skip" : "Linked", iconName: "map")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "01 DESTINATION")
                        HStack(spacing: 10) {
                            Image(systemName: "globe.asia.australia")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.teal)
                                .frame(width: 32, height: 32)
                                .background(.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                            Picker("국가", selection: $country) {
                                ForEach(countries, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                            ForEach(cities, id: \.self) { city in
                                Button {
                                    cityPreset = city
                                } label: {
                                    Text(city)
                                        .font(.caption.weight(.black))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 9)
                                        .background(cityPreset == city ? Color.teal : Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                                        .foregroundStyle(cityPreset == city ? .white : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if cityPreset == "기타" {
                            LabeledOnboardingField(title: "도시", iconName: "pencil", placeholder: "도시 직접 입력", text: $customCity)
                        }
                    }
                    .appPanel(cornerRadius: 18)

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
                    .appPanel(cornerRadius: 18)

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "03 FLIGHT")
                        LabeledOnboardingField(title: "편명", iconName: "airplane", placeholder: "예: RS0741", text: $flightNumber)
                        Text("도착/출발 시간은 여행 생성 후 설정에서 정리합니다.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .appPanel(cornerRadius: 18)

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "04 MAP")
                        LabeledOnboardingField(title: "지도", iconName: "map", placeholder: "Google My Maps 공유 링크", text: $myMapsURL)
                        Text("My Maps 링크를 넣어두면 나중에 지도 동기화 기능으로 연결할 수 있습니다.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .appPanel(cornerRadius: 18)

                    Button {
                        startTrip()
                    } label: {
                        Label(destination.isEmpty ? "여행지 입력 필요" : "\(destination) 여행 시작", systemImage: "arrow.right")
                            .font(.headline.weight(.black))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
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

private struct OnboardingHero: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title2.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(.teal, in: RoundedRectangle(cornerRadius: 17))

            VStack(alignment: .leading, spacing: 4) {
                Text("새 여행 만들기")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                Text("여행지만 정하면 시작할 수 있고, 나머지는 나중에 채워도 됩니다.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(.quaternary)
        }
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
                .frame(width: 26, height: 26)
                .background(.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
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
        .padding(.vertical, 6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.quaternary)
        }
    }
}

private struct LabeledOnboardingField: View {
    var title: String
    var iconName: String
    var placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.teal)
                .frame(width: 32, height: 32)
                .background(.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}
