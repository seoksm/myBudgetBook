package com.mybudget.backend.dto;

import com.mybudget.backend.domain.SavingsGoal;
import jakarta.validation.constraints.*;

import java.time.LocalDate;

public class SavingsGoalDto {

    public record CreateRequest(
            @NotBlank @Size(max = 100) String name,
            @NotNull @Positive Long targetAmount,
            Long currentAmount,
            @NotNull LocalDate dueDate,
            Long accountId
    ) {}

    public record Response(
            Long id, String name, Long targetAmount, Long currentAmount,
            Double progressPct, LocalDate dueDate,
            Long accountId, String accountName
    ) {
        public static Response from(SavingsGoal g) {
            double pct = g.getTargetAmount() > 0
                    ? Math.round(g.getCurrentAmount() * 10000.0 / g.getTargetAmount()) / 100.0
                    : 0.0;
            return new Response(g.getId(), g.getName(),
                    g.getTargetAmount(), g.getCurrentAmount(), pct, g.getDueDate(),
                    g.getAccount() != null ? g.getAccount().getId() : null,
                    g.getAccount() != null ? g.getAccount().getName() : null);
        }
    }
}
