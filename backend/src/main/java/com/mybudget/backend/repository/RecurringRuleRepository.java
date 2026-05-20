package com.mybudget.backend.repository;

import com.mybudget.backend.domain.RecurringRule;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface RecurringRuleRepository extends JpaRepository<RecurringRule, Long> {
    List<RecurringRule> findByUserIdAndActiveTrueAndDayOfMonth(Long userId, Integer dayOfMonth);
    List<RecurringRule> findByUserIdAndActiveTrueOrderByDayOfMonthAsc(Long userId);
    Optional<RecurringRule> findByIdAndUserId(Long id, Long userId);
    boolean existsByIdAndUserId(Long id, Long userId);
    long countByUserId(Long userId);
    List<RecurringRule> findByUserIsNull();
}
