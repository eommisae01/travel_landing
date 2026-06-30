import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.appTheme) private var theme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(AppTheme.storageKey) private var themeRawValue = AppTheme.setouchi.rawValue
    @AppStorage(AppDisplaySize.storageKey) private var displaySizeRawValue = AppDisplaySize.large.rawValue
    @State private var accommodation = ""
    @State private var accommodationAddress = ""
    @State private var myMapsURL = ""
    @State private var outboundFlight = FlightInfo(flightNumber: "", origin: "", destination: "", localDeparture: "", localArrival: "")
    @State private var inboundFlight = FlightInfo(flightNumber: "", origin: "", destination: "", localDeparture: "", localArrival: "")
    @State private var lastSavedAt: Date?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ScreenHeader(title: "Settings", subtitle: "공유 전 꼭 확인할 여행 기본 정보")

                    if let trip = store.trip {
                        SettingsTripHero(trip: trip, currentCity: store.currentCity)
                        SettingsOverviewGrid(
                            status: saveStatusText,
                            stay: trip.accommodation.isEmpty ? "숙소 입력 전" : trip.accommodation,
                            mapURL: myMapsURL.isEmpty ? trip.myMapsURL : myMapsURL
                        )
                    } else {
                        SettingsSaveBanner(status: saveStatusText)
                    }

                    ThemePickerCard(selectedTheme: selectedTheme) { theme in
                        themeRawValue = theme.rawValue
                    }

                    DisplaySizePickerCard(selectedSize: selectedDisplaySize) { size in
                        displaySizeRawValue = size.rawValue
                    }

                    if horizontalSizeClass == .compact {
                        VStack(spacing: 14) {
                            FlightEditorCard(title: "가는 편", flight: $outboundFlight)
                            FlightEditorCard(title: "오는 편", flight: $inboundFlight)
                        }
                    } else {
                        HStack(alignment: .top, spacing: 16) {
                            FlightEditorCard(title: "가는 편", flight: $outboundFlight)
                            FlightEditorCard(title: "오는 편", flight: $inboundFlight)
                        }
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16)], spacing: 16) {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionLabel(title: "STAY")
                            SettingsField(title: "이름", iconName: "bed.double", placeholder: "숙소 이름", text: $accommodation)
                            SettingsField(title: "주소", iconName: "mappin", placeholder: "숙소 주소", text: $accommodationAddress, axis: .vertical)
                        }
                        .appPanel(cornerRadius: 22)

                        VStack(alignment: .leading, spacing: 16) {
                            SectionLabel(title: "MY MAPS")
                            SettingsField(title: "링크", iconName: "map", placeholder: "Google My Maps 공유 링크", text: $myMapsURL, axis: .vertical)
                        }
                        .appPanel(cornerRadius: 22)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        SectionLabel(title: "INVITE")
                        ShareLink(item: "Triplanner 초대 링크는 Supabase 연결 후 생성됩니다.") {
                            Label("초대 메시지 공유", systemImage: "square.and.arrow.up")
                                .font(.title3.weight(.bold))
                        }
                        Text("지금은 로컬 프로토타입입니다. 다음 단계에서 Supabase 가족코드/초대 링크를 붙이면 여러 기기에서 함께 볼 수 있습니다.")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .appPanel(cornerRadius: 22)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                        Button {
                            saveChanges()
                        } label: {
                            Label("저장", systemImage: "checkmark")
                                .frame(maxWidth: .infinity)
                                .font(.title3.weight(.black))
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)

                        Button(role: .destructive) {
                            store.resetDemo()
                            syncFields()
                            lastSavedAt = Date()
                        } label: {
                            Label("데모 리셋", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                                .font(.title3.weight(.black))
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 4)
                }
                .readableWidth(1120)
                .padding(24)
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        saveChanges()
                    } label: {
                        Label("저장", systemImage: "checkmark")
                    }
                }
            }
            .onAppear {
                syncFields()
            }
        }
        .appScreenBackground()
    }

    private func syncFields() {
        accommodation = store.trip?.accommodation ?? ""
        accommodationAddress = store.trip?.accommodationAddress ?? ""
        myMapsURL = store.trip?.myMapsURL ?? ""
        outboundFlight = store.trip?.outbound ?? FlightInfo(flightNumber: "", origin: "", destination: "", localDeparture: "", localArrival: "")
        inboundFlight = store.trip?.inbound ?? FlightInfo(flightNumber: "", origin: "", destination: "", localDeparture: "", localArrival: "")
    }

    private func saveChanges() {
        store.updateOutboundFlight(outboundFlight)
        store.updateInboundFlight(inboundFlight)
        store.updateAccommodation(accommodation)
        store.updateAccommodationAddress(accommodationAddress)
        store.updateMyMapsURL(myMapsURL)
        lastSavedAt = Date()
    }

    private var saveStatusText: String {
        guard let lastSavedAt else { return "현재 기기에 저장됨" }
        let seconds = max(0, Int(Date().timeIntervalSince(lastSavedAt)))
        if seconds < 60 { return "방금 저장됨" }
        return "\(seconds / 60)분 전 저장"
    }

    private var selectedTheme: AppTheme {
        AppTheme(rawValue: themeRawValue) ?? theme
    }

    private var selectedDisplaySize: AppDisplaySize {
        AppDisplaySize(rawValue: displaySizeRawValue) ?? .large
    }
}

private struct DisplaySizePickerCard: View {
    @Environment(\.appTheme) private var theme
    var selectedSize: AppDisplaySize
    var onSelect: (AppDisplaySize) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 5) {
                    SectionLabel(title: "DISPLAY")
                    Text("아이폰, 아이패드, 맥에서 읽기 편한 크기를 고릅니다")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(selectedSize.title)
                    .font(.callout.weight(.black))
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(theme.accent.opacity(0.11), in: Capsule())
            }

            HStack(spacing: 12) {
                ForEach(AppDisplaySize.allCases) { size in
                    Button {
                        onSelect(size)
                    } label: {
                        DisplaySizeTile(size: size, isSelected: selectedSize == size)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .appPanel(cornerRadius: 24)
    }
}

private struct DisplaySizeTile: View {
    @Environment(\.appTheme) private var theme
    var size: AppDisplaySize
    var isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(size.title)
                    .font(.title3.weight(.black))
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.black))
                    .foregroundStyle(isSelected ? theme.accent : .secondary.opacity(0.44))
            }

            Text(size.subtitle)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Text("Aa")
                    .font(.system(size: size.size(30), weight: .black, design: .rounded))
                Text("일정")
                    .font(.system(size: size.size(18), weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .padding(16)
        .background((isSelected ? theme.accent : Color.secondary).opacity(isSelected ? 0.08 : 0.030), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(isSelected ? theme.accent.opacity(0.48) : Color.secondary.opacity(0.11), lineWidth: isSelected ? 1.4 : 1)
        }
    }
}

private struct ThemePickerCard: View {
    var selectedTheme: AppTheme
    var onSelect: (AppTheme) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    SectionLabel(title: "THEME")
                    Text("여행마다 앱의 색감과 분위기를 바꿔요")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(selectedTheme.title)
                    .font(.callout.weight(.black))
                    .foregroundStyle(selectedTheme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(selectedTheme.accent.opacity(0.11), in: Capsule())
            }

            ThemeActivePreview(theme: selectedTheme)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), spacing: 14)], spacing: 14) {
                ForEach(AppTheme.allCases) { theme in
                    Button {
                        onSelect(theme)
                    } label: {
                        ThemeOptionTile(theme: theme, isSelected: theme == selectedTheme)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .appPanel(cornerRadius: 24)
    }
}

private struct ThemeActivePreview: View {
    var theme: AppTheme

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            themePreviewCard
                .frame(width: 220, height: 136)
            themeDescription
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 174, alignment: .center)
        .padding(18)
        .background(theme.secondaryAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 20))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.accent)
                .frame(width: 5)
                .padding(.vertical, 15)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.accent.opacity(0.20))
        }
    }

    private var themePreviewCard: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 22)
                .fill(.regularMaterial)
                .overlay(theme.secondaryAccent.opacity(0.10))

            HStack(spacing: 0) {
                theme.accent
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Circle()
                            .fill(theme.accent)
                            .frame(width: 24, height: 24)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.primary.opacity(0.12))
                            .frame(width: 82, height: 10)
                        Spacer()
                        Circle()
                            .fill(theme.warmAccent)
                            .frame(width: 16, height: 16)
                    }

                    HStack(spacing: 8) {
                        previewBlock(theme.secondaryAccent.opacity(0.22), width: 72)
                        previewBlock(theme.warmAccent.opacity(0.22), width: 50)
                        previewBlock(theme.accent.opacity(0.18), width: 38)
                    }

                    VStack(alignment: .leading, spacing: 7) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.accent)
                            .frame(width: 116, height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.primary.opacity(0.12))
                            .frame(width: 88, height: 7)
                    }
                }
                .padding(16)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.primary.opacity(0.08))
        }
    }

    private func previewBlock(_ color: Color, width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(color)
            .frame(width: width, height: 42)
            .overlay(alignment: .bottomLeading) {
                Circle()
                    .fill(.background.opacity(0.84))
                    .frame(width: 12, height: 12)
                    .padding(8)
            }
    }

    private var themeDescription: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("선택됨", systemImage: "checkmark.circle.fill")
                .font(.body.weight(.black))
                .foregroundStyle(theme.accent)
            Text(theme.moodLine)
                .font(.title2.weight(.black))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text("홈, 일정, 지도, Notes 카드의 강조색에 바로 반영됩니다.")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }

    private func paletteDot(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.80), lineWidth: 1)
            }
    }
}

private struct ThemeOptionTile: View {
    var theme: AppTheme
    var isSelected: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 13) {
            ThemePreviewMock(theme: theme, isSelected: isSelected)
                .frame(width: 96, height: 70)

            VStack(alignment: .leading, spacing: 5) {
                Text(theme.title)
                    .font(.title3.weight(.black))
                Text(theme.subtitle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack(spacing: 5) {
                    paletteDot(theme.accent)
                    paletteDot(theme.secondaryAccent)
                    paletteDot(theme.warmAccent)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3.weight(.black))
                .foregroundStyle(isSelected ? theme.accent : .secondary.opacity(0.42))
        }
        .frame(maxWidth: .infinity, minHeight: 122, alignment: .center)
        .padding(14)
        .background((isSelected ? theme.accent : Color.secondary).opacity(isSelected ? 0.08 : 0.028), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(isSelected ? theme.accent.opacity(0.52) : Color.secondary.opacity(0.10), lineWidth: isSelected ? 1.4 : 1)
        }
    }

    private func paletteDot(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .overlay {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.8)
            }
    }
}

private struct ThemePreviewMock: View {
    var theme: AppTheme
    var isSelected: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .overlay(theme.secondaryAccent.opacity(0.10))

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(theme.accent)
                    .frame(width: 42, height: 8)
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.secondaryAccent.opacity(0.28))
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.warmAccent.opacity(0.28))
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.accent.opacity(0.20))
                }
                .frame(height: 28)
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.primary.opacity(0.11))
                    .frame(width: 58, height: 6)
            }
            .padding(10)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.caption.weight(.black))
                .foregroundStyle(isSelected ? theme.accent : .secondary.opacity(0.52))
                .padding(7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.08))
        }
    }
}

private struct SettingsOverviewGrid: View {
    @Environment(\.appTheme) private var theme
    var status: String
    var stay: String
    var mapURL: String

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 12)], spacing: 12) {
            SettingsOverviewTile(
                title: "저장",
                value: status,
                iconName: "checkmark.circle.fill",
                tint: theme.accent
            )
            SettingsOverviewTile(
                title: "숙소",
                value: stay,
                iconName: "bed.double.fill",
                tint: theme.secondaryAccent
            )
            SettingsOverviewTile(
                title: "지도",
                value: mapURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "My Maps 입력 전" : "My Maps 연결됨",
                iconName: "map.fill",
                tint: theme.warmAccent
            )
        }
    }
}

private struct SettingsOverviewTile: View {
    var title: String
    var value: String
    var iconName: String
    var tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.headline.weight(.black))
                .foregroundStyle(tint)
                .frame(width: 42, height: 42)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.weight(.black))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline.weight(.black))
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .center)
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(.quaternary)
        }
    }
}

private struct SettingsSaveBanner: View {
    @Environment(\.appTheme) private var theme
    var status: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.subheadline.weight(.black))
                .foregroundStyle(theme.accent)
                .frame(width: 30, height: 30)
                .background(theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(status)
                    .font(.subheadline.weight(.black))
                Text("저장하면 홈, 지도, 일정 화면에 바로 반영됩니다.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .center)
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 18)
                .fill(theme.accent)
                .frame(width: 4)
                .padding(.vertical, 9)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(.quaternary)
        }
    }
}

private struct SettingsTripHero: View {
    @Environment(\.appTheme) private var theme
    var trip: Trip
    var currentCity: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 12) {
                heroIcon
                tripTitleBlock
                Spacer()
                tripScopeBlock
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    heroIcon
                    tripTitleBlock
                }
                tripScopeBlock
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.accent.opacity(0.075))
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.accent)
                .frame(width: 6)
                .padding(.vertical, 18)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(.quaternary)
        }
    }

    private var heroIcon: some View {
        Image(systemName: "map.fill")
            .font(.title2.weight(.black))
            .foregroundStyle(.white)
            .frame(width: 58, height: 58)
            .background(theme.accent, in: RoundedRectangle(cornerRadius: 18))
    }

    private var tripTitleBlock: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(currentCity.isEmpty ? trip.name : displayCity(currentCity))
                .font(.system(size: 32, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            Text("\(trip.country) · \(trip.cities.map(displayCity).joined(separator: " / "))")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }

    private var tripScopeBlock: some View {
        HStack(spacing: 7) {
            Text(currentCity.isEmpty ? "ALL TRIP" : "LOCAL")
                .font(.callout.weight(.black))
                .foregroundStyle(theme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(theme.accent.opacity(0.12), in: Capsule())
            Text("\(trip.cities.count) cities")
                .font(.callout.weight(.black))
                .foregroundStyle(.secondary)
        }
    }

    private func displayCity(_ city: String) -> String {
        switch city {
        case "타카마쓰": return "Takamatsu"
        case "나오시마": return "Naoshima"
        case "도쿄": return "Tokyo"
        default: return city.isEmpty ? "All Trip" : city
        }
    }
}

private struct FlightEditorCard: View {
    @Environment(\.appTheme) private var theme
    var title: String
    @Binding var flight: FlightInfo

    private var tint: Color {
        title.contains("오는") ? theme.secondaryAccent : theme.accent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: title.contains("오는") ? "airplane.arrival" : "airplane.departure")
                    .font(.title3.weight(.bold))
                    .frame(width: 44, height: 44)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(tint)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.title2.weight(.black))
                        if !flight.flightNumber.isEmpty {
                            Text(flight.flightNumber)
                                .font(.callout.weight(.black))
                                .foregroundStyle(tint)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(tint.opacity(0.12), in: Capsule())
                        }
                    }
                    Text(routeText)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                Spacer()
            }

            SettingsField(title: "편명", iconName: "number", placeholder: "편명", text: $flight.flightNumber)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                CompactFlightField(title: "출발지", text: $flight.origin)
                CompactFlightField(title: "도착지", text: $flight.destination)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                CompactFlightField(title: "출발 시간", text: $flight.localDeparture)
                CompactFlightField(title: "도착 시간", text: $flight.localArrival)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 292, alignment: .topLeading)
        .appPanel(cornerRadius: 22)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 22)
                .fill(tint)
                .frame(width: 5)
                .padding(.vertical, 16)
        }
    }

    private var routeText: String {
        let origin = flight.origin.isEmpty ? "출발지" : flight.origin
        let destination = flight.destination.isEmpty ? "도착지" : flight.destination
        let departure = flight.localDeparture.isEmpty ? "--:--" : flight.localDeparture
        let arrival = flight.localArrival.isEmpty ? "--:--" : flight.localArrival
        return "\(origin) \(departure) → \(destination) \(arrival)"
    }
}

private struct SettingsField: View {
    @Environment(\.appTheme) private var theme
    var title: String
    var iconName: String
    var placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal

    var body: some View {
        HStack(alignment: axis == .vertical ? .top : .center, spacing: 12) {
            Image(systemName: iconName)
                .font(.headline.weight(.bold))
                .foregroundStyle(theme.accent)
                .frame(width: 40, height: 40)
                .background(theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                .padding(.top, axis == .vertical ? 1 : 0)
            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(.callout.weight(.black))
                    .foregroundStyle(.secondary)
                TextField(placeholder, text: $text, axis: axis)
                    .font(.body.weight(.semibold))
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(axis == .vertical ? 2...5 : 1...1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: axis == .vertical ? 82 : 68, alignment: .center)
    }
}

private struct CompactFlightField: View {
    var title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.callout.weight(.black))
                .foregroundStyle(.secondary)
            TextField(title, text: $text)
                .font(.body.weight(.semibold))
                .textFieldStyle(.roundedBorder)
        }
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
    }
}
