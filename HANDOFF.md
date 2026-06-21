# 작업 인수인계 메모

이 저장소는 타카마쓰 / 나오시마 가족여행을 가족이 함께 확인하고 수정하기 위한 Next.js + Supabase 기반 협업 웹앱입니다. 새 기기나 새 Codex 대화에서 이어서 작업할 때는 이 파일을 먼저 읽으면 됩니다.

## 현재 목표

- 가족들이 휴대폰, 아이패드, 노트북에서 같은 여행 계획을 확인하고 수정할 수 있게 합니다.
- 핵심 화면은 홈, 일정, 지도/식당, 체크리스트, 자료보드, 예산, 현장정보, 설정입니다.
- 가족코드로 들어가고, 실제 데이터는 Supabase에 저장합니다.
- Vercel 배포와 GitHub 저장소가 연결되어 있어 `main` 브랜치에 push하면 자동 배포됩니다.

## 현재 연결 상태

- GitHub 저장소: `eommisae01/travel_landing`
- Vercel 배포 주소: `https://project-6ok16.vercel.app`
- 로컬 작업 위치 예시: `/Users/yz/Documents/GitHub/travel_landing`
- Supabase는 설정이 진행되어 있고, schema/seed는 사용자가 한 번 실행했습니다.

새 맥북에서는 GitHub Desktop으로 `eommisae01/travel_landing`을 clone하면 코드 작업을 이어갈 수 있습니다. Vercel과 Supabase는 클라우드라서 같은 계정/설정이면 그대로 이어집니다.

## 새 Codex 대화에서 첫 메시지 예시

```text
이 저장소는 가족여행 협업 웹앱이야.
먼저 HANDOFF.md, README.md, family-share-setup.md, deploy-vercel-github.md, supabase/schema.sql, supabase/restore-full-data.sql을 읽고 이어서 도와줘.
현재 앱은 Next.js + Supabase + Vercel 구조이고, 기능은 홈/일정/지도·식당/체크리스트/자료보드/예산/현장정보/AI 추천도우미야.
```

## 새 맥북에서 작업 이어가기

1. GitHub Desktop 설치
2. GitHub 계정 로그인
3. `eommisae01/travel_landing` 저장소 clone
4. 코드 수정 후 GitHub Desktop에서 commit
5. `Push origin` 누르면 GitHub로 올라가고 Vercel이 자동 배포

로컬에서 직접 실행하려면 터미널에서 저장소 폴더로 이동한 뒤 아래를 실행합니다.

```bash
pnpm install
pnpm dev
```

브라우저에서 `http://localhost:3000` 또는 `http://127.0.0.1:3000`을 엽니다.

## 환경변수

로컬에서 Supabase와 AI 추천도우미까지 쓰려면 `.env.local` 파일이 필요합니다. 이 파일은 GitHub에 올리면 안 됩니다.

```bash
FAMILY_CODE=가족이-입력할-코드
SESSION_SECRET=긴-랜덤-문자열
SUPABASE_URL=https://프로젝트ID.supabase.co
SUPABASE_SERVICE_ROLE_KEY=Supabase service_role key
OPENAI_API_KEY=OpenAI API key
OPENAI_RECOMMENDATION_MODEL=gpt-4.1-mini
NEXT_PUBLIC_APP_URL=https://project-6ok16.vercel.app
```

중요:

- `SUPABASE_URL`은 `/rest/v1` 없이 `https://프로젝트ID.supabase.co`까지만 넣습니다.
- `SUPABASE_SERVICE_ROLE_KEY`는 브라우저에 노출하면 안 됩니다. Vercel 환경변수나 로컬 `.env.local`에만 둡니다.
- 사용자가 이전 대화에서 OpenAI API key를 한 번 채팅에 붙여넣었습니다. 안전하게 새 키로 교체하거나 기존 키를 폐기하는 것을 권장합니다.

## Supabase 데이터 복원

사용자가 처음 실행한 `supabase/seed.sql`은 예전의 짧은 데이터라서, 배포 앱에서 사진/식당/일정이 줄어든 것처럼 보일 수 있습니다.

이 경우 Supabase SQL Editor에서 아래 파일 내용을 실행해야 합니다.

```text
supabase/restore-full-data.sql
```

이 파일은 기존 샘플 데이터를 정리하고 다음 데이터를 다시 넣습니다.

- 2026년 6월 22일-24일 일정
- 나오시마/다카마쓰 장소
- 식당 후보
- 체크리스트
- 자료보드 이미지 데이터
- 현장정보
- 예산과 빠른 링크

코드 배포와 별개로, Supabase SQL을 실행하면 새로고침 후 앱 데이터가 바로 복원됩니다.

## 현재 구현된 기능 요약

- 홈: 브리핑, 날씨/준비/오늘 일정, AI 추천도우미, 미리 조사할 것
- 일정: 날짜별 타임라인, 날짜별 추가 버튼, 장소/식당을 일정에 삽입
- 지도/식당: 장소와 식당 후보를 한 화면에서 관리, Google Maps 링크, 별표, 수정/삭제, 일정에 넣기
- 체크리스트: 여행준비와 개인별 리스트, 완료 항목은 아래로 이동, 수정, 순서 변경
- 자료보드: 사진을 날짜/주제별로 모으고, 같은 주제의 여러 사진을 팝업에서 넘겨보기
- 예산: 지출 입력/수정/삭제
- 현장정보: 공항, 페리, 버스, 셔틀, 예약 등 현장용 메모를 추가/수정/삭제
- AI 추천도우미: OpenAI API key가 있으면 식당/카페/관광지/동선 추천 생성

## 최근 사용자가 중요하게 말한 개선점

- 자료보드는 사진을 여러 장 묶어서 인스타 게시물처럼 넘겨보고 싶음.
- 식당은 지도 탭과 합치는 방향이 좋음.
- 체크리스트 항목 간격은 더 촘촘해야 함.
- 일정 타임라인의 세로선은 글씨와 너무 붙지 않아야 함.
- 현장정보는 직접 추가/수정 가능해야 함.
- 택시주소용 장소는 필요 없음.
- `미리 조사할 것`은 폰트가 작고, 펼쳤을 때 내용 전체가 자연스럽게 보여야 함.

## 주요 파일

- `app/page.tsx`: 대부분의 화면 UI와 상호작용
- `app/api/data/route.ts`: Supabase 데이터 읽기/쓰기 API
- `app/api/recommendations/route.ts`: AI 추천도우미 API
- `app/lib/seed.ts`: Supabase가 없을 때 쓰는 데모 데이터
- `app/lib/types.ts`: 데이터 타입
- `app/lib/server-data.ts`: Supabase 서버 데이터 접근
- `app/lib/auth.ts`: 가족코드 세션
- `app/globals.css`: 전역 스타일
- `supabase/schema.sql`: Supabase 테이블 생성
- `supabase/seed.sql`: 기본 seed
- `supabase/restore-full-data.sql`: 줄어든 데이터 복원용 seed
- `family-share-setup.md`: 가족 공유와 Supabase 설정 안내
- `deploy-vercel-github.md`: GitHub/Vercel 배포 안내
- `figma-redesign-brief.md`: Figma 디자인 리디자인 요청문

## 배포 흐름

보통은 아래 순서입니다.

1. 코드 수정
2. GitHub Desktop에서 commit
3. `Push origin`
4. Vercel이 자동으로 새 배포 생성
5. `Ready`가 되면 `https://project-6ok16.vercel.app`에서 확인

Supabase 데이터만 바꾸는 경우에는 GitHub/Vercel 배포가 필요 없습니다. Supabase SQL Editor나 앱 화면에서 저장하면 바로 DB에 반영됩니다.

## 주의할 점

- `.env.local`이나 API key는 GitHub에 올리지 않습니다.
- 가족코드는 완벽한 로그인은 아니고, 공개 링크를 막는 가벼운 보호 장치입니다.
- 사진을 data URL로 DB에 넣는 방식은 v1에서는 간단하지만, 사진이 많아지면 Supabase Storage로 옮기는 것이 좋습니다.
- Supabase schema를 크게 바꾸면 Vercel 코드와 DB 구조가 같이 맞아야 합니다.
