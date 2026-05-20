package com.mybudget.backend.repository;

import com.mybudget.backend.domain.Tag;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TagRepository extends JpaRepository<Tag, Long> {
    List<Tag> findAllByUserIdOrderByNameAsc(Long userId);
    Optional<Tag> findByUserIdAndName(Long userId, String name);
    Optional<Tag> findByIdAndUserId(Long id, Long userId);
    boolean existsByIdAndUserId(Long id, Long userId);
    long countByUserId(Long userId);
    List<Tag> findByUserIsNull();
}
