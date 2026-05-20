package com.mybudget.backend.service;

import com.mybudget.backend.config.AuthContext;
import com.mybudget.backend.domain.MerchantRule;
import com.mybudget.backend.domain.SmsParserRule;
import com.mybudget.backend.domain.User;
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
        User user = AuthContext.requireUser();
        List<SmsParserRule> rules = ruleRepo.findByEnabledTrueOrderByPriorityDesc();
        List<MerchantRule> merchants = merchantRepo.findByUserIdOrderByPriorityDesc(user.getId());

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

                    if (store != null) {
                        store = store.trim();
                        // 가맹점 뒤에 붙는 누적/잔액/할인 등의 꼬리 정보 제거
                        store = store.replaceAll("\\s*누적\\s*[\\d,]+\\s*원.*$", "").trim();
                        store = store.replaceAll("\\s*잔여\\s*[\\d,]+\\s*원.*$", "").trim();
                        store = store.replaceAll("\\s*\\([^)]*\\)$", "").trim();
                    }
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
