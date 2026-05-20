package com.mybudget.backend.repository;

import com.mybudget.backend.domain.MerchantRule;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MerchantRuleRepository extends JpaRepository<MerchantRule, Long> {
    List<MerchantRule> findByUserIdOrderByPriorityDesc(Long userId);
    long countByUserId(Long userId);
    List<MerchantRule> findByUserIsNullOrderByPriorityDesc();
}
