import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var accommodation = ""
    @State private var accommodationAddress = ""
    @State private var myMapsURL = ""
    @State private var outboundFlight = FlightInfo(flightNumber: "", origin: "", destination: "", localDeparture: "", localArrival: "")
    @State private var inboundFlight = FlightInfo(flightNumber: "", origin: "", destination: "", localDeparture: "", localArrival: "")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ScreenHeader(title: "Settings", subtitle: "공유 전 꼭 확인할 여행 기본 정보")

                    if let trip = store.trip {
                        HStack(spacing: 12) {
                            Image(systemName: "person.2.badge.gearshape")
                                .font(.title3.weight(.black))
                                .foregroundStyle(.teal)
                                .frame(width: 46, height: 46)
                                .background(.teal.opacity(0.14), in: RoundedRectangle(cornerRadius: 15))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(trip.name)
                                    .font(.headline.weight(.black))
                                Text("\(trip.country) · \(trip.cities.joined(separator: " / "))")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                        }
                        .appPanel(cornerRadius: 18)
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

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "STAY")
                        SettingsField(title: "이름", iconName: "bed.double", placeholder: "숙소 이름", text: $accommodation)
                        SettingsField(title: "주소", iconName: "mappin", placeholder: "숙소 주소", text: $accommodationAddress, axis: .vertical)
                    }
                    .appPanel()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "MAP")
                        SettingsField(title: "링크", iconName: "map", placeholder: "Google My Maps 공유 링크", text: $myMapsURL, axis: .vertical)
                    }
                    .appPanel()

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
                    .appPanel()

                    HStack {
                        Button {
                            store.updateOutboundFlight(outboundFlight)
                            store.updateInboundFlight(inboundFlight)
                            store.updateAccommodation(accommodation)
                            store.updateAccommodationAddress(accommodationAddress)
                            store.updateMyMapsURL(myMapsURL)
                        } label: {
                            Label("저장", systemImage: "checkmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button(role: .destructive) {
                            store.resetDemo()
                            syncFields()
                        } label: {
                            Label("데모 리셋", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .readableWidth(820)
                .padding()
            }
            .navigationTitle("설정")
            .onAppear {
                syncFields()
            }
        }
    }

    private func syncFields() {
        accommodation = store.trip?.accommodation ?? ""
        accommodationAddress = store.trip?.accommodationAddress ?? ""
        myMapsURL = store.trip?.myMapsURL ?? ""
        outboundFlight = store.trip?.outbound ?? FlightInfo(flightNumber: "", origin: "", destination: "", localDeparture: "", localArrival: "")
        inboundFlight = store.trip?.inbound ?? FlightInfo(flightNumber: "", origin: "", destination: "", localDeparture: "", localArrival: "")
    }
}

private struct FlightEditorCard: View {
    var title: String
    @Binding var flight: FlightInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel(title: title.uppercased())
                Image(systemName: "airplane")
                    .foregroundStyle(.teal)
            }

            SettingsField(title: "편명", iconName: "number", placeholder: "편명", text: $flight.flightNumber)

            HStack(spacing: 8) {
                CompactFlightField(title: "출발지", text: $flight.origin)
                CompactFlightField(title: "도착지", text: $flight.destination)
            }

            HStack(spacing: 8) {
                CompactFlightField(title: "출발 시간", text: $flight.localDeparture)
                CompactFlightField(title: "도착 시간", text: $flight.localArrival)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .appPanel()
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
            Label(title, systemImage: iconName)
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
                .padding(.top, axis == .vertical ? 7 : 0)
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
