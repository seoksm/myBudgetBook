package com.mybudget.backend.dto;

import com.mybudget.backend.domain.FavoriteTransaction;
import com.mybudget.backend.domain.TransactionKind;
import jakarta.validation.constraints.*;

public class FavoriteTransactionDto {

    public record CreateRequest(
            @NotBlank @Size(max = 100) String label,
            @NotNull TransactionKind kind,
            @NotNull @Positive Long amount,
            @NotNull Long accountId,
            Long categoryId,
            String memo
    ) {}

    public record Response(
            Long id, String label, TransactionKind kind, Long amount,
            Long accountId, String accountName,
            Long categoryId, String categoryName, String memo, Integer sortOrder
    ) {
        public static Response from(FavoriteTransaction f) {
            return new Response(f.getId(), f.getLabel(), f.getKind(), f.getAmount(),
                    f.getAccount().getId(), f.getAccount().getName(),
                    f.getCategory() != null ? f.getCategory().getId() : null,
                    f.getCategory() != null ? f.getCategory().getName() : null,
                    f.getMemo(), f.getSortOrder());
        }
    }
}
