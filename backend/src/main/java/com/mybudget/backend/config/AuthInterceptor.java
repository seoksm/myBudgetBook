package com.mybudget.backend.config;

import com.mybudget.backend.domain.User;
import com.mybudget.backend.exception.UnauthorizedException;
import com.mybudget.backend.repository.UserRepository;
import com.mybudget.backend.service.TokenService;
import com.mybudget.backend.service.UserDataInitializer;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
@RequiredArgsConstructor
public class AuthInterceptor implements HandlerInterceptor {

    private final TokenService tokenService;
    private final UserRepository userRepository;
    private final UserDataInitializer userDataInitializer;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        if (isPublicRequest(request)) {
            return true;
        }

        String authorization = request.getHeader("Authorization");
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            throw new UnauthorizedException("로그인이 필요합니다.");
        }

        TokenService.TokenClaims claims = tokenService.verify(authorization.substring(7).trim());
        User user = userRepository.findById(claims.userId())
                .orElseThrow(() -> new UnauthorizedException("사용자 정보를 찾을 수 없습니다."));
        userDataInitializer.ensureUserData(user);
        AuthContext.setUser(user);
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        AuthContext.clear();
    }

    private boolean isPublicRequest(HttpServletRequest request) {
        String method = request.getMethod();
        String uri = request.getRequestURI();

        if ("OPTIONS".equalsIgnoreCase(method)) {
            return true;
        }
        if (!uri.startsWith("/api/")) {
            return true;
        }
        if ("/api/hello".equals(uri)) {
            return true;
        }
        if ("/api/auth/login".equals(uri) && "POST".equalsIgnoreCase(method)) {
            return true;
        }
        if ("/api/auth/register".equals(uri) && "POST".equalsIgnoreCase(method)) {
            return true;
        }
        if ("/api/auth/logout".equals(uri) && "POST".equalsIgnoreCase(method)) {
            return true;
        }
        return false;
    }
}
