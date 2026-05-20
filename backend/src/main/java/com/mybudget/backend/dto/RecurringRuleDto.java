package com.mybudget.backend.dto;

import com.mybudget.backend.domain.RecurringRule;
import com.mybudget.backend.domain.TransactionKind;
import jakarta.validation.constraints.*;

import java.time.LocalDate;

public class RecurringRuleDto {

    public record CreateRequest(
            @NotBlank @Size(max = 100) String name,
            @NotNull TransactionKind kind,
            @NotNull @Positive Long amount,
            @NotNull Long accountId,
            Long categoryId,
            @NotNull @Min(1) @Max(31) Integer dayOfMonth,
            @NotNull LocalDate startDate,
            LocalDate endDate,
            @Size(max = 500) String memo
    ) {}

    public record UpdateRequest(
            @NotBlank @Size(max = 100) String name,
            @NotNull @Positive Long amount,
            @NotNull @Min(1) @Max(31) Integer dayOfMonth,
            LocalDate endDate,
            String memo,
            Boolean active
    ) {}

    public record Response(
            Long id, String name, TransactionKind kind, Long amount,
            Long accountId, String accountName,
            Long categoryId, String categoryName,
            Integer dayOfMonth, LocalDate startDate, LocalDate endDate,
            String memo, Boolean active
    ) {
        public static Response from(RecurringRule r) {
            return new Response(r.getId(), r.getName(), r.getKind(), r.getAmount(),
                    r.getAccount().getId(), r.getAccount().getName(),
                    r.getCategory() != null ? r.getCategory().getId() : null,
                    r.getCategory() != null ? r.getCategory().getName() : null,
                    r.getDayOfMonth(), r.getStartDate(), r.getEndDate(),
                    r.getMemo(), r.getActive());
        }
    }
}
