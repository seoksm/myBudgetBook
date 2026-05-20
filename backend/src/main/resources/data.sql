-- =============================================================================
-- 가계부 시드 데이터 (data.sql)
-- 앱 첫 실행 시 자동 로드되며, 두 번째 이후에는 중복 방지를 위해
-- INSERT ... SELECT WHERE NOT EXISTS 패턴을 사용한다.
-- =============================================================================

-- ─── 기본 계좌 2개 ────────────────────────────────────────────────────
INSERT INTO accounts (name, type, balance, currency, color, sort_order, archived, created_at)
SELECT '현금 지갑', 'CASH', 0, 'KRW', '#94a3b8', 1, FALSE, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE name = '현금 지갑');

INSERT INTO accounts (name, type, balance, currency, color, sort_order, archived, created_at)
SELECT '주거래 은행', 'DEPOSIT', 0, 'KRW', '#0ea5e9', 2, FALSE, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE name = '주거래 은행');

-- ─── 지출 카테고리 15개 ───────────────────────────────────────────────
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '식비',           'EXPENSE', 'utensils',    '#ef4444',  1, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='식비'           AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '카페/간식',      'EXPENSE', 'coffee',      '#f97316',  2, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='카페/간식'      AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '교통',           'EXPENSE', 'bus',         '#eab308',  3, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='교통'           AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '통신',           'EXPENSE', 'wifi',        '#84cc16',  4, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='통신'           AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '주거/관리비',    'EXPENSE', 'home',        '#22c55e',  5, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='주거/관리비'    AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '의료/건강',      'EXPENSE', 'heart-pulse', '#10b981',  6, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='의료/건강'      AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '교육/자기계발',  'EXPENSE', 'book-open',   '#14b8a6',  7, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='교육/자기계발'  AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '쇼핑/생활용품',  'EXPENSE', 'shopping-bag','#06b6d4',  8, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='쇼핑/생활용품'  AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '의류/미용',      'EXPENSE', 'shirt',       '#0ea5e9',  9, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='의류/미용'      AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '여가/문화',      'EXPENSE', 'film',        '#3b82f6', 10, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='여가/문화'      AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '경조사',         'EXPENSE', 'gift',        '#6366f1', 11, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='경조사'         AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '보험',           'EXPENSE', 'shield',      '#8b5cf6', 12, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='보험'           AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '세금/공과금',    'EXPENSE', 'receipt',     '#a855f7', 13, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='세금/공과금'    AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '기부',           'EXPENSE', 'hand-heart',  '#d946ef', 14, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='기부'           AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '기타 지출',      'EXPENSE', 'more-horizontal','#64748b', 15, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='기타 지출'      AND kind='EXPENSE');

-- ─── 수입 카테고리 6개 ────────────────────────────────────────────────
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '월급',        'INCOME', 'wallet',     '#16a34a',  1, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='월급'        AND kind='INCOME');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '보너스/상여', 'INCOME', 'sparkles',   '#22c55e',  2, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='보너스/상여' AND kind='INCOME');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '부수입',      'INCOME', 'briefcase',  '#10b981',  3, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='부수입'      AND kind='INCOME');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '용돈',        'INCOME', 'hand-coins', '#14b8a6',  4, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='용돈'        AND kind='INCOME');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '이자/배당',   'INCOME', 'trending-up','#06b6d4',  5, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='이자/배당'   AND kind='INCOME');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '기타 수입',   'INCOME', 'plus-circle','#64748b',  6, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='기타 수입'   AND kind='INCOME');

-- ─── 가맹점 자동 매핑 규칙 (인기 브랜드 30+) ──────────────────────────
INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '스타벅스',  (SELECT id FROM categories WHERE name='카페/간식' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='스타벅스');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '이디야',    (SELECT id FROM categories WHERE name='카페/간식' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='이디야');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '투썸',      (SELECT id FROM categories WHERE name='카페/간식' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='투썸');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '메가커피',  (SELECT id FROM categories WHERE name='카페/간식' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='메가커피');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '컴포즈',    (SELECT id FROM categories WHERE name='카페/간식' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='컴포즈');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT 'GS25',     (SELECT id FROM categories WHERE name='식비' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='GS25');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT 'CU',       (SELECT id FROM categories WHERE name='식비' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='CU');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '세븐일레븐',(SELECT id FROM categories WHERE name='식비' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='세븐일레븐');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '이마트24', (SELECT id FROM categories WHERE name='식비' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='이마트24');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '맥도날드',  (SELECT id FROM categories WHERE name='식비' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='맥도날드');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '버거킹',    (SELECT id FROM categories WHERE name='식비' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='버거킹');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '롯데리아',  (SELECT id FROM categories WHERE name='식비' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='롯데리아');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '배달의민족',(SELECT id FROM categories WHERE name='식비' AND kind='EXPENSE' LIMIT 1), 110
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='배달의민족');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '쿠팡이츠',  (SELECT id FROM categories WHERE name='식비' AND kind='EXPENSE' LIMIT 1), 110
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='쿠팡이츠');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '요기요',    (SELECT id FROM categories WHERE name='식비' AND kind='EXPENSE' LIMIT 1), 110
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='요기요');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '이마트',    (SELECT id FROM categories WHERE name='쇼핑/생활용품' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='이마트');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '홈플러스',  (SELECT id FROM categories WHERE name='쇼핑/생활용품' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='홈플러스');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '롯데마트',  (SELECT id FROM categories WHERE name='쇼핑/생활용품' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='롯데마트');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '쿠팡',      (SELECT id FROM categories WHERE name='쇼핑/생활용품' AND kind='EXPENSE' LIMIT 1), 95
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='쿠팡');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '11번가',    (SELECT id FROM categories WHERE name='쇼핑/생활용품' AND kind='EXPENSE' LIMIT 1), 95
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='11번가');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT 'SSG',       (SELECT id FROM categories WHERE name='쇼핑/생활용품' AND kind='EXPENSE' LIMIT 1), 95
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='SSG');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '지하철',    (SELECT id FROM categories WHERE name='교통' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='지하철');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '버스',      (SELECT id FROM categories WHERE name='교통' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='버스');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '택시',      (SELECT id FROM categories WHERE name='교통' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='택시');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '카카오T',   (SELECT id FROM categories WHERE name='교통' AND kind='EXPENSE' LIMIT 1), 105
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='카카오T');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '티머니',    (SELECT id FROM categories WHERE name='교통' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='티머니');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT 'SK텔레콤',  (SELECT id FROM categories WHERE name='통신' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='SK텔레콤');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT 'KT',        (SELECT id FROM categories WHERE name='통신' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='KT');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT 'LGU+',      (SELECT id FROM categories WHERE name='통신' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='LGU+');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '넷플릭스',  (SELECT id FROM categories WHERE name='여가/문화' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='넷플릭스');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '유튜브',    (SELECT id FROM categories WHERE name='여가/문화' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='유튜브');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT 'CGV',       (SELECT id FROM categories WHERE name='여가/문화' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='CGV');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '메가박스',  (SELECT id FROM categories WHERE name='여가/문화' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='메가박스');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '롯데시네마',(SELECT id FROM categories WHERE name='여가/문화' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='롯데시네마');

-- ─── 카드사별 SMS 정규식 (Phase 7 에서 본격 사용) ─────────────────────
INSERT INTO sms_parser_rules (card_name, regex_pattern, enabled, priority)
SELECT 'KB국민', '(?:KB)?국민카드?\\(?\\d+\\)?\\s*(?<amount>[\\d,]+)원\\s*(?<installment>일시불|\\d+개월)?\\s*(?<date>\\d{1,2}/\\d{1,2})\\s*(?<time>\\d{2}:\\d{2})\\s*(?<store>.+)', TRUE, 100
WHERE NOT EXISTS (SELECT 1 FROM sms_parser_rules WHERE card_name='KB국민');

INSERT INTO sms_parser_rules (card_name, regex_pattern, enabled, priority)
SELECT '신한', '신한카드\\s*승인\\s*\\S+\\s*(?<amount>[\\d,]+)원\\(?(?<installment>일시불|\\d+개월)?\\)?\\s*(?<date>\\d{1,2}/\\d{1,2})\\s*(?<time>\\d{2}:\\d{2})\\s*(?<store>.+)', TRUE, 100
WHERE NOT EXISTS (SELECT 1 FROM sms_parser_rules WHERE card_name='신한');

INSERT INTO sms_parser_rules (card_name, regex_pattern, enabled, priority)
SELECT '삼성', '삼성카드\\s*(?<amount>[\\d,]+)원\\s*(?<installment>일시불|\\d+개월)?\\s*(?<date>\\d{1,2}/\\d{1,2})\\s*(?<time>\\d{2}:\\d{2})\\s*(?<store>.+)', TRUE, 100
WHERE NOT EXISTS (SELECT 1 FROM sms_parser_rules WHERE card_name='삼성');

INSERT INTO sms_parser_rules (card_name, regex_pattern, enabled, priority)
SELECT '현대', '현대카드\\s*(?<amount>[\\d,]+)원\\s*(?<installment>일시불|\\d+개월)?\\s*(?<date>\\d{1,2}/\\d{1,2})\\s*(?<time>\\d{2}:\\d{2})\\s*(?<store>.+)', TRUE, 100
WHERE NOT EXISTS (SELECT 1 FROM sms_parser_rules WHERE card_name='현대');

INSERT INTO sms_parser_rules (card_name, regex_pattern, enabled, priority)
SELECT '롯데', '롯데카드\\s*(?<amount>[\\d,]+)원\\s*(?<installment>일시불|\\d+개월)?\\s*(?<date>\\d{1,2}/\\d{1,2})\\s*(?<time>\\d{2}:\\d{2})\\s*(?<store>.+)', TRUE, 100
WHERE NOT EXISTS (SELECT 1 FROM sms_parser_rules WHERE card_name='롯데');

INSERT INTO sms_parser_rules (card_name, regex_pattern, enabled, priority)
SELECT '우리', '우리카드\\s*(?<amount>[\\d,]+)원\\s*(?<installment>일시불|\\d+개월)?\\s*(?<date>\\d{1,2}/\\d{1,2})\\s*(?<time>\\d{2}:\\d{2})\\s*(?<store>.+)', TRUE, 100
WHERE NOT EXISTS (SELECT 1 FROM sms_parser_rules WHERE card_name='우리');

INSERT INTO sms_parser_rules (card_name, regex_pattern, enabled, priority)
SELECT '하나', '하나카드\\s*(?<amount>[\\d,]+)원\\s*(?<installment>일시불|\\d+개월)?\\s*(?<date>\\d{1,2}/\\d{1,2})\\s*(?<time>\\d{2}:\\d{2})\\s*(?<store>.+)', TRUE, 100
WHERE NOT EXISTS (SELECT 1 FROM sms_parser_rules WHERE card_name='하나');

INSERT INTO sms_parser_rules (card_name, regex_pattern, enabled, priority)
SELECT 'BC', 'BC카드\\s*(?<amount>[\\d,]+)원\\s*(?<installment>일시불|\\d+개월)?\\s*(?<date>\\d{1,2}/\\d{1,2})\\s*(?<time>\\d{2}:\\d{2})\\s*(?<store>.+)', TRUE, 100
WHERE NOT EXISTS (SELECT 1 FROM sms_parser_rules WHERE card_name='BC');
