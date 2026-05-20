package com.mybudget.backend.exception;

/** 비즈니스 규칙 위반 (400). */
public class BusinessException extends RuntimeException {
    private final String code;
    public BusinessException(String code, String message) {
        super(message);
        this.code = code;
    }
    public String getCode() { return code; }
}
