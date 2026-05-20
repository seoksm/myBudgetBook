package com.mybudget.backend.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "favorite_transactions")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class FavoriteTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @Column(nullable = false, length = 100)
    private String label;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private TransactionKind kind;

    @Column(nullable = false)
    private Long amount;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "account_id", nullable = false)
    private Account account;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    @Column(length = 500)
    private String memo;

    @Column(nullable = false)
    @Builder.Default
    private Integer sortOrder = 0;
}
