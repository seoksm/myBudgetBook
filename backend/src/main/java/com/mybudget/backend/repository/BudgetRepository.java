package com.mybudget.backend.repository;

import com.mybudget.backend.domain.Budget;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface BudgetRepository extends JpaRepository<Budget, Long> {
    List<Budget> findByUserIdAndYearAndMonth(Long userId, Integer year, Integer month);
    Optional<Budget> findByUserIdAndYearAndMonthAndCategoryId(Long userId, Integer year, Integer month, Long categoryId);
    Optional<Budget> findByIdAndUserId(Long id, Long userId);
    boolean existsByIdAndUserId(Long id, Long userId);
    long countByUserId(Long userId);
    List<Budget> findByUserIsNull();
}
