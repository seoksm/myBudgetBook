package com.mybudget.backend.domain;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "tags",
        uniqueConstraints = @UniqueConstraint(name = "uk_tag_user_name",
                columnNames = {"user_id", "name"}))
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Tag {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @Column(nullable = false, length = 50)
    private String name;

    @Column(length = 20)
    private String color;

    @CreationTimestamp
    private LocalDateTime createdAt;
}
