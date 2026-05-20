package com.mybudget.backend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public final class AuthDto {

    private AuthDto() {
    }

    public record RegisterRequest(
            @NotBlank @Email @Size(max = 100) String email,
            @NotBlank @Size(min = 8, max = 100) String password,
            @NotBlank @Size(max = 50) String displayName
    ) {
    }

    public record LoginRequest(
            @NotBlank @Email @Size(max = 100) String email,
            @NotBlank @Size(min = 8, max = 100) String password
    ) {
    }

    public record AuthResponse(
            String token,
            MeResponse user
    ) {
    }

    public record MeResponse(
            Long id,
            String email,
            String displayName
    ) {
    }
}
