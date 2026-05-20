package com.mybudget.backend.repository;

import com.mybudget.backend.domain.Category;
import com.mybudget.backend.domain.CategoryKind;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CategoryRepository extends JpaRepository<Category, Long> {
    List<Category> findByUserIdAndKindAndArchivedFalseOrderBySortOrderAsc(Long userId, CategoryKind kind);
    List<Category> findByUserIdAndArchivedFalseOrderBySortOrderAsc(Long userId);
    List<Category> findByUserIdAndParentIdOrderBySortOrderAsc(Long userId, Long parentId);
    Optional<Category> findByIdAndUserId(Long id, Long userId);
    Optional<Category> findByUserIdAndNameAndKind(Long userId, String name, CategoryKind kind);
    boolean existsByIdAndUserId(Long id, Long userId);
    long countByUserId(Long userId);
    List<Category> findByUserIsNullOrderBySortOrderAsc();
}
