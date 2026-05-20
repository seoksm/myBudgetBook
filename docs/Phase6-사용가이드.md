# Phase 6 — 프론트엔드 화면 자동 생성 사용 가이드

가계부의 모든 화면(레이아웃 + 10개 페이지 + 다크모드 + API 연동)을 한 번에 만들어 주는 스크립트입니다.

## 한 줄 요약

```bash
cd ~/claude/budget_book_codex
source activate-env.sh
bash setup-phase6-frontend.sh

# 두 터미널 띄우기
# 터미널 A: cd backend && ./gradlew bootRun
# 터미널 B: cd frontend && npm run dev

open http://localhost:15173
```

## 사전 조건

| 조건 | 확인 |
|---|---|
| Phase 5 백엔드가 18080 에서 응답 | `curl http://localhost:18080/api/accounts` |
| frontend/ 가 존재 + Vite 동작 | `ls frontend/package.json` |
| Phase 1 환경 활성화 | `source activate-env.sh` |

## 생성되는 것

### API 호출 함수 9개 (`src/api/`)

| 파일 | 역할 |
|---|---|
| `client.ts` | axios 베이스 (에러 메시지 자동 추출) |
| `types.ts` | TypeScript 타입 (Account, Category, Transaction, ...) |
| `accounts.ts` | 계좌 CRUD |
| `categories.ts` | 카테고리 CRUD |
| `transactions.ts` | 거래 조회/검색/CRUD |
| `transfers.ts` | 이체 |
| `budgets.ts` | 예산 + 진행률 |
| `tags.ts` | 태그 |
| `stats.ts` | 월간/카테고리/달력 통계 |

### 공통 컴포넌트 7개 (`src/components/`)

| 컴포넌트 | 역할 |
|---|---|
| `AppLayout` | **모바일 하단 5탭 + PC 좌측 사이드바** 자동 전환 |
| `PageHeader` | 페이지 상단 (뒤로가기 + 제목 + 우측 액션) |
| `AmountInput` | 천 단위 자동 포맷팅 큰 금액 입력 |
| `CategoryGrid` | 4열 카테고리 아이콘 그리드 |
| `TxCard` | 거래 1건 카드 (수입 ↑녹색 / 지출 ↓빨강 / 이체 ↔파랑) |
| `EmptyState` | 빈 화면 일러스트 + 안내 |
| `Skeleton` | 로딩 스켈레톤 |

### 페이지 10개 (`src/routes/`)

| 경로 | 화면 | 주요 기능 |
|---|---|---|
| `/` | **홈 대시보드** | 이달 수입/지출/잔액 카드 · 자산 4종 · 예산 진행률 TOP3 · 최근 거래 5건 |
| `/transactions` | **거래내역** | 검색 · 일자별 그룹핑 · 일별 합계 |
| `/transactions/new` | **거래 추가** | 수입/지출/이체 토글 · 큰 키패드 · 카테고리 그리드 · 저장 시 잔액 자동 갱신 |
| `/calendar` | **달력 뷰** | 월 캘린더에 일별 ±금액 표시 · 월 이동 |
| `/stats` | **통계** | 파이차트 + 카테고리별 합계 (수입/지출 토글) |
| `/budgets` | **예산** | 카테고리별 진행률 바 (80% 노랑, 100%+ 빨강) |
| `/accounts` | **자산** | 계좌 리스트 + 잔액 |
| `/categories` | **카테고리** | 수입/지출 토글 + 아이콘 그리드 |
| `/settings` | **설정** | 다크모드 토글 · H2 콘솔/Swagger UI 링크 |
| `/sms` | SMS 붙여넣기 | Phase 7에서 본격 구현 (placeholder) |

### 핵심 기술 통합

- **React Router 7** — 중첩 라우팅, `Outlet` 으로 레이아웃 공유
- **React Query** — 모든 API 호출에 캐싱 + 자동 invalidation
  - 거래 추가 시 `transactions`, `stats`, `accounts` 쿼리 무효화 → 모든 화면 자동 갱신
- **Zustand + persist** — 다크모드 상태를 `localStorage` 에 자동 저장
- **Tailwind v4 + `@custom-variant dark`** — `dark:` prefix 로 자동 다크모드 스타일
- **Pretendard** — CDN으로 한글 폰트 자동 로드

### 반응형 레이아웃

| 폭 | 레이아웃 |
|---|---|
| 모바일 (< 768px) | 하단 탭바 5개 (홈/내역/`+`추가/통계/설정) |
| 태블릿 + PC (≥ 768px) | 좌측 사이드바 10개 메뉴 + 메인 영역 |

## 실행 후 동작 검증

### 1) 양쪽 다 띄우기

```bash
# 터미널 A — 백엔드
cd ~/claude/budget_book_codex/backend
source ~/claude/budget_book_codex/activate-env.sh
./gradlew bootRun

# 터미널 B — 프론트
cd ~/claude/budget_book_codex/frontend
source ~/claude/budget_book_codex/activate-env.sh
npm run dev
```

### 2) 브라우저 확인

http://localhost:15173 열기.

**확인 포인트:**
- [ ] 홈 화면에 "0원" 카드들이 보이는가 (시드 데이터로 인해 잔액 0)
- [ ] 자산 섹션에 "현금 지갑", "주거래 은행" 두 계좌가 보이는가
- [ ] 하단 + 버튼 클릭 → 거래 추가 화면이 뜨는가
- [ ] 금액 5000 입력 → 계좌/카테고리 선택 → 저장
- [ ] 홈으로 돌아왔을 때 잔액이 -5,000원으로 갱신됐는가
- [ ] 우측 상단 (또는 사이드바 설정) 에서 다크모드 토글 동작

### 3) 모바일 뷰

Chrome 개발자도구 F12 → 모바일 토글 (⌘⇧M) → iPhone 14 선택. 하단 탭바가 나타나야 정상.

### 4) 통계 확인

거래 몇 개 추가 후 `/stats` 진입 → 파이차트 렌더링 확인.

## 자주 만나는 문제

### "Network Error" / "Connection refused"
백엔드(18080)가 안 떠 있는 상태. Phase 5 의 `./gradlew bootRun` 부터 다시 실행.

### Vite 가 15173 이 아닌 15174 로 뜸
이미 15173 점유 중이라 그렇습니다. 자동으로 옮겨가는 건 정상이지만, CORS 설정은 15173 만 허용하므로 충돌이 날 수 있습니다. 점유 프로세스를 종료:
```bash
kill $(lsof -tiTCP:15173)
```

### 다크모드가 안 켜짐
브라우저 localStorage 확인: `localStorage.getItem('budget-ui')` 로 `darkMode: true` 가 저장되어야 함. 안 되면 캐시 클리어 후 재시도.

### Tailwind 클래스가 적용 안 됨
`src/styles/index.css` 가 `main.tsx` 에서 import 되었는지 확인:
```ts
// main.tsx
import './styles/index.css';
```

### 모든 카테고리가 같은 색
시드 데이터의 `color` 필드 (`#ef4444` 등)가 입력되었는지 H2 콘솔에서 확인. 없으면 Phase 4 의 `data.sql` 이 안 돌은 것 → `backend/data/` 폴더 지우고 재시작.

### React Router future flag 경고
무시해도 됩니다. v7 에서 default 될 동작에 대한 안내 경고입니다.

## 다음 단계

- **Phase 7** — SMS 붙여넣기 페이지 완성 (백엔드 정규식 8개는 이미 준비됨)
- **Phase 8** — PWA 설치 / Web Push 알림 / JWT 인증

`Phase 7 시작해줘` 또는 다른 단계로 진행하세요.
