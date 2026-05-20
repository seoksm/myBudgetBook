package com.mybudget.backend.domain;

/**
 * 거래 등록 출처.
 */
public enum TransactionSource {
    MANUAL,     // 사용자 직접 입력
    SMS,        // 카드 SMS 파싱
    RECURRING   // 반복 거래 규칙으로 자동 생성
}
