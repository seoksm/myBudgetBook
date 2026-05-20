# Phase 2 — 프로젝트 보일러플레이트 자동 생성 사용 가이드

Phase 1 환경 구축이 끝났으면, 이 가이드의 단 한 줄 명령으로 **Spring Boot 백엔드 + React 프론트엔드 + Hello API 통신**까지 완성된 상태를 자동 생성할 수 있습니다.

## 한 줄 요약

```bash
cd ~/claude/budget_book_codex
source activate-env.sh        # Phase 1 환경 활성화 (Java/Node 사용 가능)
bash setup-project.sh         # 백엔드 + 프론트엔드 + 통신 코드 자동 생성
```

## 사전 조건

| 조건 | 확인 명령 |
|---|---|
| Phase 1 완료 (Java 21 + Node 24) | `bash check-dev-env.sh` |
| 인터넷 연결 | Spring Initializr, npm 다운로드 필요 |
| 디스크 여유 약 500MB | (frontend `node_modules` 가 큼) |

## 스크립트가 만들어 주는 것

### 1) Spring Boot 백엔드 (`backend/`)

Spring Initializr API 에서 받아온 표준 프로젝트에 우리 구조를 입혀줍니다.

```
backend/
├── build.gradle                                Spring Boot 3.5.0 + 8개 의존성
├── gradlew, gradlew.bat                        Gradle Wrapper
├── settings.gradle
└── src/main/
    ├── java/com/mybudget/backend/
    │   ├── BackendApplication.java             메인 클래스 (Initializr 자동 생성)
    │   ├── controller/HelloController.java     ← /api/hello 엔드포인트
    │   ├── config/WebConfig.java               ← CORS 설정 (15173 허용)
    │   ├── service/.gitkeep                    빈 폴더 (Phase 5 에서 채움)
    │   ├── repository/.gitkeep
    │   ├── domain/.gitkeep
    │   ├── dto/.gitkeep
    │   ├── exception/.gitkeep
    │   └── util/.gitkeep
    └── resources/
        └── application.yml                     H2 + JPA + Actuator 설정
```

**포함된 Spring Boot 의존성 (8개):**
- `web` — REST API
- `data-jpa` — ORM
- `h2` — 개발용 인메모리/파일 DB
- `mysql` — 운영용 DB 드라이버
- `lombok` — 보일러플레이트 코드 제거
- `validation` — `@Valid` 검증
- `devtools` — Hot reload
- `actuator` — `/actuator/health` 모니터링

### 2) React 프론트엔드 (`frontend/`)

Vite + TypeScript 템플릿에 우리 구조를 입혀줍니다.

```
frontend/
├── package.json                                12개 라이브러리 설치 완료
├── vite.config.ts                              ← 프록시(/api → :18080) + Tailwind v4
├── tsconfig.json
├── index.html
└── src/
    ├── main.tsx                                ← index.css import
    ├── App.tsx                                 ← Hello API 호출 + 상태 UI
    ├── routes/, components/, features/         빈 폴더 (Phase 6 에서 채움)
    ├── api/
    │   └── client.ts                           ← axios + Hello fetcher
    ├── stores/, hooks/, utils/, constants/     빈 폴더
    └── styles/
        └── index.css                           ← Tailwind v4 + Pretendard 폰트
```

**자동 설치된 라이브러리:**

| 카테고리 | 라이브러리 |
|---|---|
| 라우팅 | `react-router-dom` |
| HTTP | `axios` |
| 서버 상태 | `@tanstack/react-query` |
| 전역 상태 | `zustand` |
| 폼/검증 | `react-hook-form`, `zod` |
| 유틸 | `date-fns`, `clsx` |
| UI | `lucide-react` (아이콘), `recharts` (차트) |
| 스타일 | `tailwindcss@4`, `@tailwindcss/vite` |

### 3) Visual Studio Code 통합 설정 (`.vscode/`)

| 파일 | 역할 |
|---|---|
| `launch.json` | **F5 한 번으로 백+프론트 동시 실행** (compound 구성) |
| `settings.json` | Java 21 런타임 경로, formatOnSave, tab size |
| `extensions.json` | 워크스페이스 추천 확장 11개 (자동 안내) |

### 4) REST Client 테스트 파일 (`http/`)

`http/hello.http` — Visual Studio Code 의 REST Client 확장으로 클릭 한 번 테스트 가능.

```http
### Spring Boot 가 살아있는지 확인
GET http://localhost:18080/api/hello
```

### 5) 루트 `.gitignore` + git 초기화

`tools/`, `node_modules/`, `backend/build/`, `backend/data/`, `.DS_Store` 등 자동 제외. 끝나면 `chore: Phase 2 boilerplate` 커밋까지 자동.

---

## 실행 후 동작 검증

스크립트가 끝나면 4가지 방법으로 작동을 확인할 수 있습니다.

### 방법 A. Visual Studio Code F5 (가장 쉬움)

```bash
code .
```

`F5` → **"▶ Full Stack (Backend + Frontend)"** 선택 → 18080 + 15173 동시 실행 → 브라우저에서 http://localhost:15173 열기 → **"✅ 연결 성공"** 카드 확인.

### 방법 B. 터미널 2개

```bash
# 터미널 A
cd backend && ./gradlew bootRun

# 터미널 B (새 창)
source activate-env.sh
cd frontend && npm run dev
```

### 방법 C. REST Client 직접 호출

`http/hello.http` 열기 → `GET http://localhost:18080/api/hello` 위의 **"Send Request"** 버튼 클릭 → JSON 응답 확인:
```json
{
  "message": "Hello from Spring Boot 3.5 !",
  "timestamp": "2026-05-17T...",
  "backend": "Spring Boot",
  "java": "21.x.x"
}
```

### 방법 D. H2 콘솔 (DB 확인)

브라우저: http://localhost:18080/h2-console
- JDBC URL: `jdbc:h2:file:./data/mybudget_codex`
- Username: `sa` / Password: 비워두기
- "Connect" → 빈 DB 상태 확인 (Phase 3 에서 테이블 생성)

---

## 자주 만나는 문제

### "java 명령을 찾을 수 없습니다" 에러
```bash
source activate-env.sh    # 환경 활성화부터
```

### Spring Boot 가 18080 포트로 못 뜸
```bash
lsof -tiTCP:18080 | xargs kill   # 기존 점유 프로세스 종료
```

### 프론트 에서 "❌ 연결 실패" 가 보임
- 백엔드가 떠 있는지 확인: 터미널에서 `curl http://localhost:18080/api/hello`
- CORS 에러가 콘솔에 보이면 `WebConfig.java` 의 `allowedOrigins` 에 현재 프론트 포트가 포함됐는지 확인

### Gradle 빌드가 처음에 너무 오래 걸림
정상입니다. 첫 실행 시 Gradle Wrapper 가 7.x ~ 8.x 를 다운로드하고 의존성 모두 받느라 5~10분 걸릴 수 있습니다. 두 번째부터는 5~10초.

### "Module not found: tailwindcss" 같은 npm 에러
```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
```

### `setup-project.sh` 를 다시 돌리고 싶을 때
`backend/`, `frontend/` 가 이미 있으면 삭제 확인을 받습니다. 일부만 다시 만들고 싶으면 해당 폴더만 미리 지우고 실행하세요.

---

## 폴더별 역할 한눈에 (Phase 3 이후 채워질 위치)

```
backend/src/main/java/com/mybudget/backend/
├── controller/    ← Phase 5 에서 채움 (AccountController, TransactionController...)
├── service/       ← 비즈니스 로직
├── repository/    ← JPA Repository
├── domain/        ← 엔티티 (Phase 4 에서 14개 생성)
├── dto/           ← 요청/응답 DTO
├── config/        ← Security, Scheduler 등
├── exception/     ← ControllerAdvice
└── util/          ← SmsParser 등

frontend/src/
├── routes/        ← Phase 6 에서 채움 (HomePage, CalendarPage...)
├── components/    ← AmountInput, CategoryGrid, TxCard...
├── features/      ← 도메인별 (accounts/, transactions/, budgets/...)
├── api/           ← REST 호출 함수 모음
├── stores/        ← Zustand 슬라이스
├── hooks/         ← 커스텀 훅
├── utils/         ← 포맷터, 헬퍼
├── constants/     ← 색상, 카테고리 기본값
└── styles/        ← 전역 CSS
```

---

## 다음 단계

Phase 2 보일러플레이트가 정상 동작한다면, **Phase 3 (기능 명세 확정)** → **Phase 4 (JPA 엔티티 14개 코드 작성)** 로 진행할 수 있습니다.

Phase 4 진행 시 자동으로:
- `domain/` 에 14개 엔티티 클래스
- `repository/` 에 14개 Repository 인터페이스
- `resources/data.sql` 에 기본 카테고리/계좌 시드 데이터

가 생성되도록 도와드릴 수 있습니다.
