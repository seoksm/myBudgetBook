package com.mybudget.backend.dto;

import com.mybudget.backend.domain.Tag;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class TagDto {

    public record CreateRequest(
            @NotBlank @Size(max = 50) String name,
            String color
    ) {}

    public record Response(Long id, String name, String color) {
        public static Response from(Tag t) {
            return new Response(t.getId(), t.getName(), t.getColor());
        }
    }
}
