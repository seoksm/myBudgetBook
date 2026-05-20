package com.mybudget.backend.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "merchant_rules")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class MerchantRule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    /** 가맹점 키워드 (예: "스타벅스", "GS25"). LIKE 검색 대상 */
    @Column(nullable = false, length = 100)
    private String pattern;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;

    /** 우선순위 (높을수록 먼저 매칭) */
    @Column(nullable = false)
    @Builder.Default
    private Integer priority = 100;
}
