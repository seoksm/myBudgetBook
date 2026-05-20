# MyBudgetBook

> 반응형 웹 가계부 — 수입·지출·예산 관리 + 카드 SMS 자동 입력 + PWA 설치

**Spring Boot 3.5 (Java 21)** 백엔드 + **React 19 + Vite + Tailwind v4** 프론트엔드로 만든 로그인 기반 가계부 앱입니다. 모바일/태블릿/PC 모두 지원하며, 홈 화면에 추가하면 네이티브 앱처럼 동작합니다.

---

## 빠른 시작 (이미 설치된 상태)

매일 개발할 때는 두 줄이면 됩니다:

```bash
cd ~/claude/budget_book_codex
source activate-env.sh

# 터미널 A — 백엔드 (18080)
cd backend && ./gradlew bootRun

# 터미널 B — 프론트엔드 (15173)
cd frontend && npm run dev
```

브라우저: <http://localhost:15173>

처음 접속하면 `/login`으로 이동합니다. 회원가입 후 발급된 토큰이 브라우저 localStorage에 저장되고, 이후 API 요청에는 `Authorization: Bearer ...` 헤더가 자동으로 붙습니다.

---

## 처음 셋업하는 경우 (다른 PC / 새 컴퓨터)

```bash
# 1) 환경 설치 (Java 21 + Node 24 + Visual Studio Code 등을 tools/ 격리 설치)
bash install-dev-env.sh
bash check-dev-env.sh        # 점검

# 2) 환경 활성화 (새 터미널마다)
source activate-env.sh

# 3) 백엔드 + 프론트 보일러플레이트 생성
bash setup-project.sh

# 4) 도메인 14 엔티티 + 시드 데이터
bash setup-phase4-domain.sh

# 5) REST API 컨트롤러 + Swagger
bash setup-phase5-api.sh

# 6) 프론트엔드 화면
bash setup-phase6-frontend.sh

# 7) SMS 파서 (선택)
bash setup-phase7-sms.sh

# 8) PWA 설정 (선택)
bash setup-phase8-pwa.sh
```

---

## 폴더 구조

```
budget_book_codex/
├── README.md                          ← (이 문서)
├── 가계부앱_개발계획.md                 메인 설계 문서
│
├── 환경 스크립트 (Phase 1)
│   ├── install-dev-env.sh             tools/ 에 Java/Node/VSCode 설치
│   ├── check-dev-env.sh               환경 점검
│   ├── activate-env.sh                ← 매 터미널마다 source 필요
│   └── tools/                          격리된 개발 도구 (gitignore)
│
├── 자동화 스크립트 (Phase 2~8)
│   ├── setup-project.sh               (Phase 2) Spring Boot + React 보일러플레이트
│   ├── setup-phase4-domain.sh         (Phase 4) JPA 엔티티 14 + 시드
│   ├── setup-phase5-api.sh            (Phase 5) REST API + Swagger
│   ├── setup-phase6-frontend.sh       (Phase 6) 프론트 화면
│   ├── setup-phase7-sms.sh            (Phase 7) SMS 파서
│   └── setup-phase8-pwa.sh            (Phase 8) PWA 설치
│
├── Phase별 상세 가이드
│   ├── Phase1-사용가이드.md            (환경 구축 상세)
│   ├── Phase2-사용가이드.md            (보일러플레이트)
│   ├── Phase4-사용가이드.md            (도메인 모델)
│   ├── Phase5-사용가이드.md            (REST API)
│   ├── Phase6-사용가이드.md            (프론트엔드)
│   ├── Phase7-사용가이드.md            (SMS 파서)
│   └── Phase8-사용가이드.md            (PWA)
│
├── backend/                            Spring Boot 3.5 + Java 21
│   ├── build.gradle
│   ├── src/main/
│   │   ├── java/com/mybudget/backend/
│   │   │   ├── BackendApplication.java
│   │   │   ├── domain/                14 엔티티 + 4 enum
│   │   │   ├── repository/             14 JPA Repository
│   │   │   ├── service/                10 비즈니스 서비스 + SmsParserService
│   │   │   ├── controller/             REST 컨트롤러 + AuthController + HelloController
│   │   │   ├── dto/                    Java record DTO + AuthDto
│   │   │   ├── exception/              GlobalExceptionHandler
│   │   │   └── config/                 WebConfig, AuthInterceptor, OpenApiConfig
│   │   └── resources/
│   │       ├── application.yml
│   │       └── data.sql                시드 (카테고리 21, 가맹점 33, SMS 8)
│   └── data/                            H2 DB 파일 (← 이 복사본은 mybudget_codex DB 사용)
│
└── frontend/                           React 19 + Vite + Tailwind v4
    ├── package.json
    ├── vite.config.ts                  (PWA + 프록시 + Tailwind)
    ├── index.html                      (PWA 메타)
    ├── public/
    │   ├── budget-icon.svg             앱 아이콘
    │   └── favicon.svg
    └── src/
        ├── main.tsx
        ├── App.tsx                     Router + QueryClient + 다크모드
        ├── index.css                   Tailwind v4 + Pretendard 폰트
        ├── api/                        API 호출 함수 (axios + react-query + 인증 헤더)
        ├── components/                 공용 컴포넌트
        │   ├── AppLayout.tsx           모바일 하단탭 ↔ PC 사이드바
        │   ├── ProtectedRoute.tsx      로그인 보호 라우트
        │   ├── PageHeader.tsx
        │   ├── AmountInput.tsx         천 단위 + "원" suffix
        │   ├── CategoryGrid.tsx
        │   ├── TxCard.tsx
        │   ├── MonthPicker.tsx         년/월 선택기 (재사용)
        │   ├── EmptyState.tsx
        │   ├── Skeleton.tsx
        │   └── InstallBanner.tsx       PWA 설치 유도
        ├── routes/                     페이지 라우트
        │   ├── HomePage.tsx            홈 대시보드
        │   ├── TransactionsPage.tsx    거래내역 + 검색 + 월 필터 (URL 보존)
        │   ├── AddTransactionPage.tsx  거래 추가 + 예금 간 이체
        │   ├── TransactionDetailPage.tsx  거래 수정/삭제
        │   ├── CalendarPage.tsx        달력 뷰
        │   ├── StatsPage.tsx           통계 (기간 범위 필터)
        │   ├── BudgetsPage.tsx         예산 (월 필터 + 진행률)
        │   ├── AccountsPage.tsx        계좌 CRUD + 체크카드 연결 예금
        │   ├── AccountDetailPage.tsx   자산별 수입/지출/이체 내역
        │   ├── CategoriesPage.tsx      카테고리 CRUD
        │   ├── SmsPage.tsx             SMS 붙여넣기 일괄 등록
        │   ├── SettingsPage.tsx        사용자/로그아웃 + 다크모드
        │   └── LoginPage.tsx           로그인/회원가입
        ├── stores/uiStore.ts           Zustand (다크모드 + localStorage)
        ├── stores/authStore.ts         Zustand (토큰/사용자 + localStorage)
        ├── hooks/usePwaInstall.ts      beforeinstallprompt + iOS 감지
        ├── utils/                      format.ts, date.ts
        └── constants/theme.ts          색상/라벨 상수
```

---

## 주요 기능

### 인증

- ✅ 회원가입/로그인 (`/api/auth/register`, `/api/auth/login`)
- ✅ PBKDF2 비밀번호 해시 저장
- ✅ HMAC-SHA256 서명 토큰 발급/검증
- ✅ `/api/hello`, 로그인/회원가입을 제외한 API 보호
- ✅ 프론트 보호 라우팅: 미로그인 사용자는 `/login`으로 이동
- ✅ 설정 화면에서 현재 사용자 확인 및 로그아웃
- ✅ 계좌/카테고리/태그/거래/예산/이체/반복거래/저축목표/즐겨찾기/SMS 가맹점 규칙 사용자별 분리
- ✅ 회원가입 또는 첫 인증 요청 시 사용자별 기본 계좌/카테고리/가맹점 규칙 자동 생성
- ✅ 기존 단일 사용자 데이터는 첫 로그인 사용자에게 한 번 귀속되도록 보정

### 거래 관리

- ✅ 수입/지출/이체 3종 + 6종 계좌 타입 (현금/예금/체크/신용/투자/대출)
- ✅ 거래 추가 시 **계좌 잔액 자동 재계산** (수정/삭제 시 되돌림 처리)
- ✅ 이체는 **보내는 예금/받는 예금**을 분리해 예금 계좌 간 이동으로 처리
- ✅ 체크카드는 **연결 예금**을 지정하고, 체크카드 지출 시 연결 예금에서 실제 출금
- ✅ 체크카드/신용카드는 잔액 관리 대상에서 제외하고, 카드 사용 내역만 기록
- ✅ 자산별 상세 화면에서 계좌별 수입/지출/이체 내역 월별 조회
- ✅ 거래내역 일자별 그룹핑 + 일별 합계 (+/-)
- ✅ 메모/가맹점 통합 검색
- ✅ 거래 상세 → 수정 → 저장 시 **이전 필터 그대로 복귀** (URL 쿼리 보존)

### 기간 조회

- ✅ 거래내역: 월별 (◀ YYYY년 M월 ▶)
- ✅ 예산: 월별 (해당 월 예산 진행률)
- ✅ 통계: **시작 년월 ~ 종료 년월** 범위 조회 (자동 보정)

### 카테고리 & 예산

- ✅ 시드 21개 (지출 15 + 수입 6) — 식비, 카페/간식, 교통, 통신, 주거, 의료, 교육, 쇼핑, 의류, 여가, 경조사, 보험, 세금, 기부, 기타, 월급, 보너스, 부수입, 용돈, 이자, 기타
- ✅ 추가/수정/삭제 + 색상 커스텀
- ✅ 월 예산 설정 + 카테고리별 진행률 바 (80% 노랑 / 100%+ 빨강)

### 통계 & 시각화

- ✅ 카테고리별 파이차트 (recharts)
- ✅ 이달 수입/지출/잔액 카드
- ✅ 달력 뷰 (월 캘린더에 일별 ±금액)
- ✅ 예산 진행률 TOP 3 (홈 대시보드)

### SMS 자동 입력 (차별화)

- ✅ 카드 SMS 텍스트 붙여넣기 → **8개 카드사** (KB국민/신한/삼성/현대/롯데/우리/하나/BC) 자동 인식
- ✅ 가맹점 → 카테고리 자동 매핑 (시드 33개: 스타벅스/배달의민족/이마트/넷플릭스 등)
- ✅ 다중 라인 일괄 파싱 + 미리보기 + 선택 저장
- ✅ "누적660,530원" 같은 꼬리 정보 자동 제거
- ✅ 새 카드사/가맹점 패턴은 H2 콘솔에서 즉시 추가 (재배포 불필요)

### PWA (앱처럼 사용)

- ✅ 홈 화면 추가 (Android Chrome / 데스크톱 / iOS Safari)
- ✅ 풀스크린 실행 (주소창 없음)
- ✅ 오프라인 앱 셸 캐시 (정적 자산 precache + CDN 캐시)
- ✅ API 요청은 Service Worker가 가로채지 않도록 분리해 거래 저장/수정 안정성 유지
- ✅ 새 버전 감지 시 앱 안에서 "지금 적용" 배너 표시
- ✅ 개발/프리뷰 모두 `15173` 포트로 통합
- ✅ 개발 서버에서는 기존 `api-cache` 자동 정리
- ✅ 다크모드 (localStorage 영속)

### 반응형 UI

- 모바일 (< 768px): 하단 5개 탭 (홈/내역/+/통계/설정)
- PC/태블릿 (≥ 768px): 좌측 사이드바 (10개 메뉴)
- Pretendard 한글 폰트 (CDN)

---

## REST API 엔드포인트

전체 목록은 <http://localhost:18080/swagger-ui.html> 에서 확인.

대부분의 `/api/**` 엔드포인트는 로그인 토큰이 필요합니다.

### 인증

| 메서드 | 경로 | 설명 |
|---|---|---|
| POST | `/api/auth/register` | 회원가입 + 토큰 발급 |
| POST | `/api/auth/login` | 로그인 + 토큰 발급 |
| GET | `/api/auth/me` | 현재 로그인 사용자 |
| POST | `/api/auth/logout` | 클라이언트 토큰 삭제용 로그아웃 |

### 핵심

| 메서드 | 경로 | 설명 |
|---|---|---|
| GET / POST | `/api/accounts` | 계좌 목록/추가 |
| PUT / DELETE | `/api/accounts/{id}` | 계좌 수정/삭제 |
| GET | `/api/accounts/{id}/activities?from=&to=` | 자산별 수입/지출/이체 내역 |
| GET / POST | `/api/categories` | 카테고리 (`?kind=EXPENSE` 필터) |
| GET | `/api/transactions?from=&to=&accountId=&categoryId=` | 기간/필터 조회 |
| GET | `/api/transactions/search?q=` | 메모 검색 |
| POST / PUT / DELETE | `/api/transactions[/{id}]` | 거래 CRUD (잔액 자동) |
| GET / POST | `/api/transfers` | 예금 간 이체 조회/생성 (양쪽 잔액 자동) |
| GET | `/api/budgets?year=&month=` | 월 예산 |
| POST | `/api/budgets` | 예산 설정 (upsert) |
| GET | `/api/budgets/progress?year=&month=` | 카테고리별 진행률 |
| GET | `/api/stats/monthly?year=&month=` | 월 요약 |
| GET | `/api/stats/by-category?from=&to=&kind=` | 카테고리 합계 (파이차트용) |
| GET | `/api/stats/calendar?year=&month=` | 달력 뷰 데이터 |
| POST | `/api/sms/parse` | SMS 텍스트 파싱 |

### 부가

`/api/tags`, `/api/recurring-rules`, `/api/savings-goals`, `/api/favorites`, `/api/transfers` 도 모두 CRUD 가능.

---

## 도메인 모델 (14 엔티티 + 4 enum)

```
[Enum]
  AccountType     CASH / DEPOSIT / CHECK_CARD / CREDIT_CARD / INVESTMENT / LOAN
  CategoryKind    INCOME / EXPENSE
  TransactionKind INCOME / EXPENSE / TRANSFER
  TransactionSource MANUAL / SMS / RECURRING

[Entity]
  User            email, passwordHash, displayName
  Account         name, type, balance, statementDay, paymentDay, color, linkedDepositAccount
  Category        name, kind, parent(self-ref), icon, color
  Tag             name, color
  Transaction     kind, amount, account, balanceAccount, category, occurredAt, source, tags[]
  TransactionAttachment  fileUrl, sizeBytes
  TransactionSplit       category, amount  (한 결제 → 여러 카테고리)
  Transfer        fromAccount, toAccount, amount  (예금 간 이동)
  Budget          year, month, category, amount (Unique key)
  RecurringRule   name, dayOfMonth, startDate, endDate, active
  SavingsGoal     name, targetAmount, dueDate
  FavoriteTransaction  label, amount, account, category
  MerchantRule    pattern, category, priority  (SMS 가맹점 매핑)
  SmsParserRule   cardName, regexPattern, enabled  (카드사 정규식)
```

---

## SMS 파싱 사용법

1. 카드사 결제 알림 SMS 를 그대로 복사
2. 가계부 `/sms` 페이지 텍스트 영역에 붙여넣기 (여러 건 가능)
3. **파싱하기** 버튼 → 미리보기 카드들 표시
4. 체크박스로 저장할 항목 선택 + 계좌 선택
5. **N건 저장** 버튼 → 일괄 등록 + 잔액 자동 갱신

**테스트 샘플:**
```
[Web발신] KB국민카드(1234) 12,300원 일시불 12/05 14:23 스타벅스
신한카드 승인 홍길동 5,500원(일시불) 05/17 12:34 GS25
삼성카드 35,000원 일시불 05/16 19:45 배달의민족
```

→ 3건 파싱 + 카테고리 자동 추천 (스타벅스→카페/간식, GS25→식비, 배달의민족→식비)

**새 카드사 추가** (H2 콘솔에서):
```sql
INSERT INTO sms_parser_rules (card_name, regex_pattern, enabled, priority)
VALUES ('카카오뱅크',
        '카카오뱅크.*?(?<amount>[\d,]+)원[\s]*(?<date>\d{1,2}/\d{1,2})\s+(?<time>\d{2}:\d{2})\s+(?<store>.+)',
        TRUE, 100);
```

---

## PWA 설치 방법

**데스크톱 Chrome/Edge**
- 주소창 우측의 ⊕ 설치 아이콘 또는 화면 하단 "앱으로 설치하기" 배너 → 설치

**Android Chrome**
- 자동 프롬프트 또는 메뉴 → "앱 설치"

**iOS Safari** (자동 프롬프트 불가)
- 하단 공유 → "홈 화면에 추가"

설치 후 풀스크린 모드로 실행됩니다.

---

## 트러블슈팅

### 백엔드 안 뜸: `Failed to initialize JPA EntityManagerFactory`
- `application.yml` 의 `spring.datasource.url` 확인
- `spring.jpa.database-platform: org.hibernate.dialect.H2Dialect` 명시

### Swagger UI 500 에러
- `build.gradle` 의 `springdoc-openapi-starter-webmvc-ui` 버전 확인 (Spring Boot 3.5 → springdoc 2.8.0)

### 프론트 빈 페이지 / Tailwind 안 먹음
- `src/main.tsx` 가 `./index.css` import 하는지 확인
- `src/index.css` 첫 줄이 `@import "tailwindcss"` 인지 확인

### `/api/*` 가 403 또는 HTML 반환
- `vite.config.ts` 의 `server.proxy` 와 `preview.proxy` 가 모두 18080을 가리키는지
- 일상 개발은 `npm run dev` (port 15173) 사용
- PWA도 15173에서 동작하지만 `/api/**`는 Service Worker 캐시 대상에서 제외됨

### lucide-react 의 `Github` 등 import 에러
- 브랜드 아이콘이 제거됨 → `FileText`, `Code`, `Globe` 등으로 대체

### Recharts Tooltip 타입 에러
- `formatter={(v) => typeof v === 'number' ? fmtWon(v) : String(v ?? 0)}`

### "원" 글자와 숫자 겹침
- AmountInput 에서 input 에 `pr-12`, "원"에 `bottom-3` 적용됨

### PWA 변경이 안 보임
- `npm run dev`를 재시작한 뒤 `http://localhost:15173`에서 확인
- 앱 화면의 "새 버전이 준비됐습니다" 배너에서 `지금 적용`
- 그래도 안 되면 브라우저 Application 탭에서 Service Worker unregister + Clear site data

### 거래 수정 후 목록으로 갈 때 필터가 리셋됨
- TxCard 가 location.state.from 으로 현재 URL 전달
- TransactionDetailPage 가 `navigate(backTo, { replace: true })`

### 체크카드 지출 저장이 실패함
- 자산 화면에서 해당 체크카드에 연결 예금을 먼저 지정
- 연결 예금은 `DEPOSIT` 타입 계좌만 가능

### 이체 저장이 실패함
- 보내는 계좌와 받는 계좌가 서로 달라야 함
- 현재 이체는 자산 이동으로 처리하므로 양쪽 모두 `DEPOSIT` 타입이어야 함

---

## 폴더 정리 명령 (사용자 직접 실행)

빌드 캐시와 백업 파일을 정리하려면:

```bash
cd ~/claude/budget_book_codex

# 1. 백업 파일 제거 (sed -i.bak 가 만든 임시 파일들)
rm -f setup-phase*.sh.bak*
rm -f backend/build.gradle.bak

# 2. 빌드 산출물 제거 (다음 빌드 시 재생성)
rm -rf frontend/dist
rm -rf backend/build

# 3. (선택) Phase 가이드를 docs/ 폴더로 모으기
mkdir -p docs && mv Phase*-사용가이드.md docs/
```

**보존해야 할 폴더 (절대 삭제 X):**
- `backend/data/` — H2 DB 파일 (실제 거래 데이터, 이 복사본은 `mybudget_codex` 사용)
- `tools/` — 격리된 개발 도구 (JDK, Node, VSCode)
- `frontend/node_modules/` — 패키지 (대용량이지만 재설치 시간 김)

---

## 검증

타입 + 빌드 점검:

```bash
# 프론트엔드 TypeScript 검증
cd frontend && ./node_modules/.bin/tsc --noEmit

# 백엔드 빌드 검증
cd backend && ./gradlew build -x test

# 환경 점검
bash check-dev-env.sh

# PWA 산출물 확인
cd frontend && npm run build
rg "api-cache|/api" dist/sw.js
```

---

## 향후 개선 가능 항목

- [ ] 운영 DB 전환 (H2 → MySQL/PostgreSQL with Flyway)
- [ ] 영수증 이미지 업로드 (TransactionAttachment 엔티티는 이미 있음)
- [ ] 반복 거래 자동 등록 스케줄러 (`@Scheduled` 추가)
- [ ] 거래 분할 기능 (한 결제를 여러 카테고리로 — TransactionSplit 엔티티는 이미 있음)
- [ ] CSV/엑셀 내보내기
- [ ] 부부/가족 공유 가계부
- [ ] Web Push 알림 (예산 80% 도달 시)
- [ ] 배포 (Railway / Render / Fly.io)

---

## 기술 스택 요약

| 영역 | 기술 |
|---|---|
| **백엔드** | Spring Boot 3.5, Java 21, JPA/Hibernate, Lombok, Validation, Actuator |
| **DB** | H2 (개발/현재), MySQL 8 (운영 옵션) |
| **API 문서** | Springdoc OpenAPI 2.8 → Swagger UI |
| **프론트엔드** | React 19, TypeScript, Vite 8 |
| **상태 관리** | TanStack Query 5 (서버), Zustand 5 (UI) |
| **라우팅** | React Router 7 |
| **스타일** | Tailwind CSS v4 + `@custom-variant dark` |
| **차트** | Recharts 3 |
| **아이콘** | lucide-react |
| **폼** | react-hook-form + zod (미사용, 추후 활용 가능) |
| **PWA** | vite-plugin-pwa 1.3 + Workbox |
| **폰트** | Pretendard (CDN) |

---

## 라이선스

개인 프로젝트 — MIT 또는 비공개 사용.

---

**개발 일자:** 2026-05-17 ~ 2026-05-19
**문서 갱신:** 2026-05-19
