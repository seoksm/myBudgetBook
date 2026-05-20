package com.mybudget.backend.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "transaction_splits")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class TransactionSplit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "transaction_id", nullable = false)
    private Transaction transaction;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;

    @Column(nullable = false)
    private Long amount;

    @Column(length = 500)
    private String memo;
}
