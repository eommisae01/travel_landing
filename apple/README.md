# Apple App Starter

이 폴더는 가족여행 협업 앱을 Apple 생태계 앱으로 옮기기 위한 SwiftUI 확장 프로젝트입니다. 같은 GitHub repository 안에서 기존 웹앱과 함께 관리합니다.

```text
travel_landing/
  app/                  Next.js 웹앱
  apple/Triplanner/     iPhone / iPad / Mac 앱
  supabase/             공용 DB schema / migration
```

현재 목표는 iPhone, iPad, Mac에서 자연스럽게 쓰는 Apple 전용 앱을 먼저 만들고, 데이터/API는 나중에 Android나 웹도 붙일 수 있게 Supabase 중심으로 유지하는 것입니다.

## 추천 시작 방식

1. Xcode를 엽니다.
2. `File > New > Project...`
3. `iOS > App` 선택
4. Product Name: `TravelPlanner`
5. Interface: `SwiftUI`
6. Language: `Swift`
7. Minimum Deployments: iOS 17 이상 추천
8. 생성된 프로젝트의 소스 파일을 이 폴더의 `TravelPlanner/` 파일들로 교체하거나 추가합니다.

## 앱 v1 화면

- Onboarding: 여행지, 기간, 비행편, My Maps 링크 입력. 여행지 외에는 Skip 가능.
- Home: 숙소, 오늘 일정, 항공편, Notes, 준비 상태.
- Schedule: 전체 / Day별 / Calendar view.
- Map: My Maps 링크 열기, 장소/식당 후보 목록.
- Notes: 주제별 메모와 사진 묶음으로 확장 예정.
- Checklist: 가족/친구별 준비물.
- Budget: 예산 진행률, 결제자/부담 예정자/사용자.

## 나중에 붙일 것

- Supabase 로그인/가족코드 세션
- My Maps KML/KMZ 가져오기 서버 함수
- Supabase Storage 사진 업로드
- 초대 링크와 멤버 권한
- App Store / TestFlight 배포

## My Maps와 Google Maps 저장 장소

일반 Google Maps의 개인 저장 장소 목록은 공식적으로 계속 동기화하기 어렵습니다. v1은 아래 방식이 현실적입니다.

- Google My Maps 공유 링크: 자동 동기화 소스
- Google Maps 장소 공유 링크: 앱에 하나씩 추가
- Google Takeout: 수동 가져오기 후보
