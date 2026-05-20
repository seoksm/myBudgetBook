package com.mybudget.backend.repository;

import com.mybudget.backend.domain.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface TransactionRepository extends JpaRepository<Transaction, Long> {

    List<Transaction> findByUserIdAndOccurredAtBetweenOrderByOccurredAtDesc(
            Long userId, LocalDateTime from, LocalDateTime to);

    List<Transaction> findByUserIdAndAccountIdAndOccurredAtBetweenOrderByOccurredAtDesc(
            Long userId, Long accountId, LocalDateTime from, LocalDateTime to);

    List<Transaction> findByUserIdAndCategoryIdAndOccurredAtBetweenOrderByOccurredAtDesc(
            Long userId, Long categoryId, LocalDateTime from, LocalDateTime to);

    Optional<Transaction> findByIdAndUserId(Long id, Long userId);

    @Query("""
            SELECT t FROM Transaction t
            WHERE t.user.id = :userId
              AND (t.account.id = :accountId OR t.balanceAccount.id = :accountId)
              AND t.occurredAt BETWEEN :from AND :to
            ORDER BY t.occurredAt DESC
            """)
    List<Transaction> findAccountActivities(@Param("userId") Long userId,
                                            @Param("accountId") Long accountId,
                                            @Param("from") LocalDateTime from,
                                            @Param("to") LocalDateTime to);

    @Query("SELECT t FROM Transaction t " +
           "WHERE t.user.id = :userId " +
           "AND LOWER(t.memo) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
           "ORDER BY t.occurredAt DESC")
    List<Transaction> searchByKeyword(@Param("userId") Long userId, @Param("keyword") String keyword);

    List<Transaction> findByUserIsNull();
}
