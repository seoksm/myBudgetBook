package com.mybudget.backend.service;

import com.mybudget.backend.domain.User;
import com.mybudget.backend.dto.AuthDto;
import com.mybudget.backend.exception.BusinessException;
import com.mybudget.backend.exception.UnauthorizedException;
import com.mybudget.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordService passwordService;
    private final TokenService tokenService;
    private final UserDataInitializer userDataInitializer;

    @Transactional
    public AuthDto.AuthResponse register(AuthDto.RegisterRequest request) {
        String email = normalizeEmail(request.email());
        if (userRepository.existsByEmail(email)) {
            throw new BusinessException("EMAIL_ALREADY_EXISTS", "이미 가입된 이메일입니다.");
        }

        User user = User.builder()
                .email(email)
                .passwordHash(passwordService.hash(request.password()))
                .displayName(request.displayName().trim())
                .build();

        User saved = userRepository.save(user);
        userDataInitializer.ensureUserData(saved);
        return toAuthResponse(saved);
    }

    @Transactional(readOnly = true)
    public AuthDto.AuthResponse login(AuthDto.LoginRequest request) {
        String email = normalizeEmail(request.email());
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UnauthorizedException("이메일 또는 비밀번호가 올바르지 않습니다."));

        if (!passwordService.verify(request.password(), user.getPasswordHash())) {
            throw new UnauthorizedException("이메일 또는 비밀번호가 올바르지 않습니다.");
        }

        userDataInitializer.ensureUserData(user);
        return toAuthResponse(user);
    }

    @Transactional(readOnly = true)
    public AuthDto.MeResponse me(User user) {
        return toMeResponse(user);
    }

    private AuthDto.AuthResponse toAuthResponse(User user) {
        return new AuthDto.AuthResponse(tokenService.createToken(user), toMeResponse(user));
    }

    private AuthDto.MeResponse toMeResponse(User user) {
        return new AuthDto.MeResponse(user.getId(), user.getEmail(), user.getDisplayName());
    }

    private String normalizeEmail(String email) {
        return email == null ? "" : email.trim().toLowerCase(Locale.ROOT);
    }
}
