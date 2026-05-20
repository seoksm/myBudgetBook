package com.mybudget.backend.domain;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "transaction_attachments")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class TransactionAttachment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "transaction_id", nullable = false)
    private Transaction transaction;

    @Column(nullable = false, length = 500)
    private String fileUrl;

    @Column(length = 200)
    private String originalName;

    private Long sizeBytes;

    @CreationTimestamp
    private LocalDateTime createdAt;
}
