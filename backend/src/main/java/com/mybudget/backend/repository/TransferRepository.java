package com.mybudget.backend.repository;

import com.mybudget.backend.domain.Transfer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface TransferRepository extends JpaRepository<Transfer, Long> {
    List<Transfer> findByUserIdAndOccurredAtBetweenOrderByOccurredAtDesc(
            Long userId, LocalDateTime from, LocalDateTime to);
    Optional<Transfer> findByIdAndUserId(Long id, Long userId);
    @Query("""
            SELECT t FROM Transfer t
            WHERE t.user.id = :userId
              AND (t.fromAccount.id = :accountId OR t.toAccount.id = :accountId)
              AND t.occurredAt BETWEEN :from AND :to
            ORDER BY t.occurredAt DESC
            """)
    List<Transfer> findAccountTransfers(@Param("userId") Long userId,
                                        @Param("accountId") Long accountId,
                                        @Param("from") LocalDateTime from,
                                        @Param("to") LocalDateTime to);
    List<Transfer> findByUserIsNull();
}
