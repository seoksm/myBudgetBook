package com.mybudget.backend.dto;

import com.mybudget.backend.domain.Transaction;
import com.mybudget.backend.domain.TransactionKind;
import com.mybudget.backend.domain.TransactionSource;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;
import java.util.Set;
import java.util.stream.Collectors;

public class TransactionDto {

    public record CreateRequest(
            @NotNull TransactionKind kind,
            @NotNull @Positive Long amount,
            @NotNull Long accountId,
            Long categoryId,
            @Size(max = 500) String memo,
            @NotNull LocalDateTime occurredAt,
            Integer installmentMonths,
            Set<String> tags,
            TransactionSource source,
            String rawSms
    ) {}

    public record UpdateRequest(
            @NotNull TransactionKind kind,
            @NotNull @Positive Long amount,
            @NotNull Long accountId,
            Long categoryId,
            @Size(max = 500) String memo,
            @NotNull LocalDateTime occurredAt,
            Set<String> tags
    ) {}

    public record Response(
            Long id,
            TransactionKind kind,
            Long amount,
            Long accountId,
            String accountName,
            Long balanceAccountId,
            String balanceAccountName,
            Long categoryId,
            String categoryName,
            String memo,
            LocalDateTime occurredAt,
            TransactionSource source,
            Integer installmentMonths,
            Integer installmentSeq,
            Set<String> tags,
            LocalDateTime createdAt,
            LocalDateTime updatedAt
    ) {
        public static Response from(Transaction t) {
            return new Response(
                    t.getId(), t.getKind(), t.getAmount(),
                    t.getAccount().getId(), t.getAccount().getName(),
                    t.getBalanceAccount() != null ? t.getBalanceAccount().getId() : null,
                    t.getBalanceAccount() != null ? t.getBalanceAccount().getName() : null,
                    t.getCategory() != null ? t.getCategory().getId() : null,
                    t.getCategory() != null ? t.getCategory().getName() : null,
                    t.getMemo(), t.getOccurredAt(), t.getSource(),
                    t.getInstallmentMonths(), t.getInstallmentSeq(),
                    t.getTags().stream().map(tag -> tag.getName()).collect(Collectors.toSet()),
                    t.getCreatedAt(), t.getUpdatedAt());
        }
    }
}
