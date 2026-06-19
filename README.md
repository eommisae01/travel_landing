# 타카마쓰 가족여행 대시보드

타카마쓰 / 나오시마 가족여행을 한눈에 보기 위한 정적 웹 대시보드입니다. 일정, 지도, 체크리스트, 날씨별 플랜 B, 빠른 링크, 간단 지출 메모를 담고 있습니다.

## 로컬에서 실행

파일을 그대로 열어도 대부분 동작합니다. PWA와 오프라인 캐시까지 확인하려면 로컬 서버로 실행하는 것이 좋습니다.

```bash
python3 -m http.server 8000
```

브라우저에서 `http://localhost:8000`을 엽니다.

## 파일 구조

- `index.html`: 화면 구조, 항공편/숙소/일정/장소 placeholder
- `style.css`: 모바일 우선 반응형 디자인
- `script.js`: 날짜, 빠른 링크, 체크리스트, 지출 메모, 탭, 복사 기능
- 식당 후보/시간대별 계획표: 식당, 위치, 이동 블록을 날짜별 시간대에 드래그
- `manifest.json`: 홈 화면 추가용 PWA 설정
- `service-worker.js`: 기본 오프라인 캐시
- `assets/setouchi-hero.png`: 상단 히어로 이미지

## 수정 위치

- 화면에서 바로 수정: 오른쪽 아래 `편집 켜기`를 누른 뒤 문구를 클릭해서 고칩니다. 포커스를 빼면 브라우저에 저장됩니다.
- 링크/날짜/지도 iframe: 오른쪽 아래 `링크/날짜` 버튼에서 저장합니다.
- Google Calendar iframe: 오른쪽 아래 `링크/날짜`에서 `Google Calendar iframe src`에 붙여넣습니다.
- 화면에서 고친 문구 초기화: 오른쪽 아래 `문구 초기화`
- 식당 후보 수정: 음식 후보 리스트에서 여러 개를 추가하고 삭제합니다.
- 일정 심화 수정: 날짜별 일정의 `시간대별 계획표 열기`를 눌러 식당, 위치, 이동 블록을 시간대에 끌어다 놓습니다.
- 빠른 링크: `script.js` 상단 `CONFIG.links`
- 여행 날짜: `script.js` 상단 `CONFIG.tripStartDate`, `tripEndDate`, `tripDays`
- Google My Maps iframe: `script.js` 상단 `CONFIG.myMapsEmbedUrl`
- Google Calendar iframe: `script.js` 상단 `CONFIG.calendarEmbedUrl`
- Google My Maps 열기 링크: `script.js` 상단 `CONFIG.links.myMaps`
- 항공편: `index.html`의 `항공편 정보 수정 위치` 주석 주변
- 숙소: `index.html`의 `숙소 정보 수정 위치` 주석 주변
- 일정: `index.html`의 `날짜별 일정` 섹션
- 체크리스트: `script.js` 상단 `CHECKLIST`

## Google My Maps 사용 방식

이 페이지에서 장소를 저장하거나 수정하지 않습니다.

```text
Google My Maps = 장소 저장/수정 원본
웹페이지 = 그 지도를 보기 좋게 임베드하는 대시보드
```

Google My Maps에서 공유/삽입용 iframe `src`를 복사한 뒤 `script.js`의 `CONFIG.myMapsEmbedUrl`에 붙여넣으세요. 지도 전체를 여는 링크는 `CONFIG.links.myMaps`에 넣습니다.

## Google Calendar

Google Calendar는 iframe보다 “Google Calendar 열기” 버튼 방식을 추천합니다. 캘린더 iframe은 공개 설정이 필요할 수 있고, 가족끼리만 보려면 여행용 Google Calendar를 만든 뒤 가족 구글 계정에 공유하는 편이 더 안전합니다.

`CONFIG.links.calendar`에 캘린더 링크를 넣으면 버튼으로 열 수 있습니다. 꼭 iframe이 필요하면 `index.html` 하단의 주석 처리된 Calendar 예시를 참고하세요.

### Google Calendar iframe embed 방법

1. Google Calendar 웹에서 왼쪽의 여행용 캘린더 `⋮` 메뉴를 엽니다.
2. `설정 및 공유`로 들어갑니다.
3. `캘린더 통합` 섹션에서 `삽입 코드`를 복사합니다.
4. `index.html` 하단의 `Google Calendar iframe 옵션` 주석 안 예시를 실제 섹션으로 꺼내고, 복사한 iframe 코드를 붙여넣습니다.
5. 가족끼리만 보려면 캘린더를 공개하지 말고 가족 Google 계정에 공유한 뒤, 웹페이지에는 “Google Calendar 열기” 버튼만 두는 편을 추천합니다.

주의: iframe으로 모두에게 보이게 하려면 Calendar 공개 설정이 필요할 수 있습니다. GitHub Pages에 공개 배포할 경우 일정 세부 내용이 노출될 수 있으니 비행편 예약번호, 숙소 세부 정보, 개인정보는 캘린더에도 조심해서 넣으세요.

## 배포

GitHub Pages, Vercel, Netlify 모두 정적 사이트로 배포할 수 있습니다. 저장소 루트에 현재 파일들을 올리고 `index.html`을 시작 파일로 두면 됩니다.

## localStorage 저장 항목

- 체크리스트 상태: `takamatsu-family-checklist-v1`
- 지출 메모: `takamatsu-family-expenses-v1`
- 식당 후보: `takamatsu-family-foods-v1`
- 위치/이동 등 일정 블록: `takamatsu-family-schedule-blocks-v1`
- 시간대별 일정 배치: `takamatsu-family-schedule-board-v1`
- 체크리스트 항목/완료 상태: `takamatsu-family-checklist-data-v2`
- 화면에서 직접 수정한 문구: `takamatsu-family-editable-text-v1`
- 화면 설정 패널에서 저장한 링크/날짜: `takamatsu-family-settings-v1`

가족 간 실시간 동기화는 없습니다. 같은 기기와 같은 브라우저에서만 저장 상태가 유지됩니다.

## 개인정보 보호 주의사항

이 웹페이지를 GitHub Pages 등에 올리면 사실상 공개 링크로 접근 가능할 수 있습니다. 따라서 다음 정보는 절대 직접 넣지 마세요.

- 여권번호
- 생년월일
- 전화번호 전체
- 예약번호 전체
- 항공권 e-ticket 번호
- 결제 정보
- 집 주소
- 상세 개인정보
- 가족의 민감한 건강정보

권장 방식:

- 항공권: “예약 완료 / Gmail 확인”
- 호텔: “예약 완료 / 예약 앱 확인”
- 예약번호: 직접 표시하지 않기
- 상세 개인정보는 Google Calendar, Gmail, 예약 앱에서만 확인
- 웹페이지에는 여행 진행에 필요한 요약 정보만 표시

## PWA 홈 화면 추가

모바일 브라우저에서 페이지를 연 뒤 공유 메뉴의 “홈 화면에 추가”를 선택합니다. Google My Maps iframe은 인터넷 연결이 필요할 수 있지만, 주요 일정과 체크리스트는 페이지 안에 남아 오프라인에서도 어느 정도 확인할 수 있습니다.
