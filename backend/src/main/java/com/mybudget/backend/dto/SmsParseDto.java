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
