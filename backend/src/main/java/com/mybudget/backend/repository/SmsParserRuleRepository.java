package com.mybudget.backend.repository;

import com.mybudget.backend.domain.SmsParserRule;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SmsParserRuleRepository extends JpaRepository<SmsParserRule, Long> {
    List<SmsParserRule> findByEnabledTrueOrderByPriorityDesc();
}
