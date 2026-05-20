package com.mybudget.backend.repository;

import com.mybudget.backend.domain.Account;
import com.mybudget.backend.domain.AccountType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AccountRepository extends JpaRepository<Account, Long> {
    List<Account> findByUserIdAndArchivedFalseOrderBySortOrderAsc(Long userId);
    List<Account> findByUserIdAndTypeAndArchivedFalse(Long userId, AccountType type);
    Optional<Account> findByIdAndUserId(Long id, Long userId);
    boolean existsByIdAndUserId(Long id, Long userId);
    long countByUserId(Long userId);
    List<Account> findByUserIsNullOrderBySortOrderAsc();
}
