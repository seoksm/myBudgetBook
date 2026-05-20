package com.mybudget.backend.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.mybudget.backend.domain.User;
import com.mybudget.backend.exception.UnauthorizedException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;

@Service
public class TokenService {

    private static final String HMAC_ALGORITHM = "HmacSHA256";
    private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {
    };

    private final ObjectMapper objectMapper;

    @Value("${app.auth.jwt-secret:budget-book-codex-local-dev-secret-change-me-2026}")
    private String secret;

    @Value("${app.auth.token-hours:24}")
    private long tokenHours;

    public TokenService(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    public String createToken(User user) {
        Instant expiresAt = Instant.now().plusSeconds(tokenHours * 3600);

        Map<String, Object> header = new LinkedHashMap<>();
        header.put("alg", "HS256");
        header.put("typ", "JWT");

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("userId", user.getId());
        payload.put("email", user.getEmail());
        payload.put("displayName", user.getDisplayName());
        payload.put("exp", expiresAt.getEpochSecond());

        String signingInput = encodeJson(header) + "." + encodeJson(payload);
        return signingInput + "." + sign(signingInput);
    }

    public TokenClaims verify(String token) {
        try {
            if (token == null || token.isBlank()) {
                throw new UnauthorizedException("인증 토큰이 없습니다.");
            }

            String[] parts = token.split("\\.");
            if (parts.length != 3) {
                throw new UnauthorizedException("인증 토큰 형식이 올바르지 않습니다.");
            }

            String signingInput = parts[0] + "." + parts[1];
            String expectedSignature = sign(signingInput);
            if (!MessageDigestSafe.equals(expectedSignature, parts[2])) {
                throw new UnauthorizedException("인증 토큰이 유효하지 않습니다.");
            }

            Map<String, Object> payload = objectMapper.readValue(decode(parts[1]), MAP_TYPE);
            long exp = asLong(payload.get("exp"));
            if (exp <= Instant.now().getEpochSecond()) {
                throw new UnauthorizedException("로그인 시간이 만료되었습니다.");
            }

            Long userId = asLong(payload.get("userId"));
            String email = asString(payload.get("email"));
            String displayName = asString(payload.get("displayName"));
            return new TokenClaims(userId, email, displayName, Instant.ofEpochSecond(exp));
        } catch (UnauthorizedException e) {
            throw e;
        } catch (Exception e) {
            throw new UnauthorizedException("인증 토큰을 확인하지 못했습니다.");
        }
    }

    private String encodeJson(Map<String, Object> value) {
        try {
            return Base64.getUrlEncoder()
                    .withoutPadding()
                    .encodeToString(objectMapper.writeValueAsBytes(value));
        } catch (Exception e) {
            throw new IllegalStateException("인증 토큰을 생성하지 못했습니다.", e);
        }
    }

    private byte[] decode(String encoded) {
        return Base64.getUrlDecoder().decode(encoded);
    }

    private String sign(String signingInput) {
        try {
            Mac mac = Mac.getInstance(HMAC_ALGORITHM);
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), HMAC_ALGORITHM));
            return Base64.getUrlEncoder()
                    .withoutPadding()
                    .encodeToString(mac.doFinal(signingInput.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new IllegalStateException("인증 토큰 서명을 생성하지 못했습니다.", e);
        }
    }

    private long asLong(Object value) {
        if (value instanceof Number number) {
            return number.longValue();
        }
        if (value instanceof String text) {
            return Long.parseLong(text);
        }
        throw new UnauthorizedException("인증 토큰 정보가 올바르지 않습니다.");
    }

    private String asString(Object value) {
        if (value instanceof String text && !text.isBlank()) {
            return text;
        }
        throw new UnauthorizedException("인증 토큰 정보가 올바르지 않습니다.");
    }

    public record TokenClaims(Long userId, String email, String displayName, Instant expiresAt) {
    }

    private static final class MessageDigestSafe {
        private MessageDigestSafe() {
        }

        static boolean equals(String a, String b) {
            return java.security.MessageDigest.isEqual(
                    a.getBytes(StandardCharsets.UTF_8),
                    b.getBytes(StandardCharsets.UTF_8));
        }
    }
}
