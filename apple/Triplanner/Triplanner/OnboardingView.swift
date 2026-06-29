import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.appTheme) private var theme
    @AppStorage(AppTheme.storageKey) private var themeRawValue = AppTheme.setouchi.rawValue
    @State private var country = "일본"
    @State private var cityPreset = "도쿄"
    @State private var customCity = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var useDates = false
    @State private var flightNumber = ""
    @State private var myMapsURL = ""

    private let countries = ["일본", "한국", "대만", "태국", "프랑스", "이탈리아", "미국", "기타"]
    private let cityOptionsByCountry = [
        "일본": ["도쿄", "오사카", "후쿠오카", "삿포로", "교토", "타카마쓰", "기타"],
        "한국": ["서울", "부산", "제주", "강릉", "경주", "기타"],
        "대만": ["타이베이", "타이중", "가오슝", "타이난", "기타"],
        "태국": ["방콕", "치앙마이", "푸켓", "끄라비", "기타"],
        "프랑스": ["파리", "니스", "리옹", "마르세유", "기타"],
        "이탈리아": ["로마", "피렌체", "베네치아", "밀라노", "기타"],
        "미국": ["뉴욕", "로스앤젤레스", "샌프란시스코", "시애틀", "기타"],
        "기타": ["기타"]
    ]

    private var cities: [String] {
        cityOptionsByCountry[country] ?? ["기타"]
    }

    private var destination: String {
        cityPreset == "기타" ? customCity.trimmingCharacters(in: .whitespacesAndNewlines) : cityPreset
    }

    private var canStart: Bool {
        !destination.isEmpty
    }

    private var dateSummary: String {
        guard useDates else { return "Skip" }
        return "\(shortDate(startDate)) - \(shortDate(endDate))"
    }

    private var flightSummary: String {
        flightNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Skip" : flightNumber
    }

    private var mapSummary: String {
        myMapsURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Skip" : "Linked"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    OnboardingHero()

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                        OnboardingSummaryChip(title: "Destination", value: destination.isEmpty ? "Required" : "\(country) · \(destination)", iconName: "mappin.and.ellipse", tint: theme.accent)
                        OnboardingSummaryChip(title: "Dates", value: dateSummary, iconName: "calendar", tint: theme.secondaryAccent)
                        OnboardingSummaryChip(title: "Flight", value: flightSummary, iconName: "airplane", tint: theme.warmAccent)
                        OnboardingSummaryChip(title: "Map", value: mapSummary, iconName: "map", tint: theme.accent)
                    }

                    OnboardingThemeStrip(selectedTheme: theme) { selectedTheme in
                        themeRawValue = selectedTheme.rawValue
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        OnboardingStepHeader(title: "01 DESTINATION", status: "필수", tint: theme.accent)
                        HStack(spacing: 10) {
                            Image(systemName: "globe.asia.australia")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(theme.accent)
                                .frame(width: 32, height: 32)
                                .background(theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                            Picker("국가", selection: $country) {
                                ForEach(countries, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onChange(of: country) { _, newCountry in
                                let nextCities = cityOptionsByCountry[newCountry] ?? ["기타"]
                                cityPreset = nextCities.first ?? "기타"
                                customCity = ""
                            }
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
                                        .background(cityPreset == city ? theme.accent : Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                                        .foregroundStyle(cityPreset == city ? .white : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if cityPreset == "기타" {
                            LabeledOnboardingField(title: "도시", iconName: "pencil", placeholder: country == "기타" ? "국가/도시 직접 입력" : "도시 직접 입력", text: $customCity)
                        }
                    }
                    .appPanel(cornerRadius: 18)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            OnboardingStepHeader(title: "02 DATES", status: "선택", tint: theme.secondaryAccent)
                            Toggle("", isOn: $useDates)
                                .labelsHidden()
                        }

                        if useDates {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 10)], spacing: 10) {
                                DatePicker("시작", selection: $startDate, displayedComponents: .date)
                                DatePicker("종료", selection: $endDate, displayedComponents: .date)
                            }
                        } else {
                            Text("기간은 건너뛰고 나중에 설정할 수 있습니다.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .appPanel(cornerRadius: 18)

                    VStack(alignment: .leading, spacing: 12) {
                        OnboardingStepHeader(title: "03 FLIGHT", status: "선택", tint: theme.warmAccent)
                        LabeledOnboardingField(title: "편명", iconName: "airplane", placeholder: "예: RS0741", text: $flightNumber)
                        Text("도착/출발 시간은 여행 생성 후 설정에서 정리합니다.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .appPanel(cornerRadius: 18)

                    VStack(alignment: .leading, spacing: 12) {
                        OnboardingStepHeader(title: "04 MAP", status: "선택", tint: theme.accent)
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
        .appScreenBackground()
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

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M.d"
        return formatter.string(from: date)
    }
}

private struct OnboardingThemeStrip: View {
    var selectedTheme: AppTheme
    var onSelect: (AppTheme) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                SectionLabel(title: "STYLE")
                Spacer()
                Text(selectedTheme.title)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(selectedTheme.accent)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 8)], spacing: 8) {
                ForEach(AppTheme.allCases) { theme in
                    Button {
                        onSelect(theme)
                    } label: {
                        HStack(spacing: 8) {
                            HStack(spacing: 0) {
                                theme.accent
                                theme.secondaryAccent
                                theme.warmAccent
                            }
                            .frame(width: 30, height: 30)
                            .clipShape(RoundedRectangle(cornerRadius: 9))

                            Text(theme.title)
                                .font(.caption.weight(.black))
                                .lineLimit(1)
                            Spacer(minLength: 0)

                            if selectedTheme == theme {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(theme.accent)
                            }
                        }
                        .padding(9)
                        .frame(maxWidth: .infinity, minHeight: 46, alignment: .center)
                        .background((selectedTheme == theme ? theme.accent : Color.secondary).opacity(selectedTheme == theme ? 0.11 : 0.055), in: RoundedRectangle(cornerRadius: 14))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedTheme == theme ? theme.accent.opacity(0.45) : Color.secondary.opacity(0.10), lineWidth: selectedTheme == theme ? 1.4 : 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .appPanel(cornerRadius: 18)
    }
}

private struct OnboardingHero: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("TRIPLANNER")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                    .tracking(1.4)
                Text("새 여행 만들기")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text("여행지만 정하면 시작할 수 있고, 나머지는 나중에 채워도 됩니다.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)

            Image(systemName: "map.fill")
                .font(.title2.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(theme.accent, in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 17)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.accent.opacity(0.16),
                            theme.secondaryAccent.opacity(0.07),
                            Color.secondary.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
        }
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 22)
                .fill(theme.accent)
                .frame(width: 5)
                .padding(.vertical, 16)
        }
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
    var tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.caption.weight(.black))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
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

private struct OnboardingStepHeader: View {
    var title: String
    var status: String
    var tint: Color

    var body: some View {
        HStack {
            SectionLabel(title: title)
            Spacer()
            Text(status)
                .font(.caption2.weight(.black))
                .foregroundStyle(tint)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(tint.opacity(0.11), in: Capsule())
        }
    }
}

private struct LabeledOnboardingField: View {
    @Environment(\.appTheme) private var theme
    var title: String
    var iconName: String
    var placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(theme.accent)
                .frame(width: 32, height: 32)
                .background(theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                TextField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}
