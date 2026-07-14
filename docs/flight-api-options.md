# 항공편 API 후보 메모

확인일: 2026-07-15

목적: 사용자가 편명을 입력하면 출발지/도착지, 출발/도착 예정 시간, 운항 상태를 여행 앱에 자동으로 채우기.

## 결론

v1에서는 **Aviationstack** 또는 **AirLabs** 중 하나로 작게 붙여보는 것이 현실적입니다.

- **Aviationstack**: 무료 플랜이 명확합니다. 공식 가격표 기준 무료 플랜은 월 100 requests이고, real-time flights가 포함됩니다. 프로토타입에는 좋지만 가족 여러 명이 자주 열어보는 서비스에는 한도가 작습니다.
- **AirLabs**: 공식 사이트에서 free package와 free API key를 제공합니다. flight number 계열 필드가 문서/예시에 있어 앱 UX와 맞습니다. 다만 무료 패키지의 정확한 요청 한도는 계정 화면에서 최종 확인해야 합니다.
- **OpenSky Network**: 무료/공개 API로 접근할 수 있지만, ADS-B 기반 위치/운항 기록 성격이 강합니다. 공식 문서상 flight endpoint는 전날 또는 그 이전 항공편 중심이라 “미래 항공편 시간 자동 입력” 용도에는 맞지 않습니다.
- **Amadeus for Developers**: 여행 API 플랫폼으로 확장성은 좋지만, 앱에서 원하는 단순 편명 자동입력만 위해 바로 붙이기에는 무겁습니다. 무료/테스트 사용 조건은 계정 콘솔에서 API별로 확인해야 합니다.

## 추천 순서

1. **Aviationstack으로 v1 연결**
   - 이유: 무료 한도와 기능 범위가 가장 명확함.
   - 구현 범위: 편명 + 날짜 입력 -> 가능한 경우 항공편 시간 자동 채움.
   - 주의: 무료 100회/월이라 반드시 캐싱 필요.

2. **AirLabs를 보조 후보로 테스트**
   - 이유: flight information / real-time flights / flight alerts를 명시하고, free API key 진입이 쉬움.
   - 주의: 무료 요청량은 실제 가입 후 dashboard에서 확인.

3. **OpenSky는 추후 지도/실시간 위치 실험용**
   - 이유: 무료 공개 데이터 성격은 좋지만, 일정 생성용 timetable API가 아님.

## 후보 비교

| API | 무료 여부 | 앱 적합도 | 장점 | 제한/주의 |
| --- | --- | --- | --- | --- |
| Aviationstack | 무료 플랜 있음. 월 100 requests | 높음 | 가격/한도가 명확하고 real-time flights 포함 | 무료 한도 작음. 고급 기능은 유료 가능성 큼 |
| AirLabs | free package / free API key 제공 | 높음 | flight number 기반 조회 UX와 맞음 | 정확한 무료 quota는 가입 후 재확인 필요 |
| OpenSky Network | 공개 API/익명 접근 가능 | 낮음 | 항공기 위치/운항 데이터 실험에 좋음 | 미래 항공편 스케줄 자동입력에는 부적합 |
| Amadeus | 테스트/계정 기반 확인 필요 | 중간 | 여행 플랫폼 확장성 좋음 | 단순 편명 자동입력에는 과하고 조건 확인 필요 |

## 구현 원칙

- API key는 절대 브라우저 코드나 GitHub에 넣지 않습니다.
- Vercel 환경변수에 저장합니다.
  - 예: `AVIATIONSTACK_API_KEY`
  - 예: `AIRLABS_API_KEY`
- 클라이언트는 `/api/flight-lookup` 같은 우리 서버 endpoint만 호출합니다.
- 조회 결과는 `flightNumber + date` 기준으로 캐싱합니다.
- 실패해도 직접 입력이 가능해야 합니다.
- 자동 조회 결과에는 출처와 조회 시각을 같이 저장합니다.

권장 정규화 형태:

```ts
type FlightLookupResult = {
  flightNumber: string;
  airline?: string;
  departureAirport?: string;
  arrivalAirport?: string;
  scheduledDeparture?: string;
  scheduledArrival?: string;
  terminal?: string;
  gate?: string;
  status?: string;
  source: "aviationstack" | "airlabs" | "manual";
  fetchedAt: string;
};
```

## 화면 적용 아이디어

- 셋업 화면의 항공편 입력 옆에 `편명으로 불러오기` 버튼을 둡니다.
- 결과가 나오면 “출발지/출발시간/도착지/도착시간”을 미리 채웁니다.
- 결과가 없거나 무료 한도를 넘으면 조용히 직접 입력 폼을 유지합니다.
- 이미 저장된 편명은 반복 호출하지 않고 캐시를 우선 사용합니다.

## 공식 확인 링크

- Aviationstack pricing: https://aviationstack.com/pricing
- AirLabs: https://airlabs.co/
- AirLabs flight docs: https://airlabs.co/docs/flight
- OpenSky REST API docs: https://openskynetwork.github.io/opensky-api/rest.html
- Amadeus pricing: https://developers.amadeus.com/pricing
