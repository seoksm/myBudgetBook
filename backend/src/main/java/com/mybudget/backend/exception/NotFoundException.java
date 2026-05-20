package com.mybudget.backend.exception;

/** 리소스 없음 (404). */
public class NotFoundException extends RuntimeException {
    public NotFoundException(String message) { super(message); }
    public NotFoundException(String entityName, Long id) {
        super(entityName + " not found: id=" + id);
    }
}
