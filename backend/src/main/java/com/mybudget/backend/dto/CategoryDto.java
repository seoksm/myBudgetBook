package com.mybudget.backend.dto;

import com.mybudget.backend.domain.Category;
import com.mybudget.backend.domain.CategoryKind;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public class CategoryDto {

    public record CreateRequest(
            @NotBlank @Size(max = 50) String name,
            @NotNull CategoryKind kind,
            Long parentId,
            String icon,
            String color,
            Integer sortOrder
    ) {}

    public record UpdateRequest(
            @NotBlank @Size(max = 50) String name,
            String icon,
            String color,
            Integer sortOrder,
            Boolean archived
    ) {}

    public record Response(
            Long id,
            String name,
            CategoryKind kind,
            Long parentId,
            String icon,
            String color,
            Integer sortOrder,
            Boolean archived
    ) {
        public static Response from(Category c) {
            return new Response(
                    c.getId(), c.getName(), c.getKind(),
                    c.getParent() != null ? c.getParent().getId() : null,
                    c.getIcon(), c.getColor(), c.getSortOrder(), c.getArchived());
        }
    }
}
