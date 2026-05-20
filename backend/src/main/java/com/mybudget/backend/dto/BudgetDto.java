package com.mybudget.backend.dto;

import com.mybudget.backend.domain.Budget;
import jakarta.validation.constraints.*;

public class BudgetDto {

    public record UpsertRequest(
            @NotNull @Min(2000) @Max(2100) Integer year,
            @NotNull @Min(1) @Max(12) Integer month,
            @NotNull Long categoryId,
            @NotNull @PositiveOrZero Long amount
    ) {}

    public record Response(Long id, Integer year, Integer month,
                           Long categoryId, String categoryName, Long amount) {
        public static Response from(Budget b) {
            return new Response(b.getId(), b.getYear(), b.getMonth(),
                    b.getCategory().getId(), b.getCategory().getName(), b.getAmount());
        }
    }

    public record Progress(
            Long categoryId, String categoryName, String color,
            Long budgetAmount, Long spentAmount, Double percentage) {}
}
