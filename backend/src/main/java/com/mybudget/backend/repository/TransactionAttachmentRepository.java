package com.mybudget.backend.repository;

import com.mybudget.backend.domain.TransactionAttachment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TransactionAttachmentRepository extends JpaRepository<TransactionAttachment, Long> {
    List<TransactionAttachment> findByTransactionId(Long transactionId);
    void deleteByTransactionId(Long transactionId);
}
