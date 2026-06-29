import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
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
                    }

                    SettingsSaveBanner(status: saveStatusText)

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

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "STAY")
                        SettingsField(title: "이름", iconName: "bed.double", placeholder: "숙소 이름", text: $accommodation)
                        SettingsField(title: "주소", iconName: "mappin", placeholder: "숙소 주소", text: $accommodationAddress, axis: .vertical)
                    }
                    .appPanel(cornerRadius: 18)

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "MAP")
                        SettingsField(title: "링크", iconName: "map", placeholder: "Google My Maps 공유 링크", text: $myMapsURL, axis: .vertical)
                    }
                    .appPanel(cornerRadius: 18)

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
            .navigationTitle("설정")
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
        guard let lastSavedAt else { return "저장 전" }
        let seconds = max(0, Int(Date().timeIntervalSince(lastSavedAt)))
        if seconds < 60 { return "방금 저장됨" }
        return "\(seconds / 60)분 전 저장"
    }
}

private struct SettingsSaveBanner: View {
    var status: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: status == "저장 전" ? "exclamationmark.circle" : "checkmark.circle.fill")
                .font(.subheadline.weight(.black))
                .foregroundStyle(status == "저장 전" ? .orange : .teal)
                .frame(width: 30, height: 30)
                .background((status == "저장 전" ? Color.orange : Color.teal).opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(status)
                    .font(.subheadline.weight(.black))
                Text("항공편, 숙소, 지도 링크는 저장 후 홈과 지도에 반영됩니다.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(11)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 15))
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(.quaternary)
        }
    }
}

private struct SettingsTripHero: View {
    var trip: Trip
    var currentCity: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "person.2.badge.gearshape")
                .font(.title3.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(.teal, in: RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 5) {
                Text(displayCity(currentCity))
                    .font(.title2.weight(.black))
                    .lineLimit(1)
                Text("\(trip.country) · \(trip.cities.map(displayCity).joined(separator: " / "))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Text("LOCAL")
                .font(.caption2.weight(.black))
                .foregroundStyle(.teal)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.teal.opacity(0.12), in: Capsule())
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
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
        default: return city.isEmpty ? "Trip" : city
        }
    }
}

private struct FlightEditorCard: View {
    var title: String
    @Binding var flight: FlightInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: title.contains("오는") ? "airplane.arrival" : "airplane.departure")
                    .font(.headline.weight(.bold))
                    .frame(width: 34, height: 34)
                    .background(.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
                    .foregroundStyle(.teal)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.headline.weight(.black))
                        if !flight.flightNumber.isEmpty {
                            Text(flight.flightNumber)
                                .font(.caption2.weight(.black))
                                .foregroundStyle(.teal)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(.teal.opacity(0.12), in: Capsule())
                        }
                    }
                    Text(routeText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
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
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .appPanel(cornerRadius: 18)
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
    var title: String
    var iconName: String
    var placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal

    var body: some View {
        HStack(alignment: axis == .vertical ? .top : .center, spacing: 10) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.teal)
                .frame(width: 32, height: 32)
                .background(.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                .padding(.top, axis == .vertical ? 1 : 0)
            TextField(placeholder, text: $text, axis: axis)
                .textFieldStyle(.roundedBorder)
                .lineLimit(axis == .vertical ? 2...5 : 1...1)
        }
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
    }
}
