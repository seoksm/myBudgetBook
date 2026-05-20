package com.mybudget.backend.controller;

import com.mybudget.backend.config.AuthContext;
import com.mybudget.backend.dto.AuthDto;
import com.mybudget.backend.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Tag(name = "Auth", description = "인증")
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    @Operation(summary = "회원가입")
    public AuthDto.AuthResponse register(@Valid @RequestBody AuthDto.RegisterRequest request) {
        return authService.register(request);
    }

    @PostMapping("/login")
    @Operation(summary = "로그인")
    public AuthDto.AuthResponse login(@Valid @RequestBody AuthDto.LoginRequest request) {
        return authService.login(request);
    }

    @GetMapping("/me")
    @Operation(summary = "현재 로그인 사용자")
    public AuthDto.MeResponse me() {
        return authService.me(AuthContext.requireUser());
    }

    @PostMapping("/logout")
    @Operation(summary = "로그아웃")
    public ResponseEntity<Void> logout() {
        return ResponseEntity.noContent().build();
    }
}
