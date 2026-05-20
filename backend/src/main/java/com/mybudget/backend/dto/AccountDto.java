package com.mybudget.backend.dto;

import com.mybudget.backend.domain.Account;
import com.mybudget.backend.domain.AccountType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;

public class AccountDto {

    public record CreateRequest(
            @NotBlank @Size(max = 50) String name,
            @NotNull AccountType type,
            Long balance,
            String currency,
            String color,
            Integer statementDay,
            Integer paymentDay,
            Long linkedDepositAccountId
    ) {}

    public record UpdateRequest(
            @NotBlank @Size(max = 50) String name,
            String color,
            Integer statementDay,
            Integer paymentDay,
            Integer sortOrder,
            Boolean archived,
            Long linkedDepositAccountId
    ) {}

    public record Response(
            Long id,
            String name,
            AccountType type,
            Long balance,
            String currency,
            String color,
            Integer statementDay,
            Integer paymentDay,
            Long linkedDepositAccountId,
            String linkedDepositAccountName,
            Integer sortOrder,
            Boolean archived,
            LocalDateTime createdAt
    ) {
        public static Response from(Account a) {
            return new Response(
                    a.getId(), a.getName(), a.getType(), a.getBalance(),
                    a.getCurrency(), a.getColor(),
                    a.getStatementDay(), a.getPaymentDay(),
                    a.getLinkedDepositAccount() != null ? a.getLinkedDepositAccount().getId() : null,
                    a.getLinkedDepositAccount() != null ? a.getLinkedDepositAccount().getName() : null,
                    a.getSortOrder(), a.getArchived(), a.getCreatedAt());
        }
    }

    public record ActivityResponse(
            String sourceType,
            Long sourceId,
            String kind,
            Long amount,
            String title,
            String subtitle,
            String memo,
            LocalDateTime occurredAt,
            Long relatedAccountId,
            String relatedAccountName
    ) {}
}
