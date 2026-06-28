# Apple 앱 다음 개발 순서

현재 Apple 앱은 실행 가능한 SwiftUI 프로토타입입니다. 다음 목표는 로컬 프로토타입을 가족이 함께 쓰는 동기화 앱으로 키우는 것입니다.

## 지금 된 것

- Xcode 멀티플랫폼 프로젝트: `apple/Triplanner/Triplanner.xcodeproj`
- iPhone / iPad / Mac SwiftUI 앱 구조
- 홈, 일정, 지도/식당, Notes, 체크리스트, 예산, 설정 탭
- 다카마쓰/나오시마 샘플 데이터
- UserDefaults 기반 로컬 저장
- Notes / 체크리스트 / 장소 추가 UI
- 설정에서 숙소와 Google My Maps 링크 수정

## 다음 1순위: 사진/자료 묶음

목표:

- `Notes`의 `페리시간표` 같은 항목 안에 여러 장의 이미지를 넣습니다.
- 한 항목을 누르면 이미지들을 좌우로 넘겨봅니다.
- iPhone Photos picker로 이미지를 추가합니다.

구현 위치:

- `Models.swift`: `NoteGroup.imageNames`를 실제 이미지 저장 구조로 확장
- `NotesScreen.swift`: 이미지 추가 버튼, 이미지 carousel
- 이후에는 Supabase Storage에 원본 이미지 업로드

## 다음 2순위: Supabase 연결

목표:

- iPhone, iPad, Mac이 같은 여행 데이터를 봅니다.
- 로컬 저장은 캐시/오프라인 fallback으로 남깁니다.

권장 구조:

- `SupabaseClient.swift` 추가
- 앱에서 직접 service role key를 쓰지 않습니다.
- 처음에는 Supabase anon key + RLS 정책 또는 Next.js API proxy 중 하나를 선택합니다.
- 가족코드/초대 링크 설계 후 row-level 접근을 붙입니다.

필요한 환경:

- Supabase project URL
- Supabase anon key
- 가족코드 또는 초대 토큰

## 다음 3순위: My Maps 자동 동기화

목표:

- 설정에 Google My Maps 공유 링크를 넣습니다.
- 서버가 KML/KMZ를 읽어 장소/식당 후보로 변환합니다.
- 앱은 변환된 장소 목록을 받아옵니다.

주의:

- 일반 Google Maps 개인 저장 장소는 공식 API로 계속 동기화하기 어렵습니다.
- My Maps 공유 링크를 v1의 정식 동기화 소스로 둡니다.
- Google Maps 장소 공유 링크는 수동 추가 흐름으로 둡니다.

구현 후보:

- Next.js API route: `/api/sync-mymaps`
- Supabase Edge Function

## 다음 4순위: 초대/가족코드

목표:

- 여행마다 초대 링크가 생깁니다.
- 초대 받은 사람이 앱에서 가족코드를 입력하거나 링크를 열어 참여합니다.
- 멤버별 체크리스트/지출/메모가 연결됩니다.

필요 데이터:

- trips
- trip_members
- trip_invites
- invite_token
- member role

## 다음 5순위: 디자인 polish

방향:

- Apple 기본 컴포넌트를 유지하되, 여행앱 느낌을 강화합니다.
- 홈은 “오늘 당장 필요한 정보” 중심
- 일정은 Day별 타임라인과 Calendar view
- 지도/식당은 카테고리 묶음 + 별표
- Notes는 주제별 자료 묶음

## Git 주의

- `travel_landing` 하나의 repository를 사용합니다.
- `apple/Triplanner` 안에 별도 `.git`을 만들지 않습니다.
- Xcode 사용자 설정은 commit하지 않습니다.
- `.DS_Store`는 commit하지 않습니다.

## Xcode에서 실행

1. `apple/Triplanner/Triplanner.xcodeproj` 열기
2. 실행 대상 선택: iPhone, iPad, My Mac
3. `Product > Clean Build Folder`
4. Run

