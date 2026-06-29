import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.appTheme) private var theme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(AppTheme.storageKey) private var themeRawValue = AppTheme.setouchi.rawValue
    @State private var accommodation = ""
    @State private var accommodationAddress = ""
    @State private var myMapsURL = ""
    @State private var outboundFlight = FlightInfo(flightNumber: "", origin: "", destination: "", localDeparture: "", localArrival: "")
    @State private var inboundFlight = FlightInfo(flightNumber: "", origin: "", destination: "", localDeparture: "", localArrival: "")
    @State private var lastSavedAt: Date?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
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

                    if horizontalSizeClass == .compact {
                        VStack(spacing: 12) {
                            FlightEditorCard(title: "가는 편", flight: $outboundFlight)
                            FlightEditorCard(title: "오는 편", flight: $inboundFlight)
                        }
                    } else {
                        HStack(alignment: .top, spacing: 12) {
                            FlightEditorCard(title: "가는 편", flight: $outboundFlight)
                            FlightEditorCard(title: "오는 편", flight: $inboundFlight)
                        }
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 270), spacing: 12)], spacing: 12) {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionLabel(title: "STAY")
                            SettingsField(title: "이름", iconName: "bed.double", placeholder: "숙소 이름", text: $accommodation)
                            SettingsField(title: "주소", iconName: "mappin", placeholder: "숙소 주소", text: $accommodationAddress, axis: .vertical)
                        }
                        .appPanel(cornerRadius: 18)

                        VStack(alignment: .leading, spacing: 12) {
                            SectionLabel(title: "MY MAPS")
                            SettingsField(title: "링크", iconName: "map", placeholder: "Google My Maps 공유 링크", text: $myMapsURL, axis: .vertical)
                        }
                        .appPanel(cornerRadius: 18)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(title: "INVITE")
                        ShareLink(item: "Triplanner 초대 링크는 Supabase 연결 후 생성됩니다.") {
                            Label("초대 메시지 공유", systemImage: "square.and.arrow.up")
                                .font(.headline.weight(.bold))
                        }
                        Text("지금은 로컬 프로토타입입니다. 다음 단계에서 Supabase 가족코드/초대 링크를 붙이면 여러 기기에서 함께 볼 수 있습니다.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .appPanel(cornerRadius: 18)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 10)], spacing: 10) {
                        Button {
                            saveChanges()
                        } label: {
                            Label("저장", systemImage: "checkmark")
                                .frame(maxWidth: .infinity)
                                .font(.headline.weight(.black))
                        }
                        .buttonStyle(.borderedProminent)

                        Button(role: .destructive) {
                            store.resetDemo()
                            syncFields()
                            lastSavedAt = Date()
                        } label: {
                            Label("데모 리셋", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                                .font(.headline.weight(.black))
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 2)
                }
                .readableWidth(820)
                .padding()
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
}

private struct ThemePickerCard: View {
    var selectedTheme: AppTheme
    var onSelect: (AppTheme) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel(title: "THEME")
                Spacer()
                Text(selectedTheme.title)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(selectedTheme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(selectedTheme.accent.opacity(0.11), in: Capsule())
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 156), spacing: 10)], spacing: 10) {
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
        .appPanel(cornerRadius: 18)
    }
}

private struct ThemeOptionTile: View {
    var theme: AppTheme
    var isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ThemePreviewMock(theme: theme, isSelected: isSelected)

            VStack(alignment: .leading, spacing: 3) {
                Text(theme.title)
                    .font(.subheadline.weight(.black))
                Text(theme.subtitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
        .padding(9)
        .background((isSelected ? theme.accent : Color.secondary).opacity(isSelected ? 0.10 : 0.052), in: RoundedRectangle(cornerRadius: 17))
        .overlay {
            RoundedRectangle(cornerRadius: 17)
                .stroke(isSelected ? theme.accent.opacity(0.45) : Color.secondary.opacity(0.10), lineWidth: isSelected ? 1.4 : 1)
        }
        .shadow(color: isSelected ? theme.accent.opacity(0.14) : .clear, radius: 8, x: 0, y: 4)
    }
}

private struct ThemePreviewMock: View {
    var theme: AppTheme
    var isSelected: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 15)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.accent.opacity(0.92),
                            theme.secondaryAccent.opacity(0.68),
                            theme.warmAccent.opacity(0.48)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 5) {
                    paletteDot(theme.accent)
                    paletteDot(theme.secondaryAccent)
                    paletteDot(theme.warmAccent)
                    Spacer()
                }

                RoundedRectangle(cornerRadius: 5)
                    .fill(.white.opacity(0.82))
                    .frame(width: 58, height: 6)

                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white.opacity(0.76))
                        .frame(width: 38, height: 18)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white.opacity(0.44))
                        .frame(width: 26, height: 18)
                }
            }
            .padding(9)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.black))
                    .foregroundStyle(theme.accent)
                    .frame(width: 22, height: 22)
                    .background(.white.opacity(0.90), in: Circle())
                    .padding(8)
            }
        }
        .frame(height: 58)
    }

    private func paletteDot(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 9, height: 9)
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.76), lineWidth: 1)
            }
    }
}

private struct SettingsOverviewGrid: View {
    @Environment(\.appTheme) private var theme
    var status: String
    var stay: String
    var mapURL: String

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 172), spacing: 9)], spacing: 9) {
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
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.black))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.weight(.black))
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .center)
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15))
        .overlay {
            RoundedRectangle(cornerRadius: 15)
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
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .center)
        .padding(11)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 15)
                .fill(theme.accent)
                .frame(width: 4)
                .padding(.vertical, 9)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(.quaternary)
        }
    }
}

private struct SettingsTripHero: View {
    @Environment(\.appTheme) private var theme
    var trip: Trip
    var currentCity: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "map.fill")
                .font(.title3.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(theme.accent, in: RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 5) {
                Text(currentCity.isEmpty ? trip.name : displayCity(currentCity))
                    .font(.title2.weight(.black))
                    .lineLimit(1)
                Text("\(trip.country) · \(trip.cities.map(displayCity).joined(separator: " / "))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(currentCity.isEmpty ? "ALL TRIP" : "LOCAL")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(theme.accent.opacity(0.12), in: Capsule())
                Text("\(trip.cities.count) cities")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.accent.opacity(0.15),
                            theme.secondaryAccent.opacity(0.06),
                            Color.secondary.opacity(0.035)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.accent)
                .frame(width: 5)
                .padding(.vertical, 15)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(.quaternary)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: title.contains("오는") ? "airplane.arrival" : "airplane.departure")
                    .font(.headline.weight(.bold))
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
                    .foregroundStyle(tint)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.headline.weight(.black))
                        if !flight.flightNumber.isEmpty {
                            Text(flight.flightNumber)
                                .font(.caption2.weight(.black))
                                .foregroundStyle(tint)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(tint.opacity(0.12), in: Capsule())
                        }
                    }
                    Text(routeText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                Spacer()
            }

            SettingsField(title: "편명", iconName: "number", placeholder: "편명", text: $flight.flightNumber)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                CompactFlightField(title: "출발지", text: $flight.origin)
                CompactFlightField(title: "도착지", text: $flight.destination)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                CompactFlightField(title: "출발 시간", text: $flight.localDeparture)
                CompactFlightField(title: "도착 시간", text: $flight.localArrival)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 250, alignment: .topLeading)
        .appPanel(cornerRadius: 18)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 18)
                .fill(tint)
                .frame(width: 4)
                .padding(.vertical, 12)
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
        HStack(alignment: axis == .vertical ? .top : .center, spacing: 10) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(theme.accent)
                .frame(width: 32, height: 32)
                .background(theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                .padding(.top, axis == .vertical ? 1 : 0)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                TextField(placeholder, text: $text, axis: axis)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(axis == .vertical ? 2...5 : 1...1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: axis == .vertical ? 66 : 54, alignment: .center)
    }
}

private struct CompactFlightField: View {
    var title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption2.weight(.black))
                .foregroundStyle(.secondary)
            TextField(title, text: $text)
                .textFieldStyle(.roundedBorder)
        }
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
    }
}
