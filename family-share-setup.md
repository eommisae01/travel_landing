# 가족 공유 설정 가이드

## 지금 단계

로컬 주소인 `http://127.0.0.1:3000`은 내 컴퓨터에서만 열립니다. 가족과 같이 보려면 Vercel에 배포하고 Supabase를 연결해야 합니다.

## Supabase

1. Supabase 프로젝트를 만듭니다.
2. SQL Editor에서 `supabase/schema.sql`을 실행합니다.
3. 초기 데이터가 필요하면 `supabase/seed.sql`을 실행합니다.
4. Project Settings > API에서 `Project URL`과 `service_role key`를 확인합니다.

## Vercel 환경변수

Vercel 프로젝트 Settings > Environment Variables에 아래 값을 넣습니다.

```bash
FAMILY_CODE=가족끼리-정한-코드
SESSION_SECRET=긴-랜덤-문자열
SUPABASE_URL=Supabase-Project-URL
SUPABASE_SERVICE_ROLE_KEY=Supabase-service-role-key
OPENAI_API_KEY=OpenAI-API-Key
OPENAI_RECOMMENDATION_MODEL=gpt-4.1-mini
NEXT_PUBLIC_APP_URL=https://배포주소.vercel.app
```

## 가족 초대

1. Vercel 배포 주소를 가족에게 보냅니다.
2. 가족코드를 따로 알려줍니다.
3. 휴대폰에서는 브라우저 공유 메뉴에서 홈 화면에 추가하면 앱처럼 열 수 있습니다.

## 추천도우미

추천도우미는 `/api/recommendations`에서 서버 환경변수 `OPENAI_API_KEY`를 사용합니다. 키는 브라우저로 내려가지 않고 서버에서만 쓰입니다.

이미 채팅이나 메모에 노출된 API 키는 나중에 OpenAI Platform에서 삭제하고 새 키로 교체하는 편이 안전합니다.
