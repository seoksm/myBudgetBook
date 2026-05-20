package com.mybudget.backend.exception;

public class UnauthorizedException extends RuntimeException {

    private final String code;

    public UnauthorizedException(String message) {
        super(message);
        this.code = "UNAUTHORIZED";
    }

    public String getCode() {
        return code;
    }
}
