package com.mybudget.backend.repository;

import com.mybudget.backend.domain.FavoriteTransaction;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface FavoriteTransactionRepository extends JpaRepository<FavoriteTransaction, Long> {
    List<FavoriteTransaction> findByUserIdOrderBySortOrderAsc(Long userId);
    Optional<FavoriteTransaction> findByIdAndUserId(Long id, Long userId);
    boolean existsByIdAndUserId(Long id, Long userId);
    long countByUserId(Long userId);
    List<FavoriteTransaction> findByUserIsNull();
}
