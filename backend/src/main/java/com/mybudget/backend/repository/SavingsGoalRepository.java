package com.mybudget.backend.repository;

import com.mybudget.backend.domain.SavingsGoal;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SavingsGoalRepository extends JpaRepository<SavingsGoal, Long> {
    List<SavingsGoal> findByUserIdOrderByDueDateAsc(Long userId);
    Optional<SavingsGoal> findByIdAndUserId(Long id, Long userId);
    boolean existsByIdAndUserId(Long id, Long userId);
    long countByUserId(Long userId);
    List<SavingsGoal> findByUserIsNull();
}
