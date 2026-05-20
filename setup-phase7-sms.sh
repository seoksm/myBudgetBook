#!/usr/bin/env bash
# =============================================================================
# 가계부 웹앱 - Phase 7 SMS 파서 본격 구현
#
# 사용법:
#   source activate-env.sh           ← Phase 1 환경 활성화
#   bash setup-phase7-sms.sh          ← Phase 7 실행
#                                     (Phase 5/6 완료 후)
#
# 생성물:
#   백엔드:
#     - dto/SmsParseDto.java        : 요청/응답 (record)
#     - service/SmsParserService.java : 정규식 기반 SMS 파싱
#     - controller/SmsController.java : POST /api/sms/parse
#   프론트:
#     - api/sms.ts                  : 파서 호출 함수
#     - routes/SmsPage.tsx (재작성) : 다중 라인 + 미리보기 + 일괄 저장
# =============================================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

say()  { echo -e "${BOLD}${BLUE}▶ $1${NC}"; }
ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
err()  { echo -e "  ${RED}✗${NC} $1"; }
info() { echo -e "  ${DIM}↳ $1${NC}"; }

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BE="$PROJECT_DIR/backend/src/main/java/com/mybudget/backend"
FE="$PROJECT_DIR/frontend/src"

# =============================================================================
echo ""
echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║  가계부 웹앱 — Phase 7 SMS 파서 본격 구현                                   ║${NC}"
echo -e "${BOLD}${BLUE}║  백엔드 파싱 로직 + 프론트엔드 미리보기 UI                                  ║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 사전 점검
if [ ! -d "$BE/service" ] || [ ! -d "$FE/routes" ]; then
  err "Phase 5/6 가 완료되어야 합니다."
  exit 1
fi

# =============================================================================
say "1/3. 백엔드 - DTO + Service + Controller"
# =============================================================================

# ─── SmsParseDto ───────────────────────────────────────────────────────
cat > "$BE/dto/SmsParseDto.java" <<'EOF'
package com.mybudget.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;
import java.util.List;

public class SmsParseDto {

    /** 입력 — 카드 SMS 텍스트 (여러 줄 가능) */
    public record Request(
            @NotBlank @Size(max = 10000) String text
    ) {}

    /** 한 줄 파싱 결과 */
    public record Result(
            String raw,
            String cardName,
            Long amount,
            String storeName,
            LocalDateTime occurredAt,
            Integer installmentMonths,
            Long suggestedCategoryId,
            String suggestedCategoryName
    ) {}

    /** 전체 응답 */
    public record Response(
            int totalLines,
            int parsedCount,
            int failedCount,
            List<Result> results,
            List<String> failed
    ) {}
}
EOF
ok "SmsParseDto.java"

# ─── SmsParserService ──────────────────────────────────────────────────
cat > "$BE/service/SmsParserService.java" <<'EOF'
package com.mybudget.backend.service;

import com.mybudget.backend.domain.MerchantRule;
import com.mybudget.backend.domain.SmsParserRule;
import com.mybudget.backend.dto.SmsParseDto;
import com.mybudget.backend.repository.MerchantRuleRepository;
import com.mybudget.backend.repository.SmsParserRuleRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 카드 SMS 텍스트를 정규식 기반으로 파싱하여 거래 정보를 추출한다.
 *
 * 정규식 규칙은 SmsParserRule 테이블에서 우선순위 순으로 조회한다.
 * 가맹점 → 카테고리 자동 매핑은 MerchantRule 테이블 사용.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SmsParserService {

    private static final Logger log = LoggerFactory.getLogger(SmsParserService.class);

    private final SmsParserRuleRepository ruleRepo;
    private final MerchantRuleRepository merchantRepo;

    public SmsParseDto.Response parse(String text) {
        List<SmsParserRule> rules = ruleRepo.findByEnabledTrueOrderByPriorityDesc();
        List<MerchantRule> merchants = merchantRepo.findAllByOrderByPriorityDesc();

        List<SmsParseDto.Result> results = new ArrayList<>();
        List<String> failed = new ArrayList<>();

        String[] lines = text.split("\\r?\\n");
        int totalLines = 0;
        for (String raw : lines) {
            String line = raw.trim();
            if (line.isEmpty()) continue;
            totalLines++;

            SmsParseDto.Result r = tryParse(line, rules, merchants);
            if (r != null) {
                results.add(r);
            } else {
                failed.add(line);
            }
        }
        return new SmsParseDto.Response(totalLines, results.size(), failed.size(), results, failed);
    }

    private SmsParseDto.Result tryParse(String line, List<SmsParserRule> rules, List<MerchantRule> merchants) {
        for (SmsParserRule rule : rules) {
            try {
                Pattern p = Pattern.compile(rule.getRegexPattern());
                Matcher m = p.matcher(line);
                if (m.find()) {
                    long amount = Long.parseLong(safeGroup(m, "amount").replace(",", ""));
                    String date = safeGroup(m, "date");
                    String time = safeGroup(m, "time");
                    String store = safeGroup(m, "store");
                    String installmentStr = safeGroup(m, "installment");

                    if (store != null) store = store.trim();
                    LocalDateTime occurredAt = parseDateTime(date, time);
                    Integer installmentMonths = parseInstallment(installmentStr);

                    Long suggestedCategoryId = null;
                    String suggestedCategoryName = null;
                    if (store != null) {
                        for (MerchantRule mr : merchants) {
                            if (store.contains(mr.getPattern())) {
                                suggestedCategoryId = mr.getCategory().getId();
                                suggestedCategoryName = mr.getCategory().getName();
                                break;
                            }
                        }
                    }

                    return new SmsParseDto.Result(
                            line, rule.getCardName(), amount, store,
                            occurredAt, installmentMonths,
                            suggestedCategoryId, suggestedCategoryName
                    );
                }
            } catch (Exception e) {
                log.debug("Rule {} failed on line: {}", rule.getCardName(), e.getMessage());
            }
        }
        return null;
    }

    /** Matcher.group(name) 가 그룹이 없거나 매칭 안 됐을 때 null 반환 */
    private String safeGroup(Matcher m, String name) {
        try { return m.group(name); } catch (Exception e) { return null; }
    }

    private Integer parseInstallment(String s) {
        if (s == null || s.isBlank() || "일시불".equals(s.trim())) return null;
        try {
            return Integer.parseInt(s.replace("개월", "").trim());
        } catch (Exception e) {
            return null;
        }
    }

    /** "12/05" + "14:23" → LocalDateTime. 년도는 현재 기준, 미래면 작년으로 */
    private LocalDateTime parseDateTime(String date, String time) {
        if (date == null) return LocalDateTime.now();
        try {
            String[] dp = date.split("/");
            int month = Integer.parseInt(dp[0]);
            int day = Integer.parseInt(dp[1]);
            int hour = 0, minute = 0;
            if (time != null) {
                String[] tp = time.split(":");
                hour = Integer.parseInt(tp[0]);
                minute = Integer.parseInt(tp[1]);
            }
            int year = LocalDate.now().getYear();
            LocalDateTime candidate = LocalDateTime.of(year, month, day, hour, minute);
            if (candidate.isAfter(LocalDateTime.now().plusDays(1))) {
                candidate = candidate.minusYears(1);
            }
            return candidate;
        } catch (Exception e) {
            return LocalDateTime.now();
        }
    }
}
EOF
ok "SmsParserService.java"

# ─── SmsController ─────────────────────────────────────────────────────
cat > "$BE/controller/SmsController.java" <<'EOF'
package com.mybudget.backend.controller;

import com.mybudget.backend.dto.SmsParseDto;
import com.mybudget.backend.service.SmsParserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/sms")
@RequiredArgsConstructor
@Tag(name = "Sms", description = "카드 SMS 자동 파싱")
public class SmsController {

    private final SmsParserService service;

    @PostMapping("/parse")
    @Operation(summary = "SMS 텍스트를 파싱하여 거래 후보 반환")
    public SmsParseDto.Response parse(@Valid @RequestBody SmsParseDto.Request req) {
        return service.parse(req.text());
    }
}
EOF
ok "SmsController.java"

# =============================================================================
say "2/3. 프론트엔드 — api/sms.ts + SmsPage.tsx 재작성"
# =============================================================================

# ─── api/sms.ts ────────────────────────────────────────────────────────
cat > "$FE/api/sms.ts" <<'EOF'
import { apiClient } from './client';

export interface SmsParseResult {
  raw: string;
  cardName: string;
  amount: number;
  storeName: string | null;
  occurredAt: string;
  installmentMonths: number | null;
  suggestedCategoryId: number | null;
  suggestedCategoryName: string | null;
}

export interface SmsParseResponse {
  totalLines: number;
  parsedCount: number;
  failedCount: number;
  results: SmsParseResult[];
  failed: string[];
}

export const parseSms = (text: string) =>
  apiClient.post<SmsParseResponse>('/sms/parse', { text }).then((r) => r.data);
EOF
ok "api/sms.ts"

# ─── routes/SmsPage.tsx (재작성) ──────────────────────────────────────
cat > "$FE/routes/SmsPage.tsx" <<'EOF'
import { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Sparkles, CheckCircle2, AlertCircle } from 'lucide-react';
import { parseSms, type SmsParseResult } from '../api/sms';
import { fetchAccounts } from '../api/accounts';
import { createTransaction } from '../api/transactions';
import { PageHeader } from '../components/PageHeader';
import { EmptyState } from '../components/EmptyState';
import { fmtWon, fmtDateKo, fmtTime } from '../utils/format';

interface ParsedRow extends SmsParseResult {
  selected: boolean;
  accountId?: number;
  categoryId?: number;
}

export default function SmsPage() {
  const qc = useQueryClient();
  const [text, setText] = useState('');
  const [rows, setRows] = useState<ParsedRow[]>([]);
  const [failed, setFailed] = useState<string[]>([]);
  const [savedCount, setSavedCount] = useState(0);

  const { data: accounts } = useQuery({ queryKey: ['accounts'], queryFn: fetchAccounts });
  const defaultAccountId = accounts?.[0]?.id;

  const parseMutation = useMutation({
    mutationFn: parseSms,
    onSuccess: (res) => {
      setRows(res.results.map((r) => ({
        ...r,
        selected: true,
        accountId: defaultAccountId,
        categoryId: r.suggestedCategoryId ?? undefined,
      })));
      setFailed(res.failed);
      setSavedCount(0);
    },
  });

  const saveMutation = useMutation({
    mutationFn: async (selectedRows: ParsedRow[]) => {
      let saved = 0;
      for (const r of selectedRows) {
        if (!r.accountId) continue;
        await createTransaction({
          kind: 'EXPENSE',
          amount: r.amount,
          accountId: r.accountId,
          categoryId: r.categoryId,
          memo: r.storeName ?? undefined,
          occurredAt: r.occurredAt,
        });
        saved++;
      }
      return saved;
    },
    onSuccess: (saved) => {
      setSavedCount(saved);
      setRows([]);
      setText('');
      qc.invalidateQueries({ queryKey: ['transactions'] });
      qc.invalidateQueries({ queryKey: ['accounts'] });
      qc.invalidateQueries({ queryKey: ['stats'] });
    },
  });

  const selectedCount = rows.filter((r) => r.selected).length;

  const toggleRow = (idx: number) => {
    setRows((rs) => rs.map((r, i) => i === idx ? { ...r, selected: !r.selected } : r));
  };

  const toggleAll = () => {
    const allSelected = rows.every((r) => r.selected);
    setRows((rs) => rs.map((r) => ({ ...r, selected: !allSelected })));
  };

  return (
    <div className="space-y-4">
      <PageHeader title="SMS 붙여넣기" />

      <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-100 dark:border-slate-800 p-4 space-y-3">
        <div className="text-xs text-slate-500">
          카드사 결제 SMS 를 그대로 복사 → 붙여넣기. 여러 건도 한 번에 가능합니다.
        </div>
        <textarea
          value={text}
          onChange={(e) => setText(e.target.value)}
          rows={6}
          placeholder={`예) [Web발신] KB국민카드(1234) 12,300원 일시불 12/05 14:23 스타벅스\n     신한카드 승인 홍길동 5,500원(일시불) 05/17 12:34 GS25`}
          className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700
                     bg-slate-50 dark:bg-slate-800/50 font-mono text-xs outline-none focus:border-sky-500
                     placeholder:text-slate-300 dark:placeholder:text-slate-600"
        />
        <button
          onClick={() => parseMutation.mutate(text)}
          disabled={!text.trim() || parseMutation.isPending}
          className="w-full bg-sky-600 hover:bg-sky-700 disabled:opacity-50 text-white font-medium py-2.5 rounded-lg flex items-center justify-center gap-2"
        >
          <Sparkles size={16} />
          {parseMutation.isPending ? '파싱 중...' : '파싱하기'}
        </button>
      </div>

      {savedCount > 0 && (
        <div className="flex items-center gap-2 p-3 bg-emerald-50 dark:bg-emerald-900/30 border border-emerald-200 dark:border-emerald-700 rounded-lg text-sm">
          <CheckCircle2 size={18} className="text-emerald-600 dark:text-emerald-400" />
          <span>{savedCount}개 거래 저장 완료</span>
        </div>
      )}

      {rows.length > 0 && (
        <>
          <div className="flex items-center justify-between">
            <label className="flex items-center gap-2 text-sm cursor-pointer">
              <input
                type="checkbox"
                checked={rows.every((r) => r.selected)}
                onChange={toggleAll}
                className="w-4 h-4 accent-sky-600"
              />
              <span>전체 선택 ({selectedCount}/{rows.length})</span>
            </label>
            <button
              onClick={() => saveMutation.mutate(rows.filter((r) => r.selected))}
              disabled={selectedCount === 0 || saveMutation.isPending}
              className="bg-sky-600 hover:bg-sky-700 disabled:opacity-50 text-white text-sm font-medium px-4 py-2 rounded-lg"
            >
              {saveMutation.isPending ? '저장 중...' : `${selectedCount}건 저장`}
            </button>
          </div>

          <div className="space-y-2">
            {rows.map((r, i) => (
              <div
                key={i}
                className={`p-3 rounded-xl border-2 transition ${
                  r.selected
                    ? 'border-sky-500 bg-sky-50/30 dark:bg-sky-900/10'
                    : 'border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 opacity-60'
                }`}
              >
                <div className="flex items-start gap-3">
                  <input
                    type="checkbox"
                    checked={r.selected}
                    onChange={() => toggleRow(i)}
                    className="w-5 h-5 mt-1 accent-sky-600 flex-shrink-0"
                  />
                  <div className="flex-1 min-w-0">
                    <div className="flex justify-between items-baseline gap-2">
                      <div className="font-semibold truncate">{r.storeName || '(가맹점 미상)'}</div>
                      <div className="text-rose-600 dark:text-rose-400 font-bold">
                        -{fmtWon(r.amount)}
                      </div>
                    </div>
                    <div className="text-xs text-slate-500 mt-0.5">
                      {fmtDateKo(r.occurredAt)} {fmtTime(r.occurredAt)} · {r.cardName}
                      {r.installmentMonths && ` · ${r.installmentMonths}개월 할부`}
                    </div>

                    <div className="grid grid-cols-2 gap-2 mt-2">
                      <select
                        value={r.accountId || ''}
                        onChange={(e) => {
                          const v = e.target.value ? Number(e.target.value) : undefined;
                          setRows((rs) => rs.map((row, idx) => idx === i ? { ...row, accountId: v } : row));
                        }}
                        className="text-xs px-2 py-1.5 rounded border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900"
                      >
                        <option value="">계좌 선택...</option>
                        {accounts?.map((a) => (
                          <option key={a.id} value={a.id}>{a.name}</option>
                        ))}
                      </select>
                      <div className="text-xs px-2 py-1.5 rounded border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/50 text-slate-600 dark:text-slate-300 truncate">
                        {r.suggestedCategoryName || '(카테고리 미지정)'}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </>
      )}

      {failed.length > 0 && (
        <div className="bg-amber-50 dark:bg-amber-900/30 border border-amber-200 dark:border-amber-700 rounded-xl p-3">
          <div className="flex items-center gap-2 text-amber-700 dark:text-amber-300 text-sm font-semibold mb-2">
            <AlertCircle size={16} /> 파싱 실패 {failed.length}건
          </div>
          <div className="space-y-1 text-xs font-mono text-slate-600 dark:text-slate-400">
            {failed.map((f, i) => <div key={i}>· {f}</div>)}
          </div>
          <div className="text-[11px] text-slate-500 mt-2">
            카드사 패턴이 시드에 없거나, 형식이 달라서 인식되지 않은 SMS입니다.
            정규식은 H2 콘솔 SMS_PARSER_RULES 테이블에서 추가/수정할 수 있습니다.
          </div>
        </div>
      )}

      {rows.length === 0 && failed.length === 0 && !parseMutation.isPending && (
        <EmptyState
          icon="📱"
          title="아직 파싱 결과가 없습니다"
          description="위에 카드 SMS를 붙여넣고 '파싱하기' 를 눌러주세요. KB국민/신한/삼성/현대/롯데/우리/하나/BC 8개 카드사 지원."
        />
      )}
    </div>
  );
}
EOF
ok "SmsPage.tsx (재작성)"

# =============================================================================
say "3/3. 마무리"
# =============================================================================

echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║  🎉  Phase 7 SMS 파서 구현 완료!                                            ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}생성/수정 파일${NC}"
echo "  백엔드:"
echo "    • dto/SmsParseDto.java        (Request/Result/Response)"
echo "    • service/SmsParserService.java (정규식 기반 파싱 + 가맹점 매핑)"
echo "    • controller/SmsController.java (POST /api/sms/parse)"
echo "  프론트:"
echo "    • api/sms.ts                  (parseSms 함수)"
echo "    • routes/SmsPage.tsx          (다중 라인 + 미리보기 + 일괄 저장)"
echo ""
echo -e "${BOLD}다음 단계${NC}"
echo ""
echo "  1) 백엔드 재시작 (새 컨트롤러/서비스 로드):"
echo -e "       ${BLUE}cd backend && ./gradlew bootRun${NC}"
echo ""
echo "  2) 프론트는 Vite hot reload 로 자동 반영"
echo ""
echo "  3) 브라우저: http://localhost:15173/sms"
echo "     테스트 텍스트 (아래 그대로 복붙):"
echo ""
cat <<'SAMPLE'
       [Web발신] KB국민카드(1234) 12,300원 일시불 12/05 14:23 스타벅스
       신한카드 승인 홍길동 5,500원(일시불) 05/17 12:34 GS25
       삼성카드 35,000원 일시불 05/16 19:45 배달의민족
       잘못된 SMS 라인입니다 (파싱 실패 케이스)
SAMPLE
echo ""
echo "     → 4건 입력 → '파싱하기' → 3건 미리보기 + 1건 실패"
echo "     → 계좌 선택 → '3건 저장'"
echo "     → 홈 화면 가서 거래 + 잔액 갱신 확인"
echo ""
echo -e "${DIM}Swagger UI 에서도 직접 시험 가능: http://localhost:18080/swagger-ui.html → Sms${NC}"
echo ""
