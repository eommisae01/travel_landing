import { TripData } from "./types";

export const DEFAULT_TRIP_ID = "trip-takamatsu-2026";
export const MY_MAPS_MID = "1njIQAzxY74XFmaChyqYaY-q7t1KsC-M";
export const MY_MAPS_URL = `https://www.google.com/maps/d/u/0/viewer?mid=${MY_MAPS_MID}`;
export const MY_MAPS_EMBED_URL = `https://www.google.com/maps/d/embed?mid=${MY_MAPS_MID}&ehbc=2E312F`;

export const googleMapUrlFromCoords = (coords: string) => {
  const [lng, lat] = coords.split(",");
  return `https://www.google.com/maps/search/?api=1&query=${lat},${lng}`;
};

const myMapPlaces = [
  ["place-airport-1", "타카마쓰 공항 환전/ATM", "공항", "134.018922,34.219017,0", "국제선 쪽 114Bank Money Exchange, 은행 ATM. 사진 기준 운영 9:00-21:00. 트래블카드 출금/환전 확인."],
  ["place-port-1", "미야노우라항 2번 버스정류장", "환승", "133.972996,34.459005,0", "페리 도착 후 재빨리 2번 정류장으로 이동. 츠츠지소행 100엔 버스 탑승."],
  ["place-bus-1", "츠츠지소", "환승", "133.993486,34.438656,0", "시내버스 종점. 여기서 베네세 구역 무료 셔틀버스로 갈아타기."],
  ["place-art-0", "지중미술관", "미술관", "133.986422,34.444914,0", "10:00-17:00, 마지막 입장 16:00. 날짜/시간 예약 필요. 6/23 12:00 예약 완료."],
  ["place-art-1", "타카마츠시 미술관", "관광지", "134.049138,34.344046,0", ""],
  ["place-art-2", "리쓰린 공원", "관광지", "134.0457696,34.3299036,0", ""],
  ["place-art-3", "이우환 미술관", "관광지", "133.9891177,34.4485238,0", ""],
  ["place-art-4", "Pumpkin by Yayoi Kusama", "관광지", "133.9956455,34.4463665,0", ""],
  ["place-art-5", "베네세 하우스 뮤지엄", "미술관", "133.991591,34.442386,0", "08:00-21:00, 마지막 입장 20:00."],
  ["place-art-6", "Valley Gallery", "미술관", "133.989973,34.444196,0", "09:30-16:00, 마지막 입장 15:30. 베네세 하우스 티켓에 포함."],
  ["place-art-7", "히로시 스기모토 갤러리", "미술관", "133.991872,34.444019,0", "11:00-15:00, 마지막 입장 14:00. 날짜/시간 예약 필요."]
] as const;

const myMapFoods = [
  ["dessert-1", "산비키노 코부타 (아기돼지 세마리)", "디저트", "134.051646,34.3386338,0", ""],
  ["dessert-2", "브랑제리 쿠리무기", "디저트", "134.046978,34.3283155,0", ""],
  ["dessert-3", "さくらドーナツ堂", "디저트", "134.052507,34.3387569,0", ""],
  ["dessert-4", "As canele &. 瓦町店", "디저트", "134.0508241,34.3396691,0", "까눌레!!!!!"],
  ["dessert-5", "Le Reve", "디저트", "134.0496431,34.3415212,0", "빵!!!"],
  ["izakaya-1", "おばんざい家庭料理 いろいろ", "이자카야", "134.0505282,34.3408073,0", "이자카야"],
  ["izakaya-2", "Okamura", "이자카야", "134.0507691,34.3411097,0", ""],
  ["izakaya-3", "讃岐のちょい呑み屋 EViSU / Sanuki Izakaya EViSU", "이자카야", "134.0505362,34.3398497,0", "아주 늦게까지"],
  ["izakaya-4", "Issekigocho", "이자카야", "134.0506978,34.3414884,0", ""],
  ["food-udon-1", "가마아게 우동 오카지마 다카마츠점", "우동", "134.0491239,34.3488577,0", ""],
  ["food-local-1", "호네츠키도리 잇카쿠 타카마츠점", "식당", "134.0486208,34.3430677,0", ""],
  ["food-udon-2", "우동보 타카마츠본점", "우동", "134.0483626,34.3394937,0", ""],
  ["food-seafood-1", "해물 우마이몬야 하마카이도 카지야마치점", "식당", "134.0488211,34.3433379,0", ""],
  ["food-yakiniku-1", "야키니쿠호루몬 신묘정육점 카지야마치점", "야키니쿠", "134.0486874,34.3434107,0", ""],
  ["food-yakiniku-2", "야키니쿠 하나후사 본점", "야키니쿠", "134.0542011,34.3417554,0", ""],
  ["food-udon-3", "신페이 우동", "우동", "134.0524855,34.3416034,0", ""],
  ["food-udon-4", "우동 바카이치다이", "우동", "134.0585379,34.3367417,0", ""],
  ["food-yakiniku-3", "焼肉 丸惠 松縄店", "야키니쿠", "134.0656764,34.3165395,0", "야키니쿠"],
  ["food-unagi-1", "우나기 마츠모토", "식당", "134.0491649,34.3235171,0", "민물장어"],
  ["food-soba-1", "Tasu Hiku", "소바", "134.0447632,34.3323896,0", "소바"],
  ["food-udon-5", "혼카쿠테우치모리야", "우동", "134.0473602,34.3523085,0", ""],
  ["food-udon-6", "사누키 우동 우에하라야 본점", "우동", "134.0453842,34.3271176,0", ""],
  ["food-udon-7", "마츠시타 제면소", "우동", "134.0449083,34.3350154,0", ""],
  ["food-yakiniku-4", "焼肉イトーロインすき焼亭", "야키니쿠", "134.0502471,34.3462657,0", "스키야키"],
  ["food-bistro-1", "粋香(夜) / 日々 粋香(昼)", "식당", "134.0454632,34.3430253,0", ""],
  ["food-bistro-2", "Bistro Bon", "식당", "134.0495334,34.3315728,0", "함박"],
  ["food-yakiniku-5", "黒毛和牛ホルモン 大衆焼肉しんすけ トキワ新町店", "야키니쿠", "134.0507739,34.3412928,0", "곱창구이"],
  ["food-sushi-1", "鮨 猿の手", "스시", "134.0516597,34.3427279,0", "오마카세?"],
  ["food-local-2", "Honetsuki-dori Ippon Gabumaru", "식당", "134.0516688,34.343559,0", ""],
  ["food-local-3", "엔마대왕's 키친", "식당", "134.0516226,34.3434486,0", ""],
  ["food-gyoza-1", "교자야", "식당", "134.0527714,34.3429114,0", ""],
  ["food-udon-8", "수타 우동 무기조", "우동", "134.0603187,34.347775,0", "오픈런해야함"],
  ["food-sushi-2", "스시 도코로 이토한", "스시", "134.052336,34.3420079,0", "오마카세, 6시-3시"],
  ["food-sushi-3", "세토노마쓰리 스시 효고마치점", "스시", "134.0498007,34.3459902,0", ""],
  ["cafe-naoshima-1", "나오시마 커피", "카페", "134.0005878,34.4568835,0", "미야노우라항 근처 카페 후보"],
  ["cafe-1", "豆丸珈琲 鍛冶屋町焙煎所", "카페", "134.0492534,34.3429955,0", "원두카페"],
  ["cafe-2", "스벅 スターバックス コーヒー 高松上福岡店", "카페", "134.06453,34.327048,0", "스벅"],
  ["cafe-3", "Kona's Coffee Ritsurin Garden", "카페", "134.0433778,34.3239173,0", ""],
  ["cafe-4", "Akaito Coffee", "카페", "133.9752235,34.4586412,0", ""]
] as const;

const galleryItems = [
  ["gallery-01", "공항 리무진버스 경로", "/assets/gallery/route-airport-bus.png", "2026-06-22", "공항/버스", "다카마쓰 공항에서 시내로 이동하는 버스 경로 참고", true],
  ["gallery-02", "공항 환전/ATM", "/assets/gallery/airport-exchange-atm.png", "2026-06-22", "공항/환전", "114Bank Money Exchange, 은행 ATM. 트래블카드 출금 확인", true],
  ["gallery-03", "나오시마 → 다카마쓰 시간표", "/assets/gallery/ferry-naoshima-to-takamatsu.png", "2026-06-23", "페리", "복귀편 17:00 추천", true],
  ["gallery-04", "다카마쓰 → 나오시마 시간표", "/assets/gallery/ferry-takamatsu-to-naoshima.png", "2026-06-23", "페리", "10:14 출발 추천", true],
  ["gallery-05", "페리 전체 표", "/assets/gallery/ferry-table-overview.png", "2026-06-23", "페리", "왕복 페리/고속페리 비교 표", false],
  ["gallery-06", "베네세 셔틀 환승 안내", "/assets/gallery/benesse-shuttle-transfer.png", "2026-06-23", "버스/셔틀", "츠츠지소에서 베네세 구역 무료 셔틀 환승", true],
  ["gallery-07", "셔틀 시간 하이라이트", "/assets/gallery/shuttle-times-highlight.png", "2026-06-23", "버스/셔틀", "이우환/밸리 갤러리에서 츠츠지소행 시간", false],
  ["gallery-08", "이우환/밸리 버스 안내", "/assets/gallery/lee-ufan-valley-bus.png", "2026-06-23", "버스/셔틀", "이우환 미술관/Valley Gallery 앞 셔틀 안내", false],
  ["gallery-09", "베네세 버스 시간표", "/assets/gallery/benesse-bus-timetable.png", "2026-06-23", "버스/셔틀", "지중미술관행/츠츠지소행 셔틀 시간표", true],
  ["gallery-10", "츠츠지소 100엔 버스", "/assets/gallery/tsutsuji-town-bus.png", "2026-06-23", "버스/셔틀", "미야노우라항에서 츠츠지소행 100엔 버스 시간 참고", true],
  ["gallery-11", "나오시마 지도 메모", "/assets/gallery/naoshima-map-annotated.png", "2026-06-23", "지도", "항구/미술관/츠츠지소 위치 관계", true],
  ["gallery-12", "미술관 사이 이동 시간", "/assets/gallery/museum-transfer-times.png", "2026-06-23", "미술관", "지중-이우환-베네세 이동 감각", true],
  ["gallery-13", "이우환 미술관 메모", "/assets/gallery/lee-ufan-note.png", "2026-06-23", "미술관", "온라인 1,200엔, 관람 50분 정도", false],
  ["gallery-14", "지중미술관 메모", "/assets/gallery/chichu-note.png", "2026-06-23", "미술관", "온라인 2,500엔, 사전예약 필수, 90-120분", true],
  ["gallery-15", "관람 순서 후보", "/assets/gallery/viewing-order-note.png", "2026-06-23", "미술관", "A/B 관람 순서 후보", false],
  ["gallery-16", "베네세 하우스 메모", "/assets/gallery/benesse-house-note.png", "2026-06-23", "미술관", "온라인 1,300엔, 관람 1시간 30분", false],
  ["gallery-17", "Valley Gallery 메모", "/assets/gallery/valley-gallery-note.png", "2026-06-23", "미술관", "베네세 뮤지엄 관람 시 무료, 20-30분", false]
] as const;

const onsiteNotes = [
  ["onsite-1", "공항 이동", "6/24 RS0742 11:40 출발. 마지막 날은 관광보다 체크아웃과 공항 이동을 우선.", "urgent"],
  ["onsite-2", "공항 환전/출금", "타카마쓰 공항 국제선 쪽 114Bank Money Exchange와 은행 ATM 위치 확인. 사진 기준 환전 9:00-21:00. 트래블카드 출금, 현금 엔화 보충, 리무진버스 티켓 구매 위치를 공항에서 같이 확인.", "money"],
  ["onsite-3", "나오시마 버스 핵심", "미야노우라항 도착 후 2번 정류장으로 바로 이동. 츠츠지소행 시내버스는 100엔, 하차할 때 지불. 약 20분 이동 후 츠츠지소에서 베네세 구역 무료 셔틀버스로 환승.", "move"],
  ["onsite-4", "베네세 무료 셔틀", "츠츠지소 → 히로시 스기모토 갤러리 → 베네세 하우스 뮤지엄 → 이우환 미술관/Valley Gallery → 지중미술관. 반대 방향은 지중미술관에서 출발해 츠츠지소로 돌아감. 버스 대기 시간이 일정의 병목.", "move"],
  ["onsite-5", "나룻배체험", "선착순 성격이 강하고 원하는 시간대가 있으면 미리 예매 여부 확인. 6/23은 12:00 지중미술관 예약이 있어 오전에는 무리하지 않기.", "note"]
] as const;

export const seedData: TripData = {
  trips: [
    {
      id: DEFAULT_TRIP_ID,
      name: "타카마쓰 가족여행",
      region: "타카마쓰 · 나오시마",
      start_date: "2026-06-22",
      end_date: "2026-06-24",
      hero_image: "/assets/setouchi-hero.png",
      note: "RS0741 10:30 도착, RS0742 11:40 출발. 짐을 들고 우동집/공원에 가지 않고 숙소 짐보관 후 움직이는 일정.",
      country: "일본",
      cities: ["타카마쓰", "나오시마"],
      accommodation: "리쓰린코엔 기타구치역 근처 숙소 · 12:00 짐보관 기준",
      my_maps_url: MY_MAPS_URL,
      outbound_origin: "서울",
      outbound_destination: "타카마쓰",
      outbound_flight: "RS0741",
      outbound_arrival_time: "10:30",
      return_origin: "타카마쓰",
      return_destination: "서울",
      return_flight: "RS0742",
      return_departure_time: "11:40",
      budget_amount: 150000,
      budget_currency: "JPY",
      archived: false
    }
  ],
  trip_members: [
    { id: "member-me", trip_id: DEFAULT_TRIP_ID, name: "예지", color: "#16a3a3", role: "지도/예약 관리" },
    { id: "member-dad", trip_id: DEFAULT_TRIP_ID, name: "승환", color: "#ff6f61", role: "컨디션/동선 확인" },
    { id: "member-minji", trip_id: DEFAULT_TRIP_ID, name: "민지", color: "#ffc857", role: "맛집/카페 후보" }
  ],
  itinerary_items: [
    { id: "iti-1", trip_id: DEFAULT_TRIP_ID, date: "2026-06-22", time_label: "오전", start_time: "10:30", end_time: "12:00", title: "RS0741 타카마쓰 도착 / 숙소 짐보관", description: "10:30 도착 기준. 공항에서 바로 시내로 무리하게 뛰지 않고 12:00 숙소 짐보관 시간에 맞춰 이동. 짐 들고 우동집/공원 이동 금지.", location: "타카마쓰 공항 → 숙소", priority: "필수", reservation_status: "확정", weather_impact: "낮음", owner: "다 같이", sort_order: 10 },
    { id: "iti-2", trip_id: DEFAULT_TRIP_ID, date: "2026-06-22", time_label: "오후", start_time: "14:00", end_time: "16:00", title: "리쓰린 공원", description: "날씨가 괜찮으면 천천히 산책. 첫날 핵심 일정.", location: "리쓰린 공원", priority: "날씨 좋으면", reservation_status: "해당 없음", weather_impact: "중간", owner: "다 같이", sort_order: 20 },
    { id: "iti-3", trip_id: DEFAULT_TRIP_ID, date: "2026-06-23", time_label: "아침", start_time: "09:20", end_time: "10:10", title: "숙소 → 다카마쓰항 이동", description: "JR 리쓰린코엔 기타구치역에서 9:20 전후 열차로 다카마쓰역 이동 후 항구로 이동.", location: "리쓰린코엔 기타구치역 → 다카마쓰항", priority: "필수", reservation_status: "확인 필요", weather_impact: "낮음", owner: "다 같이", sort_order: 30 },
    { id: "iti-4", trip_id: DEFAULT_TRIP_ID, date: "2026-06-23", time_label: "오전", start_time: "10:14", end_time: "11:04", title: "페리: 타카마쓰항 → 나오시마", description: "추천 페리. 소요 약 50분, 성인 편도 520엔. 도착 후 항구 앞 자전거 대여와 점심 후보 확인.", location: "타카마쓰항 → 미야노우라항", priority: "필수", reservation_status: "시간 확정", weather_impact: "높음", owner: "다 같이", sort_order: 40 },
    { id: "iti-5", trip_id: DEFAULT_TRIP_ID, date: "2026-06-23", time_label: "오전", start_time: "11:05", end_time: "11:45", title: "미야노우라항 → 츠츠지소 → 지중미술관", description: "페리 하차 후 2번 정류장으로 이동. 츠츠지소행 시내버스 100엔, 하차할 때 지불. 츠츠지소에서 베네세 구역 무료 셔틀버스로 지중미술관 이동. 버스 대기 시간이 핵심.", location: "미야노우라항 2번 정류장 → 츠츠지소 → 지중미술관", priority: "필수", reservation_status: "확인 필요", weather_impact: "중간", owner: "다 같이", sort_order: 50 },
    { id: "iti-6", trip_id: DEFAULT_TRIP_ID, date: "2026-06-23", time_label: "낮", start_time: "12:00", end_time: "13:30", title: "지중미술관 예약", description: "Chichu Art Museum Jun 23, 2026 (Tue) 12:00. 성인 3명, 각 ¥2,500. QR은 예약 화면에서 확인. 관람 90-120분 예상.", location: "지중미술관", priority: "필수", reservation_status: "예약 완료", weather_impact: "중간", owner: "다 같이", sort_order: 60 },
    { id: "iti-7", trip_id: DEFAULT_TRIP_ID, date: "2026-06-23", time_label: "오후", start_time: "13:30", end_time: "16:30", title: "베네세 구역 미술관 후보", description: "이우환미술관, Valley Gallery, 베네세 하우스 뮤지엄 후보. 셔틀 시간 안 맞으면 도보/전기자전거가 빠를 수 있음.", location: "지중미술관 주변", priority: "선택", reservation_status: "현장 판단", weather_impact: "중간", owner: "다 같이", sort_order: 70 },
    { id: "iti-8", trip_id: DEFAULT_TRIP_ID, date: "2026-06-23", time_label: "오후", start_time: "17:00", end_time: "17:50", title: "페리: 나오시마 → 다카마쓰항", description: "추천 복귀편. 시내 도착 후 저녁 일정으로 연결.", location: "미야노우라항 → 다카마쓰항", priority: "필수", reservation_status: "시간 확정", weather_impact: "높음", owner: "다 같이", sort_order: 80 },
    { id: "iti-9", trip_id: DEFAULT_TRIP_ID, date: "2026-06-24", time_label: "아침", start_time: "08:00", end_time: "10:00", title: "체크아웃 / RS0742 공항 이동", description: "RS0742 11:40 출발. 마지막 날은 관광보다 공항 이동 중심으로 줄이기. 공항에서 트래블카드 ATM/환전 필요하면 이 시간 안에 처리.", location: "호텔 → 타카마쓰 공항", priority: "필수", reservation_status: "확인 필요", weather_impact: "낮음", owner: "다 같이", sort_order: 90 }
  ],
  places: myMapPlaces.map(([id, name, category, coords, note]) => ({
    id,
    trip_id: DEFAULT_TRIP_ID,
    name,
    category,
    address: coords,
    map_url: googleMapUrlFromCoords(coords),
    hours: "확인 필요",
    reservation_note: "My Maps에서 가져옴",
    sensitive_note: note
  })),
  food_candidates: myMapFoods.map(([id, name, category, coords, note]) => ({
    id,
    trip_id: DEFAULT_TRIP_ID,
    name,
    category,
    location: coords,
    map_url: googleMapUrlFromCoords(coords),
    reservation: "확인 필요",
    wait_note: "확인 필요",
    recommender: "My Maps",
    note,
    is_favorite: false
  })),
  checklist_items: [
    "여권", "RS0741/RS0742 항공권 확인", "호텔 예약 확인", "eSIM / 로밍", "신용카드", "현금 / 엔화", "공항 ATM/환전 위치 확인", "보조배터리", "지중미술관 QR 확인", "페리/리무진버스 티켓 구매 위치 확인", "츠츠지소 셔틀 동선 확인", "나룻배체험 예매/선착순 확인"
  ].map((text, index) => ({
    id: `check-${index + 1}`,
    trip_id: DEFAULT_TRIP_ID,
    group_name: index < 6 ? "여행준비" : ["예지", "승환", "민지"][index % 3],
    text,
    owner: index % 3 === 0 ? "예지" : index % 3 === 1 ? "승환" : "민지",
    is_done: false,
    sort_order: index
  })),
  gallery_items: galleryItems.map(([id, title, src, date, category, note, is_favorite], index) => ({
    id,
    trip_id: DEFAULT_TRIP_ID,
    title,
    src,
    date,
    category,
    note,
    is_favorite,
    sort_order: index
  })),
  onsite_notes: onsiteNotes.map(([id, title, body, tone], index) => ({
    id,
    trip_id: DEFAULT_TRIP_ID,
    title,
    body,
    tone,
    sort_order: index
  })),
  expenses: [
    { id: "expense-1", trip_id: DEFAULT_TRIP_ID, category: "교통비", item: "페리 예상", amount: 3120, currency: "JPY", payer: "예지", intended_payer: "예지", participants: ["예지", "승환", "민지"], note: "성인 3명 왕복 기준 520엔 x 2 x 3" },
    { id: "expense-2", trip_id: DEFAULT_TRIP_ID, category: "입장권", item: "지중미술관", amount: 7500, currency: "JPY", payer: "예지", intended_payer: "예지", participants: ["예지", "승환", "민지"], note: "성인 3명, 12:00 예약, 각 2,500엔" }
  ],
  quick_links: [
    { id: "link-1", trip_id: DEFAULT_TRIP_ID, label: "공유 지도", kind: "map", url: MY_MAPS_URL },
    { id: "link-2", trip_id: DEFAULT_TRIP_ID, label: "날씨", kind: "weather", url: "https://weather.com/" },
    { id: "link-3", trip_id: DEFAULT_TRIP_ID, label: "페리 시간", kind: "ferry", url: "https://www.shikokukisen.com/" },
    { id: "link-4", trip_id: DEFAULT_TRIP_ID, label: "Google Calendar", kind: "calendar", url: "https://calendar.google.com/" }
  ],
  app_settings: [
    { id: "settings-main", default_trip_id: DEFAULT_TRIP_ID, public_sensitive: false }
  ]
};
