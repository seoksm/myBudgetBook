package com.mybudget.backend.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "budgets",
        uniqueConstraints = @UniqueConstraint(name = "uk_budget_user_ym_category",
                columnNames = {"user_id", "year_value", "month_value", "category_id"}))
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Budget {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "year_value", nullable = false)
    private Integer year;

    @Column(name = "month_value", nullable = false)
    private Integer month;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;

    @Column(nullable = false)
    private Long amount;
}
