package com.mybudget.backend.domain;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "accounts")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Account {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    /** 체크카드 사용액이 실제 출금될 예금 계좌. CHECK_CARD 유형에서 사용한다. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "linked_deposit_account_id")
    private Account linkedDepositAccount;

    @Column(nullable = false, length = 50)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private AccountType type;

    @Column(nullable = false)
    @Builder.Default
    private Long balance = 0L;

    @Column(length = 10)
    @Builder.Default
    private String currency = "KRW";

    @Column(length = 20)
    private String color;

    /** 신용카드 결제 마감일 (1-31). CREDIT_CARD 만 사용 */
    private Integer statementDay;

    /** 신용카드 결제일 (1-31). CREDIT_CARD 만 사용 */
    private Integer paymentDay;

    @Column(nullable = false)
    @Builder.Default
    private Integer sortOrder = 0;

    @Column(nullable = false)
    @Builder.Default
    private Boolean archived = false;

    @CreationTimestamp
    private LocalDateTime createdAt;
}
