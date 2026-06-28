import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var store: TripStore
    @State private var accommodation = ""
    @State private var myMapsURL = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("여행 설정") {
                    TextField("숙소 / 체크인 메모", text: $accommodation, axis: .vertical)
                    TextField("Google My Maps 공유 링크", text: $myMapsURL, axis: .vertical)
                    Button("저장") {
                        store.updateAccommodation(accommodation)
                        store.updateMyMapsURL(myMapsURL)
                    }
                }

                Section("친구 초대") {
                    ShareLink(item: "TravelPlanner 초대 링크는 Supabase 연결 후 생성됩니다.") {
                        Label("초대 메시지 공유", systemImage: "square.and.arrow.up")
                    }
                    Text("지금은 로컬 프로토타입이라 같은 기기 안에서 저장됩니다. 다음 단계에서 Supabase 가족코드/초대 링크를 붙이면 여러 기기에서 함께 볼 수 있어요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("개발") {
                    Button("다카마쓰 데모 데이터 다시 넣기") {
                        store.resetDemo()
                        if let trip = store.trip {
                            accommodation = trip.accommodation
                            myMapsURL = trip.myMapsURL
                        }
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("설정")
            .onAppear {
                accommodation = store.trip?.accommodation ?? ""
                myMapsURL = store.trip?.myMapsURL ?? ""
            }
        }
    }
}

