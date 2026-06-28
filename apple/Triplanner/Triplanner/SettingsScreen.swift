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
                        TextField("숙소 이름", text: $accommodation, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                        TextField("숙소 주소", text: $accommodationAddress, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                    }
                    .appPanel()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "MAP")
                        TextField("Google My Maps 공유 링크", text: $myMapsURL, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
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

            TextField("편명", text: $flight.flightNumber)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 8) {
                TextField("출발지", text: $flight.origin)
                    .textFieldStyle(.roundedBorder)
                TextField("도착지", text: $flight.destination)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 8) {
                TextField("출발 시간", text: $flight.localDeparture)
                    .textFieldStyle(.roundedBorder)
                TextField("도착 시간", text: $flight.localArrival)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .appPanel()
    }
}
