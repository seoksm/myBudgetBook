package com.mybudget.backend.domain;

/**
 * 자산/부채 계좌의 종류.
 */
public enum AccountType {
    CASH,          // 현금
    DEPOSIT,       // 예금/적금
    CHECK_CARD,    // 체크카드
    CREDIT_CARD,   // 신용카드 (결제일/마감일 관리)
    INVESTMENT,    // 투자 (주식/펀드/코인)
    LOAN           // 대출 (음수 잔액)
}
