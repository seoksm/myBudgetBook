package com.mybudget.backend.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "sms_parser_rules")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class SmsParserRule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 카드사 이름 (예: KB국민, 신한, 삼성, BC...) */
    @Column(nullable = false, length = 50)
    private String cardName;

    /** 정규식 패턴 - 명명된 그룹: amount, store, occurredAt, installment */
    @Column(nullable = false, columnDefinition = "TEXT")
    private String regexPattern;

    @Column(nullable = false)
    @Builder.Default
    private Boolean enabled = true;

    @Column(nullable = false)
    @Builder.Default
    private Integer priority = 100;
}
