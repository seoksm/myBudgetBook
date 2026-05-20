# Phase 4 — 도메인 레이어 자동 생성 사용 가이드

가계부의 모든 데이터 구조(엔티티 + Repository + 시드 데이터)를 한 번에 만들어 주는 스크립트입니다.

## 한 줄 요약

```bash
cd ~/claude/budget_book_codex
source activate-env.sh
bash setup-phase4-domain.sh
```

## 사전 조건

| 조건 | 확인 |
|---|---|
| Phase 2 완료 (`backend/` 가 존재) | `ls backend/` |
| Phase 1 환경 활성화 (Java 21) | `java -version` |

## 스크립트가 만들어 주는 것

### 1) Enum 4개 (`backend/src/main/java/com/mybudget/backend/domain/`)

| 파일 | 값 |
|---|---|
| `AccountType.java` | CASH / DEPOSIT / CHECK_CARD / CREDIT_CARD / INVESTMENT / LOAN |
| `CategoryKind.java` | INCOME / EXPENSE |
| `TransactionKind.java` | INCOME / EXPENSE / TRANSFER |
| `TransactionSource.java` | MANUAL / SMS / RECURRING |

### 2) JPA Entity 14개

| 엔티티 | 핵심 컬럼 | 비고 |
|---|---|---|
| `User` | email, passwordHash, displayName | 단일/다중 사용자 지원 |
| `Account` | name, type, balance, statementDay, paymentDay | 신용카드는 결제일 관리 |
| `Category` | name, kind, parent(self-ref), icon, color | 하위 카테고리 지원 |
| `Tag` | name, color | 자유 태그 (#여행 등) |
| `Transaction` | kind, amount, account, category, occurredAt, source, rawSms, installmentMonths, tags | 거래 본체 |
| `TransactionAttachment` | transaction, fileUrl | 영수증 사진 첨부 |
| `TransactionSplit` | transaction, category, amount | 한 결제를 여러 카테고리로 분할 |
| `Transfer` | fromAccount, toAccount, amount | 계좌 간 이체 |
| `Budget` | year, month, category, amount | 월별 예산 (Unique key) |
| `RecurringRule` | name, kind, amount, dayOfMonth, startDate, endDate, active | 고정지출/반복거래 |
| `SavingsGoal` | name, targetAmount, currentAmount, dueDate | 목표 저축 |
| `FavoriteTransaction` | label, kind, amount, account, category | 즐겨찾기 빠른 입력 |
| `MerchantRule` | pattern, category, priority | 가맹점→카테고리 자동 매핑 |
| `SmsParserRule` | cardName, regexPattern, enabled | 카드사별 SMS 정규식 |

**공통 특징:**
- Lombok `@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder`
- 생성/수정 시간은 `@CreationTimestamp` / `@UpdateTimestamp` 자동
- `Transaction` 에 3개 인덱스 (`occurredAt`, `account_id+occurredAt`, `category_id+occurredAt`) 자동 생성

### 3) Spring Data JPA Repository 14개 (`repository/`)

각 엔티티마다 `JpaRepository<T, Long>` 을 상속한 인터페이스. 자주 쓰는 쿼리 메서드가 미리 정의됨:

```java
// 예) TransactionRepository
List<Transaction> findByOccurredAtBetweenOrderByOccurredAtDesc(...);
List<Transaction> findByAccountIdAndOccurredAtBetweenOrderByOccurredAtDesc(...);
@Query("...") List<Transaction> searchByKeyword(@Param("keyword") String keyword);

// 예) RecurringRuleRepository (스케줄러용)
List<RecurringRule> findByActiveTrueAndDayOfMonth(Integer dayOfMonth);

// 예) BudgetRepository
List<Budget> findByYearAndMonth(Integer year, Integer month);
```

### 4) 시드 데이터 (`backend/src/main/resources/data.sql`)

앱 첫 실행 시 자동 로드. **중복 방지** 패턴(`WHERE NOT EXISTS`) 사용으로 재실행 안전.

| 데이터 | 개수 |
|---|---|
| 기본 계좌 | 2개 (현금 지갑, 주거래 은행) |
| 지출 카테고리 | 15개 (식비, 카페/간식, 교통, 통신, 주거/관리비, 의료/건강, 교육, 쇼핑, 의류/미용, 여가/문화, 경조사, 보험, 세금, 기부, 기타) |
| 수입 카테고리 | 6개 (월급, 보너스, 부수입, 용돈, 이자/배당, 기타) |
| 가맹점 자동 매핑 | 33개 (스타벅스/이디야/투썸/메가커피/GS25/CU/맥도날드/배달의민족/쿠팡/이마트/지하철/택시/카카오T/넷플릭스/CGV 등) |
| 카드사 SMS 정규식 | 8개 (KB국민/신한/삼성/현대/롯데/우리/하나/BC) |

### 5) `application.yml` 패치

`data.sql` 이 Hibernate 의 테이블 생성 이후에 실행되도록 설정 추가:

```yaml
spring:
  jpa:
    defer-datasource-initialization: true   # ← 추가
  sql:
    init:
      mode: always                          # ← 추가
      continue-on-error: false
```

## 실행 후 동작 검증

### 1) 백엔드 재시작
```bash
cd backend
./gradlew bootRun
```

콘솔에 다음과 같은 SQL 로그가 보여야 정상:
```
Hibernate: create table accounts (...)
Hibernate: create table categories (...)
Hibernate: create table transactions (...)
...
Hibernate: alter table transactions add constraint ... foreign key (account_id) references accounts
```

### 2) H2 콘솔로 테이블 확인

브라우저: `http://localhost:18080/h2-console`
- JDBC URL: `jdbc:h2:file:./data/mybudget_codex`
- User: `sa` / Password: (비워두기)

테이블 확인 쿼리:
```sql
-- 모든 테이블 (15개여야 함: 14 엔티티 + transaction_tags 조인 테이블)
SHOW TABLES;

-- 카테고리 21개
SELECT name, kind, color FROM categories ORDER BY kind, sort_order;

-- 가맹점 규칙 33개
SELECT m.pattern, c.name AS category, m.priority
FROM merchant_rules m
JOIN categories c ON c.id = m.category_id
ORDER BY m.priority DESC, m.pattern;

-- SMS 규칙 8개
SELECT card_name, enabled, priority FROM sms_parser_rules;

-- 계좌 2개
SELECT name, type, balance, color FROM accounts;
```

### 3) 테이블 인덱스 확인 (성능)
```sql
SHOW INDEXES FROM transactions;
-- IDX_TX_OCCURRED, IDX_TX_ACCOUNT_OCCURRED, IDX_TX_CATEGORY_OCCURRED
```

## 자주 만나는 문제

### "테이블이 안 보이는데요"
H2 가 파일 모드라 이전 DB 가 남아있을 수 있습니다.
```bash
rm -rf backend/data/
cd backend && ./gradlew bootRun
```

### "data.sql 이 안 도는 것 같아요"
`application.yml` 에 다음 두 줄이 있는지 확인:
```yaml
spring.jpa.defer-datasource-initialization: true
spring.sql.init.mode: always
```

이게 없으면 data.sql 이 테이블 생성 *전*에 실행되어 모두 실패합니다.

### "Lombok @Getter 가 빨간 줄로 표시돼요"
Visual Studio Code 의 Lombok 확장 (`vscjava.vscode-lombok`) 이 설치되었는지 확인:
```bash
code --list-extensions | grep lombok
```
없으면:
```bash
code --install-extension vscjava.vscode-lombok
```
설치 후 Visual Studio Code 재시작.

### "ddl-auto: update 가 컬럼 변경을 못 따라가요"
운영 환경에서는 `validate` 로 바꾸고 Flyway/Liquibase 로 마이그레이션 관리하는 게 정석. 개발 중에는 `data/` 폴더를 지우고 재시작이 가장 빠릅니다.

### "Transaction 이라는 테이블명이 위험하지 않나요?"
일부 DB 에서 `transaction` 은 예약어이므로 본 스크립트는 **`transactions`** (복수형) 으로 저장합니다. 마찬가지로 `user` → `users`, `tag` → `tags` 등 안전한 복수형을 사용합니다.

## 전체 도메인 관계도

```
                    ┌────────┐
                    │  User  │
                    └────────┘

   ┌─────────┐   *──*   ┌──────────┐   *──*   ┌──────────┐
   │ Account │ ◀────── │Transaction│ ──────▶ │ Category │
   └─────────┘          └──────────┘          └──────────┘
        ▲                  │    ▲                  ▲
        │                  │    │                  │
        │ from/to          │    │ M:N              │ self-ref
        │                  ▼    │                  │ parent
   ┌─────────┐      ┌──────────┴┐       ┌──────────┴────┐
   │Transfer │      │ TxSplit /  │       │ Sub-Category  │
   │         │      │ Attachment │       └───────────────┘
   └─────────┘      └────────────┘
                          │
                          ▼
                       ┌─────┐
                       │ Tag │
                       └─────┘

   ┌─────────────┐  ┌──────────────┐  ┌──────────────┐
   │   Budget    │  │RecurringRule │  │ SavingsGoal  │
   └─────────────┘  └──────────────┘  └──────────────┘

   ┌────────────────┐  ┌───────────────┐  ┌─────────────────┐
   │FavoriteTx Tpl. │  │ MerchantRule  │  │ SmsParserRule   │
   └────────────────┘  └───────────────┘  └─────────────────┘
```

## 다음 단계

Phase 4 가 통과되면 **Phase 5 (REST API 컨트롤러)** 로 진입합니다.

Phase 5 자동화 시 만들어질 것들:
- `controller/AccountController.java` 등 14개 컨트롤러
- `service/` 14개 서비스 (비즈니스 로직 + 트랜잭션)
- `dto/` 요청/응답 DTO (Java record)
- `exception/` 전역 예외 핸들러 (`@ControllerAdvice`)
- Springdoc OpenAPI 의존성 추가 → `/swagger-ui.html` 자동 문서

`Phase 5 시작해줘` 라고 하시면 진행하겠습니다.
