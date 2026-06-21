# GitHub + Vercel 배포 순서

## 0. 지금 상황

- 로컬 앱 주소: `http://127.0.0.1:3000`
- GitHub 원격 저장소: `https://github.com/eommisae01/travel_landing.git`
- 현재 브랜치: `main`
- 가족에게 공유할 주소는 Vercel 배포 후 생기는 `https://...vercel.app` 주소입니다.

## 1. 로컬에서 확인

```bash
pnpm build
pnpm exec next start -H 127.0.0.1 -p 3000
```

브라우저에서 `http://127.0.0.1:3000`을 열어 화면을 확인합니다.

## 2. Git에 저장

변경 파일 확인:

```bash
git status
```

전체 변경을 올릴 준비:

```bash
git add .
```

커밋:

```bash
git commit -m "Convert trip dashboard to collaborative Next app"
```

GitHub로 올리기:

```bash
git push origin main
```

주의: `.env.local`에는 API 키와 Supabase 키가 들어가므로 GitHub에 올리면 안 됩니다. `.gitignore`가 `.env` 계열 파일을 무시하도록 되어 있어야 합니다.

## 3. Supabase 만들기

1. Supabase에서 새 프로젝트를 만듭니다.
2. SQL Editor를 엽니다.
3. `supabase/schema.sql` 내용을 실행합니다.
4. 초기 데이터가 필요하면 `supabase/seed.sql` 내용도 실행합니다.
5. Project Settings > API에서 아래 값을 확인합니다.
   - Project URL
   - service_role key

## 4. Vercel 프로젝트 만들기

1. Vercel에 GitHub 계정으로 로그인합니다.
2. `Add New...` → `Project`
3. `travel_landing` 저장소를 선택합니다.
4. Framework Preset이 `Next.js`인지 확인합니다.
5. Environment Variables에 아래 값을 넣습니다.

```bash
FAMILY_CODE=가족끼리-정한-코드
SESSION_SECRET=긴-랜덤-문자열
SUPABASE_URL=Supabase-Project-URL
SUPABASE_SERVICE_ROLE_KEY=Supabase-service-role-key
OPENAI_API_KEY=OpenAI-API-Key
OPENAI_RECOMMENDATION_MODEL=gpt-4.1-mini
NEXT_PUBLIC_APP_URL=https://배포주소.vercel.app
```

6. `Deploy`를 누릅니다.

## 5. 가족 초대

1. Vercel 배포 주소를 가족에게 보냅니다.
2. 가족코드를 따로 알려줍니다.
3. 휴대폰에서 열고 공유 메뉴의 `홈 화면에 추가`를 누르면 앱처럼 쓸 수 있습니다.

## 6. 배포 후 수정

코드를 고친 뒤:

```bash
git add .
git commit -m "Update trip app"
git push origin main
```

Vercel은 GitHub에 새 커밋이 올라오면 자동으로 다시 배포합니다.

데이터를 앱에서 수정한 경우:

- Supabase 연결 후에는 일정/장소/식당/체크리스트/자료/현장정보가 DB에 저장됩니다.
- 코드 수정 없이 가족들이 같은 URL에서 새 데이터를 보게 됩니다.

## 7. API 키 주의

OpenAI API 키를 채팅이나 화면에 붙여넣은 적이 있으면 OpenAI Platform에서 삭제하고 새 키로 교체하는 편이 안전합니다.

키는 코드에 적지 말고 Vercel Environment Variables 또는 로컬 `.env.local`에만 넣습니다.
