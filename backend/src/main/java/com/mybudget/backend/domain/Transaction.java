package com.mybudget.backend.domain;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "transactions", indexes = {
        @Index(name = "idx_tx_occurred", columnList = "occurred_at"),
        @Index(name = "idx_tx_user_occurred", columnList = "user_id, occurred_at"),
        @Index(name = "idx_tx_account_occurred", columnList = "account_id, occurred_at"),
        @Index(name = "idx_tx_category_occurred", columnList = "category_id, occurred_at")
})
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Transaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private TransactionKind kind;

    @Column(nullable = false)
    private Long amount;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "account_id", nullable = false)
    private Account account;

    /** 실제 잔액이 증감되는 계좌. 체크카드 지출은 연결 예금 계좌가 들어간다. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "balance_account_id")
    private Account balanceAccount;

    /** 이체(TRANSFER) 거래는 카테고리 NULL 허용 */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    @Column(length = 500)
    private String memo;

    @Column(name = "occurred_at", nullable = false)
    private LocalDateTime occurredAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private TransactionSource source = TransactionSource.MANUAL;

    /** SMS 출처 원본 텍스트 */
    @Lob
    @Column(columnDefinition = "TEXT")
    private String rawSms;

    /** 할부 개월 수 (12개월 할부 시 12). 일시불은 null */
    private Integer installmentMonths;

    /** 할부 회차 (12개월 중 3번째 회차면 3) */
    private Integer installmentSeq;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
            name = "transaction_tags",
            joinColumns = @JoinColumn(name = "transaction_id"),
            inverseJoinColumns = @JoinColumn(name = "tag_id")
    )
    @Builder.Default
    private Set<Tag> tags = new HashSet<>();

    @CreationTimestamp
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
