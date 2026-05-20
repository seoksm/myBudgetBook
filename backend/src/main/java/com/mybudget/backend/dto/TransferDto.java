package com.mybudget.backend.dto;

import com.mybudget.backend.domain.Transfer;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;

public class TransferDto {

    public record CreateRequest(
            @NotNull Long fromAccountId,
            @NotNull Long toAccountId,
            @NotNull @Positive Long amount,
            @NotNull LocalDateTime occurredAt,
            @Size(max = 500) String memo
    ) {}

    public record Response(
            Long id,
            Long fromAccountId,
            String fromAccountName,
            Long toAccountId,
            String toAccountName,
            Long amount,
            LocalDateTime occurredAt,
            String memo
    ) {
        public static Response from(Transfer t) {
            return new Response(t.getId(),
                    t.getFromAccount().getId(), t.getFromAccount().getName(),
                    t.getToAccount().getId(), t.getToAccount().getName(),
                    t.getAmount(), t.getOccurredAt(), t.getMemo());
        }
    }
}
