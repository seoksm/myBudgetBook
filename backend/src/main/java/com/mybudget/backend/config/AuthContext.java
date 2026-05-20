package com.mybudget.backend.config;

import com.mybudget.backend.domain.User;
import com.mybudget.backend.exception.UnauthorizedException;

public final class AuthContext {

    private static final ThreadLocal<User> CURRENT_USER = new ThreadLocal<>();

    private AuthContext() {
    }

    public static void setUser(User user) {
        CURRENT_USER.set(user);
    }

    public static User requireUser() {
        User user = CURRENT_USER.get();
        if (user == null) {
            throw new UnauthorizedException("로그인이 필요합니다.");
        }
        return user;
    }

    public static void clear() {
        CURRENT_USER.remove();
    }
}
