# Phase 7 — SMS 파서 본격 구현 사용 가이드

카드사 SMS 텍스트를 복사·붙여넣기만 하면 자동으로 거래로 등록되는 핵심 차별화 기능입니다.

## 한 줄 요약

```bash
cd ~/claude/budget_book_codex
source activate-env.sh
bash setup-phase7-sms.sh

# 백엔드 재시작 (새 컨트롤러 로드)
# 터미널 A: cd backend && ./gradlew bootRun
# 프론트는 Vite HMR 로 자동 반영

open http://localhost:15173/sms
```

## 사전 조건

| 조건 | 확인 |
|---|---|
| Phase 5 백엔드 + Phase 6 프론트 | http://localhost:15173 에서 홈이 보임 |
| Phase 4 시드 데이터 (sms_parser_rules 8개) | H2 콘솔: `SELECT * FROM sms_parser_rules` |
| Phase 4 시드 데이터 (merchant_rules 33개) | H2 콘솔: `SELECT count(*) FROM merchant_rules` |

## 동작 흐름

```
[사용자]                [프론트엔드]              [백엔드]
복사한 SMS 텍스트
  └─▶ 텍스트영역 ──▶ POST /api/sms/parse ──▶ SmsParserService
                                                  │
                                                  ▼
                                          SmsParserRule 조회
                                          (KB국민, 신한, ... 8종)
                                                  │
                                                  ▼  정규식 매칭
                                          Matcher → amount, store,
                                                   date, time, installment
                                                  │
                                                  ▼  가맹점 매핑
                                          MerchantRule 조회
                                          "스타벅스 → 카페/간식"
                                                  │
        ◀─── 미리보기 카드 N개  ───  Result[N]
체크박스 + 계좌선택
        │
        └─▶ N×POST /api/transactions ──▶ TransactionService
                                          잔액 자동 갱신
        ◀─── "N건 저장 완료" ──
```

## 생성되는 것

### 백엔드 (`backend/`)

| 파일 | 역할 |
|---|---|
| `dto/SmsParseDto.java` | `Request` (text), `Result` (한 줄 파싱), `Response` (총합 + 결과 + 실패 리스트) |
| `service/SmsParserService.java` | SmsParserRule 조회 → 정규식 적용 → MerchantRule 로 카테고리 추천 |
| `controller/SmsController.java` | `POST /api/sms/parse` 엔드포인트 |

### 프론트엔드 (`frontend/src/`)

| 파일 | 역할 |
|---|---|
| `api/sms.ts` | `parseSms(text)` 호출 함수 |
| `routes/SmsPage.tsx` (재작성) | 텍스트 영역 + 미리보기 카드 + 일괄 저장 UI |

## SMS 페이지 사용법

1. 카드사 알림 SMS 를 그대로 복사
2. `/sms` 페이지의 텍스트 영역에 붙여넣기 (여러 건 한 번에 OK)
3. **파싱하기** 버튼
4. 파싱된 거래가 카드 형태로 미리보기 표시
   - 체크박스로 저장할 항목 선택
   - 계좌 선택 (기본: 첫 번째 계좌)
   - 카테고리는 가맹점에서 자동 추천 (예: "스타벅스" → "카페/간식")
5. **N건 저장** 버튼 → 일괄 등록 + 계좌 잔액 자동 갱신

## 지원하는 카드사 (시드 데이터 기준)

| 카드사 | 패턴 |
|---|---|
| KB국민 | `(?:KB)?국민카드?\(?\d+\)?\s*(?<amount>[\d,]+)원\s*(?<installment>일시불\|\d+개월)?\s*(?<date>\d{1,2}/\d{1,2})\s*(?<time>\d{2}:\d{2})\s*(?<store>.+)` |
| 신한 | `신한카드\s*승인\s*\S+\s*(?<amount>[\d,]+)원\(?(?<installment>일시불\|\d+개월)?\)?\s*(?<date>\d{1,2}/\d{1,2})\s*(?<time>\d{2}:\d{2})\s*(?<store>.+)` |
| 삼성, 현대, 롯데, 우리, 하나, BC | 비슷한 형식 |

**명명 그룹**: `amount`, `store`, `date`, `time`, `installment` (선택)

## 테스트 샘플

브라우저 SMS 페이지에 그대로 붙여넣어 테스트:

```
[Web발신] KB국민카드(1234) 12,300원 일시불 12/05 14:23 스타벅스
신한카드 승인 홍길동 5,500원(일시불) 05/17 12:34 GS25
삼성카드 35,000원 일시불 05/16 19:45 배달의민족
현대카드 4,500원 일시불 05/17 08:30 메가커피
잘못된 SMS 라인입니다 (파싱 실패 케이스)
```

**예상 결과:**
- ✅ 파싱 4건 (스타벅스 12,300, GS25 5,500, 배달의민족 35,000, 메가커피 4,500)
- ⚠ 실패 1건 (마지막 줄)
- 자동 카테고리: 스타벅스/메가커피 → 카페/간식, GS25 → 식비, 배달의민족 → 식비

## 새 카드사 패턴 추가

H2 콘솔 (http://localhost:18080/h2-console) 에서:

```sql
INSERT INTO sms_parser_rules (card_name, regex_pattern, enabled, priority)
VALUES (
  '카카오뱅크체크',
  '카카오뱅크\s*체크\s*(?<amount>[\d,]+)원\s*(?<date>\d{1,2}/\d{1,2})\s*(?<time>\d{2}:\d{2})\s*(?<store>.+)',
  TRUE,
  100
);
```

→ 재배포 없이 즉시 새 패턴 적용 (백엔드가 매번 DB 조회).

## 새 가맹점 자동 매핑 추가

```sql
INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '쿠팡플레이',
       (SELECT id FROM categories WHERE name='여가/문화' AND kind='EXPENSE' LIMIT 1),
       100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='쿠팡플레이');
```

## API 직접 테스트 (Swagger UI 또는 curl)

```bash
curl -X POST http://localhost:18080/api/sms/parse \
  -H 'Content-Type: application/json' \
  -d '{
    "text": "[Web발신] KB국민카드(1234) 12,300원 일시불 12/05 14:23 스타벅스\n신한카드 승인 홍길동 5,500원(일시불) 05/17 12:34 GS25"
  }' | jq
```

응답:
```json
{
  "totalLines": 2,
  "parsedCount": 2,
  "failedCount": 0,
  "results": [
    {
      "raw": "[Web발신] KB국민카드(1234) ...",
      "cardName": "KB국민",
      "amount": 12300,
      "storeName": "스타벅스",
      "occurredAt": "2025-12-05T14:23:00",
      "installmentMonths": null,
      "suggestedCategoryId": 2,
      "suggestedCategoryName": "카페/간식"
    },
    ...
  ],
  "failed": []
}
```

## 자주 만나는 문제

### "파싱 실패" 가 많이 나옴
SMS 형식이 카드사마다 조금씩 다르고 시즌에 따라 바뀝니다. 실패한 SMS 의 정확한 텍스트를 보고 `sms_parser_rules` 에 새 정규식을 추가하세요.

테스트 팁: [regex101.com](https://regex101.com/) 에서 Java 모드로 패턴 검증.

### 가맹점은 인식했는데 카테고리가 비어있음
`merchant_rules` 에 해당 가맹점 키워드가 없는 것. 새로 INSERT 하세요. 가맹점 명에 부분 문자열이 들어있으면 매칭됩니다 (`"스타벅스 강남점"` 도 `pattern='스타벅스'` 로 매칭).

### 연도가 이상하게 나옴
SMS 에는 보통 연도가 없어 **현재 연도** 를 사용합니다. 미래 날짜로 계산되면 **작년** 으로 자동 조정. 12월 SMS 를 1월에 파싱하면 작년으로 인식됩니다.

### 할부가 인식 안 됨
정규식의 `(?<installment>일시불|\d+개월)?` 부분이 없거나, SMS 가 "3개월" 대신 "3회"로 표기되어 있으면 인식 못 합니다. 정규식 수정 필요.

## 다음 단계

- **Phase 8** — PWA 설치 (홈 화면 추가) / JWT 인증 / 알림
- **마감/정리** — git 정리, README 작성, 배포

`Phase 8 시작해줘` 또는 "마감해줘" 로 진행하세요.
