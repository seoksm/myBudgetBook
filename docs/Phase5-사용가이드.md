# Phase 5 — REST API 레이어 자동 생성 사용 가이드

가계부의 모든 REST 엔드포인트(Controller + Service + DTO + 예외처리 + Swagger UI)를 한 번에 만들어 주는 스크립트입니다.

## 한 줄 요약

```bash
cd ~/claude/budget_book_codex
source activate-env.sh
bash setup-phase5-api.sh
cd backend && ./gradlew bootRun
```

## 사전 조건

| 조건 | 확인 |
|---|---|
| Phase 4 완료 (entity/repository 폴더에 파일 존재) | `ls backend/src/main/java/com/mybudget/backend/domain/ \| wc -l` → 18 |
| `application.yml` 에 `defer-datasource-initialization: true` | `grep defer backend/src/main/resources/application.yml` |
| 환경 활성화 | `source activate-env.sh` |

## 생성되는 것 (총 35개 파일)

### Controller 10개

| 클래스 | URL 베이스 | 주요 엔드포인트 |
|---|---|---|
| `AccountController` | `/api/accounts` | GET/POST/PUT/DELETE |
| `CategoryController` | `/api/categories` | GET `?kind=EXPENSE`, CRUD |
| `TagController` | `/api/tags` | GET, POST(중복은 기존 반환), DELETE |
| `TransactionController` | `/api/transactions` | GET `?from=&to=&accountId=&categoryId=`, POST/PUT/DELETE, GET `/search?q=` |
| `TransferController` | `/api/transfers` | GET, POST, DELETE |
| `BudgetController` | `/api/budgets` | GET/POST/DELETE, GET `/progress?year=&month=` |
| `RecurringRuleController` | `/api/recurring-rules` | CRUD |
| `SavingsGoalController` | `/api/savings-goals` | GET, POST, DELETE |
| `FavoriteTransactionController` | `/api/favorites` | GET, POST, DELETE |
| `StatsController` | `/api/stats` | GET `/monthly`, `/by-category`, `/calendar` |

### Service 10개 (비즈니스 로직 + `@Transactional`)

**TransactionService 의 핵심: 잔액 자동 재계산**
- POST → 거래 추가 시 계좌 잔액 ± amount
- PUT → 기존 거래 효과 되돌린 후 새 값 적용 (계좌/카테고리/금액/종류 변경 모두 안전)
- DELETE → 삭제 시 잔액 되돌림

**TransferService**:
- 출금 계좌 −amount, 입금 계좌 +amount 자동 처리
- 동일 계좌 이체는 `BusinessException` 으로 차단

**BudgetService.progress()**: 이달 카테고리별 지출 합계 ÷ 예산 × 100 → 진행률(%)

**StatsService**: 월간 요약 / 카테고리 파이차트 데이터 / 달력 뷰 데이터 생성

### DTO (Java 21 record)

각 도메인마다 `XxxDto.java` 한 파일에 `CreateRequest`, `UpdateRequest`, `Response` 를 묶어둠. 검증은 `@NotNull`, `@NotBlank`, `@Positive`, `@Size`, `@Min/@Max` 등 표준 Bean Validation.

### 공통 인프라

| 파일 | 역할 |
|---|---|
| `dto/ErrorResponse.java` | 표준 에러 응답 (`timestamp`, `status`, `code`, `message`, `path`, `errors[]`) |
| `exception/NotFoundException.java` | 404 — 리소스 없음 |
| `exception/BusinessException.java` | 400 — 비즈니스 규칙 위반 (코드 포함) |
| `exception/GlobalExceptionHandler.java` | `@RestControllerAdvice` 로 위 예외 + Validation 자동 변환 |
| `config/OpenApiConfig.java` | Springdoc OpenAPI 메타정보 (제목/버전/서버) |

### `build.gradle` 패치

`dependencies { ... }` 블록 안에 추가:
```gradle
implementation 'org.springdoc:springdoc-openapi-starter-webmvc-ui:2.6.0'
```

## 실행 후 동작 검증

### 1) Swagger UI (가장 직관적)

```
http://localhost:18080/swagger-ui.html
```

10개 도메인의 모든 엔드포인트가 시각적으로 표시됨. 우측 **"Try it out"** 버튼으로 브라우저에서 직접 호출 가능.

### 2) curl 로 빠른 확인

```bash
# 기본 데이터 확인 (Phase 4 시드)
curl http://localhost:18080/api/accounts
curl 'http://localhost:18080/api/categories?kind=EXPENSE'

# 거래 추가 (잔액 자동 갱신)
curl -X POST http://localhost:18080/api/transactions \
  -H 'Content-Type: application/json' \
  -d '{
    "kind": "EXPENSE",
    "amount": 5500,
    "accountId": 1,
    "categoryId": 1,
    "memo": "점심 백반",
    "occurredAt": "2026-05-17T12:30:00"
  }'

# 잔액이 -5500 으로 변했는지 확인
curl http://localhost:18080/api/accounts

# 통계
curl 'http://localhost:18080/api/stats/monthly?year=2026&month=5'
curl 'http://localhost:18080/api/stats/calendar?year=2026&month=5'
```

### 3) REST Client 확장 (.http 파일)

Phase 2 에서 만든 `http/hello.http` 와 같이 도메인별로 `.http` 파일을 추가하면 클릭 한 번으로 테스트 가능:

```http
### 거래 추가
POST http://localhost:18080/api/transactions
Content-Type: application/json

{
  "kind": "EXPENSE",
  "amount": 12300,
  "accountId": 1,
  "categoryId": 2,
  "memo": "스타벅스 아메리카노",
  "occurredAt": "2026-05-17T09:15:00",
  "tags": ["테스트"]
}

### 이달 통계
GET http://localhost:18080/api/stats/monthly?year=2026&month=5
```

## 자주 만나는 문제

### Swagger UI 가 404
```bash
grep springdoc backend/build.gradle
# implementation 'org.springdoc:springdoc-openapi-starter-webmvc-ui:2.6.0'
# 위 줄이 있어야 함. 없으면 스크립트 다시 실행.
```
의존성을 추가했으면 `./gradlew clean bootRun` 으로 클린 빌드 권장.

### "Validation failed" 400 응답
응답의 `errors[]` 필드에 어느 필드가 어떤 이유로 실패했는지 표시됩니다:
```json
{"errors":[{"field":"amount","message":"must be positive","rejectedValue":-1}]}
```

### "Category not found" 404 (거래 추가 시)
H2 콘솔에서 카테고리 ID 확인:
```sql
SELECT id, name, kind FROM categories ORDER BY id;
```

### 잔액이 이상하게 보임
거래 수정/삭제 시 잔액 재계산은 `TransactionService` 가 자동 처리합니다. 그래도 어긋났다면 (개발 중 직접 SQL 로 손댄 경우) 다음 쿼리로 재계산:
```sql
UPDATE accounts SET balance = (
  SELECT COALESCE(SUM(CASE WHEN kind='INCOME' THEN amount ELSE -amount END), 0)
  FROM transactions WHERE account_id = accounts.id AND kind != 'TRANSFER'
);
```

### Lombok 빌더가 인식 안 됨
Visual Studio Code 에서 빨간 줄이 보이면:
1. `code --list-extensions | grep lombok` 으로 확장 확인
2. `code --install-extension vscjava.vscode-lombok`
3. Visual Studio Code 재시작

## 다음 단계

- **Phase 6 (프론트엔드 화면)** — React Router + Tailwind 모바일 퍼스트 UI, React Query 로 위 API 호출
- **Phase 7 (SMS 파서 본격 구현)** — `SmsParserService` 만들고 `/api/sms/parse` 엔드포인트 추가
- **Phase 8 (PWA/다크모드/인증)** — JWT 인증, PWA 설치

`Phase 6 시작해줘` 또는 `Phase 7 시작해줘` 로 진행하세요.
