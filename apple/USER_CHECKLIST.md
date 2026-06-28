# 사용자 체크리스트

이 문서는 맥북에어에서 이어서 열거나, iPhone/iPad 시뮬레이터로 확인하거나, GitHub에 올릴 때 보는 짧은 안내입니다.

## 지금 바로 해야 할 것

1. GitHub Desktop을 엽니다.
2. 현재 저장소가 `travel_landing`인지 확인합니다.
3. `Push origin` 버튼이 보이면 누릅니다.
4. Xcode를 완전히 종료했다가 다시 엽니다.
5. `apple/Triplanner/Triplanner.xcodeproj`를 엽니다.
6. `Product > Clean Build Folder`를 한 번 실행합니다.
7. 상단 실행 대상에서 `iPhone`, `iPad`, `My Mac` 중 하나를 선택합니다.
8. 실행 버튼을 누릅니다.

## iPhone / iPad 시뮬레이터가 안 보이면

1. Xcode 상단 메뉴에서 `Xcode > Settings... > Platforms`를 엽니다.
2. `iOS`가 설치되어 있는지 확인합니다.
3. 없으면 iOS Simulator runtime을 설치합니다.
4. `Window > Devices and Simulators`를 엽니다.
5. `Simulators` 탭에서 `+`를 누릅니다.
6. `iPhone 16`, `iPhone SE`, `iPad Pro` 같은 기기를 추가합니다.
7. 다시 상단 실행 대상 드롭다운을 확인합니다.

그래도 안 보이면 `Product > Destination > Manage Run Destinations...`에서 iPhone/iPad 시뮬레이터가 숨김 처리되어 있지 않은지 확인합니다.

## 맥북에어에서 이어서 작업할 때

1. GitHub Desktop 설치
2. GitHub 계정 로그인
3. `eommisae01/travel_landing` 저장소 clone
4. Xcode 설치
5. Xcode에서 `apple/Triplanner/Triplanner.xcodeproj` 열기
6. GitHub Desktop에서 `Fetch origin` 또는 `Pull origin`으로 최신 코드 받기

## 현재 상태 확인

터미널을 쓸 수 있으면 저장소 폴더에서 아래 상태만 확인하면 됩니다.

```bash
git status
```

`nothing to commit, working tree clean` 또는 GitHub Desktop에서 `No local changes`가 보이면 최신 작업이 잘 정리된 상태입니다.

Xcode에서 프로젝트가 이상하게 보이면 새 프로젝트를 만들지 말고, 이 파일을 먼저 확인합니다.

```text
apple/Triplanner/Triplanner.xcodeproj
```

## 다시 Codex에게 맡길 때 첫 메시지

```text
이 저장소는 여행 계획 앱 프로젝트야.
먼저 HANDOFF.md, apple/README.md, apple/USER_CHECKLIST.md, apple/NEXT_STEPS.md를 읽고 이어서 도와줘.
현재 Apple 앱 위치는 apple/Triplanner/Triplanner.xcodeproj이고, iPhone/iPad/Mac SwiftUI 앱으로 확장 중이야.
우선순위는 Notes 사진 묶음, Supabase 동기화, My Maps 자동 동기화, 친구 초대 기능이야.
```

## 앞으로 개발 우선순위

1. Notes에 사진 여러 장 묶음 추가
2. Supabase 동기화 연결
3. My Maps 공유 링크 자동 동기화 서버/API 연결
4. 친구/가족 초대 링크
5. iPhone/iPad/Mac 레이아웃 다듬기

## 기억할 것

- 새 Xcode 프로젝트를 또 만들지 않습니다.
- 실제 Apple 앱 위치는 `apple/Triplanner`입니다.
- GitHub Desktop에서 `Push origin`을 눌러야 다른 맥에서도 최신 상태를 받을 수 있습니다.
- `.env`, API key, 비밀번호는 GitHub에 올리지 않습니다.
