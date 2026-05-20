package com.mybudget.backend.dto;

import java.time.LocalDateTime;
import java.util.List;

/** 전역 표준 에러 응답 형식. */
public record ErrorResponse(
        LocalDateTime timestamp,
        int status,
        String code,
        String message,
        String path,
        List<FieldError> errors
) {
    public record FieldError(String field, String message, Object rejectedValue) {}

    public static ErrorResponse of(int status, String code, String message, String path) {
        return new ErrorResponse(LocalDateTime.now(), status, code, message, path, List.of());
    }
}
