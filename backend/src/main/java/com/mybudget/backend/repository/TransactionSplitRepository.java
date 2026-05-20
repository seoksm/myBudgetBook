package com.mybudget.backend.repository;

import com.mybudget.backend.domain.TransactionSplit;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TransactionSplitRepository extends JpaRepository<TransactionSplit, Long> {
    List<TransactionSplit> findByTransactionId(Long transactionId);
    void deleteByTransactionId(Long transactionId);
}
