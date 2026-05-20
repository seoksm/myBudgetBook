#!/usr/bin/env bash
# =============================================================================
# 가계부 웹앱 - Phase 4 도메인 레이어 자동 생성
#
# 사용법:
#   source activate-env.sh        ← Phase 1 환경 활성화
#   bash setup-phase4-domain.sh    ← Phase 4 실행 (backend/ 가 이미 있어야 함)
#
# 생성물:
#   - 4개 enum (AccountType, CategoryKind, TransactionKind, TransactionSource)
#   - 14개 JPA 엔티티
#   - 14개 Spring Data JPA Repository
#   - data.sql (기본 카테고리 21개, 기본 계좌 2개, 가맹점 규칙 30+개)
#   - application.yml 패치 (data.sql 로드 활성화)
# =============================================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

say()  { echo -e "${BOLD}${BLUE}▶ $1${NC}"; }
ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
err()  { echo -e "  ${RED}✗${NC} $1"; }
info() { echo -e "  ${DIM}↳ $1${NC}"; }

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BE="$PROJECT_DIR/backend/src/main/java/com/mybudget/backend"
RES="$PROJECT_DIR/backend/src/main/resources"
DOMAIN="$BE/domain"
REPO="$BE/repository"

# =============================================================================
echo ""
echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║  가계부 웹앱 — Phase 4 도메인 레이어 자동 생성                              ║${NC}"
echo -e "${BOLD}${BLUE}║  Enum 4 + Entity 14 + Repository 14 + 시드 데이터                          ║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 사전 점검
if [ ! -d "$BE" ]; then
  err "$BE 가 없습니다. 먼저 'bash setup-project.sh' (Phase 2) 를 실행하세요."
  exit 1
fi

mkdir -p "$DOMAIN" "$REPO"
# .gitkeep 제거 (실제 파일로 채워질 예정)
rm -f "$DOMAIN/.gitkeep" "$REPO/.gitkeep"

# =============================================================================
say "1/4. Enum 4개 생성"
# =============================================================================

cat > "$DOMAIN/AccountType.java" <<'EOF'
package com.mybudget.backend.domain;

/**
 * 자산/부채 계좌의 종류.
 */
public enum AccountType {
    CASH,          // 현금
    DEPOSIT,       // 예금/적금
    CHECK_CARD,    // 체크카드
    CREDIT_CARD,   // 신용카드 (결제일/마감일 관리)
    INVESTMENT,    // 투자 (주식/펀드/코인)
    LOAN           // 대출 (음수 잔액)
}
EOF
ok "AccountType.java"

cat > "$DOMAIN/CategoryKind.java" <<'EOF'
package com.mybudget.backend.domain;

/**
 * 카테고리 종류 — 수입 또는 지출.
 */
public enum CategoryKind {
    INCOME,
    EXPENSE
}
EOF
ok "CategoryKind.java"

cat > "$DOMAIN/TransactionKind.java" <<'EOF'
package com.mybudget.backend.domain;

/**
 * 거래 종류 — 수입/지출/이체.
 */
public enum TransactionKind {
    INCOME,
    EXPENSE,
    TRANSFER
}
EOF
ok "TransactionKind.java"

cat > "$DOMAIN/TransactionSource.java" <<'EOF'
package com.mybudget.backend.domain;

/**
 * 거래 등록 출처.
 */
public enum TransactionSource {
    MANUAL,     // 사용자 직접 입력
    SMS,        // 카드 SMS 파싱
    RECURRING   // 반복 거래 규칙으로 자동 생성
}
EOF
ok "TransactionSource.java"

# =============================================================================
say "2/4. Entity 14개 생성"
# =============================================================================

# ─── User ──────────────────────────────────────────────────────────────
cat > "$DOMAIN/User.java" <<'EOF'
package com.mybudget.backend.domain;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 100)
    private String email;

    @Column(nullable = false, length = 200)
    private String passwordHash;

    @Column(nullable = false, length = 50)
    private String displayName;

    @CreationTimestamp
    private LocalDateTime createdAt;
}
EOF
ok "User.java"

# ─── Account ───────────────────────────────────────────────────────────
cat > "$DOMAIN/Account.java" <<'EOF'
package com.mybudget.backend.domain;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "accounts")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Account {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 50)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private AccountType type;

    @Column(nullable = false)
    @Builder.Default
    private Long balance = 0L;

    @Column(length = 10)
    @Builder.Default
    private String currency = "KRW";

    @Column(length = 20)
    private String color;

    /** 신용카드 결제 마감일 (1-31). CREDIT_CARD 만 사용 */
    private Integer statementDay;

    /** 신용카드 결제일 (1-31). CREDIT_CARD 만 사용 */
    private Integer paymentDay;

    @Column(nullable = false)
    @Builder.Default
    private Integer sortOrder = 0;

    @Column(nullable = false)
    @Builder.Default
    private Boolean archived = false;

    @CreationTimestamp
    private LocalDateTime createdAt;
}
EOF
ok "Account.java"

# ─── Category ──────────────────────────────────────────────────────────
cat > "$DOMAIN/Category.java" <<'EOF'
package com.mybudget.backend.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "categories")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Category {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 50)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private CategoryKind kind;

    /** 자기참조 - 하위 카테고리 지원 (식비 > 점심) */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_id")
    private Category parent;

    @Column(length = 50)
    private String icon;

    @Column(length = 20)
    private String color;

    @Column(nullable = false)
    @Builder.Default
    private Integer sortOrder = 0;

    @Column(nullable = false)
    @Builder.Default
    private Boolean archived = false;
}
EOF
ok "Category.java"

# ─── Tag ───────────────────────────────────────────────────────────────
cat > "$DOMAIN/Tag.java" <<'EOF'
package com.mybudget.backend.domain;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "tags")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Tag {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 50)
    private String name;

    @Column(length = 20)
    private String color;

    @CreationTimestamp
    private LocalDateTime createdAt;
}
EOF
ok "Tag.java"

# ─── Transaction ───────────────────────────────────────────────────────
cat > "$DOMAIN/Transaction.java" <<'EOF'
package com.mybudget.backend.domain;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "transactions", indexes = {
        @Index(name = "idx_tx_occurred", columnList = "occurred_at"),
        @Index(name = "idx_tx_account_occurred", columnList = "account_id, occurred_at"),
        @Index(name = "idx_tx_category_occurred", columnList = "category_id, occurred_at")
})
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Transaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private TransactionKind kind;

    @Column(nullable = false)
    private Long amount;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "account_id", nullable = false)
    private Account account;

    /** 이체(TRANSFER) 거래는 카테고리 NULL 허용 */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    @Column(length = 500)
    private String memo;

    @Column(name = "occurred_at", nullable = false)
    private LocalDateTime occurredAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private TransactionSource source = TransactionSource.MANUAL;

    /** SMS 출처 원본 텍스트 */
    @Lob
    @Column(columnDefinition = "TEXT")
    private String rawSms;

    /** 할부 개월 수 (12개월 할부 시 12). 일시불은 null */
    private Integer installmentMonths;

    /** 할부 회차 (12개월 중 3번째 회차면 3) */
    private Integer installmentSeq;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
            name = "transaction_tags",
            joinColumns = @JoinColumn(name = "transaction_id"),
            inverseJoinColumns = @JoinColumn(name = "tag_id")
    )
    @Builder.Default
    private Set<Tag> tags = new HashSet<>();

    @CreationTimestamp
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
EOF
ok "Transaction.java"

# ─── TransactionAttachment ─────────────────────────────────────────────
cat > "$DOMAIN/TransactionAttachment.java" <<'EOF'
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
EOF
ok "TransactionAttachment.java"

# ─── TransactionSplit ──────────────────────────────────────────────────
cat > "$DOMAIN/TransactionSplit.java" <<'EOF'
package com.mybudget.backend.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "transaction_splits")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class TransactionSplit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "transaction_id", nullable = false)
    private Transaction transaction;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;

    @Column(nullable = false)
    private Long amount;

    @Column(length = 500)
    private String memo;
}
EOF
ok "TransactionSplit.java"

# ─── Transfer ──────────────────────────────────────────────────────────
cat > "$DOMAIN/Transfer.java" <<'EOF'
package com.mybudget.backend.domain;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "transfers")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Transfer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "from_account_id", nullable = false)
    private Account fromAccount;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "to_account_id", nullable = false)
    private Account toAccount;

    @Column(nullable = false)
    private Long amount;

    @Column(name = "occurred_at", nullable = false)
    private LocalDateTime occurredAt;

    @Column(length = 500)
    private String memo;

    @CreationTimestamp
    private LocalDateTime createdAt;
}
EOF
ok "Transfer.java"

# ─── Budget ────────────────────────────────────────────────────────────
cat > "$DOMAIN/Budget.java" <<'EOF'
package com.mybudget.backend.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "budgets",
        uniqueConstraints = @UniqueConstraint(name = "uk_budget_ym_category",
                columnNames = {"year_value", "month_value", "category_id"}))
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Budget {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "year_value", nullable = false)
    private Integer year;

    @Column(name = "month_value", nullable = false)
    private Integer month;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;

    @Column(nullable = false)
    private Long amount;
}
EOF
ok "Budget.java"

# ─── RecurringRule ─────────────────────────────────────────────────────
cat > "$DOMAIN/RecurringRule.java" <<'EOF'
package com.mybudget.backend.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;

@Entity
@Table(name = "recurring_rules")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class RecurringRule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private TransactionKind kind;

    @Column(nullable = false)
    private Long amount;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "account_id", nullable = false)
    private Account account;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    /** 매월 며칠에 자동 등록할지 (1-31). 31 이 없는 달은 말일 */
    @Column(nullable = false)
    private Integer dayOfMonth;

    @Column(nullable = false)
    private LocalDate startDate;

    private LocalDate endDate;

    @Column(length = 500)
    private String memo;

    @Column(nullable = false)
    @Builder.Default
    private Boolean active = true;
}
EOF
ok "RecurringRule.java"

# ─── SavingsGoal ───────────────────────────────────────────────────────
cat > "$DOMAIN/SavingsGoal.java" <<'EOF'
package com.mybudget.backend.domain;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "savings_goals")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class SavingsGoal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(nullable = false)
    private Long targetAmount;

    @Column(nullable = false)
    @Builder.Default
    private Long currentAmount = 0L;

    @Column(nullable = false)
    private LocalDate dueDate;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "account_id")
    private Account account;

    @CreationTimestamp
    private LocalDateTime createdAt;
}
EOF
ok "SavingsGoal.java"

# ─── FavoriteTransaction ───────────────────────────────────────────────
cat > "$DOMAIN/FavoriteTransaction.java" <<'EOF'
package com.mybudget.backend.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "favorite_transactions")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class FavoriteTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String label;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private TransactionKind kind;

    @Column(nullable = false)
    private Long amount;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "account_id", nullable = false)
    private Account account;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    @Column(length = 500)
    private String memo;

    @Column(nullable = false)
    @Builder.Default
    private Integer sortOrder = 0;
}
EOF
ok "FavoriteTransaction.java"

# ─── MerchantRule ──────────────────────────────────────────────────────
cat > "$DOMAIN/MerchantRule.java" <<'EOF'
package com.mybudget.backend.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "merchant_rules")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class MerchantRule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 가맹점 키워드 (예: "스타벅스", "GS25"). LIKE 검색 대상 */
    @Column(nullable = false, length = 100)
    private String pattern;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;

    /** 우선순위 (높을수록 먼저 매칭) */
    @Column(nullable = false)
    @Builder.Default
    private Integer priority = 100;
}
EOF
ok "MerchantRule.java"

# ─── SmsParserRule ─────────────────────────────────────────────────────
cat > "$DOMAIN/SmsParserRule.java" <<'EOF'
package com.mybudget.backend.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "sms_parser_rules")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class SmsParserRule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 카드사 이름 (예: KB국민, 신한, 삼성, BC...) */
    @Column(nullable = false, length = 50)
    private String cardName;

    /** 정규식 패턴 - 명명된 그룹: amount, store, occurredAt, installment */
    @Column(nullable = false, columnDefinition = "TEXT")
    private String regexPattern;

    @Column(nullable = false)
    @Builder.Default
    private Boolean enabled = true;

    @Column(nullable = false)
    @Builder.Default
    private Integer priority = 100;
}
EOF
ok "SmsParserRule.java"

# =============================================================================
say "3/4. Repository 14개 생성"
# =============================================================================

# ─── UserRepository ────────────────────────────────────────────────────
cat > "$REPO/UserRepository.java" <<'EOF'
package com.mybudget.backend.repository;

import com.mybudget.backend.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
}
EOF
ok "UserRepository.java"

# ─── AccountRepository ─────────────────────────────────────────────────
cat > "$REPO/AccountRepository.java" <<'EOF'
package com.mybudget.backend.repository;

import com.mybudget.backend.domain.Account;
import com.mybudget.backend.domain.AccountType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AccountRepository extends JpaRepository<Account, Long> {
    List<Account> findByArchivedFalseOrderBySortOrderAsc();
    List<Account> findByTypeAndArchivedFalse(AccountType type);
}
EOF
ok "AccountRepository.java"

# ─── CategoryRepository ────────────────────────────────────────────────
cat > "$REPO/CategoryRepository.java" <<'EOF'
package com.mybudget.backend.repository;

import com.mybudget.backend.domain.Category;
import com.mybudget.backend.domain.CategoryKind;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CategoryRepository extends JpaRepository<Category, Long> {
    List<Category> findByKindAndArchivedFalseOrderBySortOrderAsc(CategoryKind kind);
    List<Category> findByParentIdOrderBySortOrderAsc(Long parentId);
}
EOF
ok "CategoryRepository.java"

# ─── TransactionRepository ─────────────────────────────────────────────
cat > "$REPO/TransactionRepository.java" <<'EOF'
package com.mybudget.backend.repository;

import com.mybudget.backend.domain.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface TransactionRepository extends JpaRepository<Transaction, Long> {

    List<Transaction> findByOccurredAtBetweenOrderByOccurredAtDesc(
            LocalDateTime from, LocalDateTime to);

    List<Transaction> findByAccountIdAndOccurredAtBetweenOrderByOccurredAtDesc(
            Long accountId, LocalDateTime from, LocalDateTime to);

    List<Transaction> findByCategoryIdAndOccurredAtBetweenOrderByOccurredAtDesc(
            Long categoryId, LocalDateTime from, LocalDateTime to);

    @Query("SELECT t FROM Transaction t " +
           "WHERE LOWER(t.memo) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
           "ORDER BY t.occurredAt DESC")
    List<Transaction> searchByKeyword(@Param("keyword") String keyword);
}
EOF
ok "TransactionRepository.java"

# ─── TagRepository ─────────────────────────────────────────────────────
cat > "$REPO/TagRepository.java" <<'EOF'
package com.mybudget.backend.repository;

import com.mybudget.backend.domain.Tag;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface TagRepository extends JpaRepository<Tag, Long> {
    Optional<Tag> findByName(String name);
}
EOF
ok "TagRepository.java"

# ─── TransactionAttachmentRepository ───────────────────────────────────
cat > "$REPO/TransactionAttachmentRepository.java" <<'EOF'
package com.mybudget.backend.repository;

import com.mybudget.backend.domain.TransactionAttachment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TransactionAttachmentRepository extends JpaRepository<TransactionAttachment, Long> {
    List<TransactionAttachment> findByTransactionId(Long transactionId);
    void deleteByTransactionId(Long transactionId);
}
EOF
ok "TransactionAttachmentRepository.java"

# ─── TransactionSplitRepository ────────────────────────────────────────
cat > "$REPO/TransactionSplitRepository.java" <<'EOF'
package com.mybudget.backend.repository;

import com.mybudget.backend.domain.TransactionSplit;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TransactionSplitRepository extends JpaRepository<TransactionSplit, Long> {
    List<TransactionSplit> findByTransactionId(Long transactionId);
    void deleteByTransactionId(Long transactionId);
}
EOF
ok "TransactionSplitRepository.java"

# ─── TransferRepository ────────────────────────────────────────────────
cat > "$REPO/TransferRepository.java" <<'EOF'
package com.mybudget.backend.repository;

import com.mybudget.backend.domain.Transfer;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface TransferRepository extends JpaRepository<Transfer, Long> {
    List<Transfer> findByOccurredAtBetweenOrderByOccurredAtDesc(
            LocalDateTime from, LocalDateTime to);
}
EOF
ok "TransferRepository.java"

# ─── BudgetRepository ──────────────────────────────────────────────────
cat > "$REPO/BudgetRepository.java" <<'EOF'
package com.mybudget.backend.repository;

import com.mybudget.backend.domain.Budget;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface BudgetRepository extends JpaRepository<Budget, Long> {
    List<Budget> findByYearAndMonth(Integer year, Integer month);
    Optional<Budget> findByYearAndMonthAndCategoryId(Integer year, Integer month, Long categoryId);
}
EOF
ok "BudgetRepository.java"

# ─── RecurringRuleRepository ───────────────────────────────────────────
cat > "$REPO/RecurringRuleRepository.java" <<'EOF'
package com.mybudget.backend.repository;

import com.mybudget.backend.domain.RecurringRule;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RecurringRuleRepository extends JpaRepository<RecurringRule, Long> {
    List<RecurringRule> findByActiveTrueAndDayOfMonth(Integer dayOfMonth);
    List<RecurringRule> findByActiveTrueOrderByDayOfMonthAsc();
}
EOF
ok "RecurringRuleRepository.java"

# ─── SavingsGoalRepository ─────────────────────────────────────────────
cat > "$REPO/SavingsGoalRepository.java" <<'EOF'
package com.mybudget.backend.repository;

import com.mybudget.backend.domain.SavingsGoal;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SavingsGoalRepository extends JpaRepository<SavingsGoal, Long> {
    List<SavingsGoal> findAllByOrderByDueDateAsc();
}
EOF
ok "SavingsGoalRepository.java"

# ─── FavoriteTransactionRepository ─────────────────────────────────────
cat > "$REPO/FavoriteTransactionRepository.java" <<'EOF'
package com.mybudget.backend.repository;

import com.mybudget.backend.domain.FavoriteTransaction;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FavoriteTransactionRepository extends JpaRepository<FavoriteTransaction, Long> {
    List<FavoriteTransaction> findAllByOrderBySortOrderAsc();
}
EOF
ok "FavoriteTransactionRepository.java"

# ─── MerchantRuleRepository ────────────────────────────────────────────
cat > "$REPO/MerchantRuleRepository.java" <<'EOF'
package com.mybudget.backend.repository;

import com.mybudget.backend.domain.MerchantRule;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MerchantRuleRepository extends JpaRepository<MerchantRule, Long> {
    List<MerchantRule> findAllByOrderByPriorityDesc();
}
EOF
ok "MerchantRuleRepository.java"

# ─── SmsParserRuleRepository ───────────────────────────────────────────
cat > "$REPO/SmsParserRuleRepository.java" <<'EOF'
package com.mybudget.backend.repository;

import com.mybudget.backend.domain.SmsParserRule;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SmsParserRuleRepository extends JpaRepository<SmsParserRule, Long> {
    List<SmsParserRule> findByEnabledTrueOrderByPriorityDesc();
}
EOF
ok "SmsParserRuleRepository.java"

# =============================================================================
say "4/4. data.sql 시드 데이터 + application.yml 패치"
# =============================================================================

# ─── data.sql ──────────────────────────────────────────────────────────
cat > "$RES/data.sql" <<'EOF'
-- =============================================================================
-- 가계부 시드 데이터 (data.sql)
-- 앱 첫 실행 시 자동 로드되며, 두 번째 이후에는 중복 방지를 위해
-- INSERT ... SELECT WHERE NOT EXISTS 패턴을 사용한다.
-- =============================================================================

-- ─── 기본 계좌 2개 ────────────────────────────────────────────────────
INSERT INTO accounts (name, type, balance, currency, color, sort_order, archived, created_at)
SELECT '현금 지갑', 'CASH', 0, 'KRW', '#94a3b8', 1, FALSE, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE name = '현금 지갑');

INSERT INTO accounts (name, type, balance, currency, color, sort_order, archived, created_at)
SELECT '주거래 은행', 'DEPOSIT', 0, 'KRW', '#0ea5e9', 2, FALSE, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE name = '주거래 은행');

-- ─── 지출 카테고리 15개 ───────────────────────────────────────────────
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '식비',           'EXPENSE', 'utensils',    '#ef4444',  1, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='식비'           AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '카페/간식',      'EXPENSE', 'coffee',      '#f97316',  2, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='카페/간식'      AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '교통',           'EXPENSE', 'bus',         '#eab308',  3, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='교통'           AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '통신',           'EXPENSE', 'wifi',        '#84cc16',  4, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='통신'           AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '주거/관리비',    'EXPENSE', 'home',        '#22c55e',  5, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='주거/관리비'    AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '의료/건강',      'EXPENSE', 'heart-pulse', '#10b981',  6, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='의료/건강'      AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '교육/자기계발',  'EXPENSE', 'book-open',   '#14b8a6',  7, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='교육/자기계발'  AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '쇼핑/생활용품',  'EXPENSE', 'shopping-bag','#06b6d4',  8, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='쇼핑/생활용품'  AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '의류/미용',      'EXPENSE', 'shirt',       '#0ea5e9',  9, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='의류/미용'      AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '여가/문화',      'EXPENSE', 'film',        '#3b82f6', 10, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='여가/문화'      AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '경조사',         'EXPENSE', 'gift',        '#6366f1', 11, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='경조사'         AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '보험',           'EXPENSE', 'shield',      '#8b5cf6', 12, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='보험'           AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '세금/공과금',    'EXPENSE', 'receipt',     '#a855f7', 13, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='세금/공과금'    AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '기부',           'EXPENSE', 'hand-heart',  '#d946ef', 14, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='기부'           AND kind='EXPENSE');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '기타 지출',      'EXPENSE', 'more-horizontal','#64748b', 15, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='기타 지출'      AND kind='EXPENSE');

-- ─── 수입 카테고리 6개 ────────────────────────────────────────────────
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '월급',        'INCOME', 'wallet',     '#16a34a',  1, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='월급'        AND kind='INCOME');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '보너스/상여', 'INCOME', 'sparkles',   '#22c55e',  2, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='보너스/상여' AND kind='INCOME');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '부수입',      'INCOME', 'briefcase',  '#10b981',  3, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='부수입'      AND kind='INCOME');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '용돈',        'INCOME', 'hand-coins', '#14b8a6',  4, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='용돈'        AND kind='INCOME');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '이자/배당',   'INCOME', 'trending-up','#06b6d4',  5, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='이자/배당'   AND kind='INCOME');
INSERT INTO categories (name, kind, icon, color, sort_order, archived) SELECT '기타 수입',   'INCOME', 'plus-circle','#64748b',  6, FALSE WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='기타 수입'   AND kind='INCOME');

-- ─── 가맹점 자동 매핑 규칙 (인기 브랜드 30+) ──────────────────────────
INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '스타벅스',  (SELECT id FROM categories WHERE name='카페/간식' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='스타벅스');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '이디야',    (SELECT id FROM categories WHERE name='카페/간식' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='이디야');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '투썸',      (SELECT id FROM categories WHERE name='카페/간식' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='투썸');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '메가커피',  (SELECT id FROM categories WHERE name='카페/간식' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='메가커피');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '컴포즈',    (SELECT id FROM categories WHERE name='카페/간식' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='컴포즈');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT 'GS25',     (SELECT id FROM categories WHERE name='식비' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='GS25');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT 'CU',       (SELECT id FROM categories WHERE name='식비' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='CU');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '세븐일레븐',(SELECT id FROM categories WHERE name='식비' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='세븐일레븐');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '이마트24', (SELECT id FROM categories WHERE name='식비' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='이마트24');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '맥도날드',  (SELECT id FROM categories WHERE name='식비' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='맥도날드');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '버거킹',    (SELECT id FROM categories WHERE name='식비' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='버거킹');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '롯데리아',  (SELECT id FROM categories WHERE name='식비' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='롯데리아');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '배달의민족',(SELECT id FROM categories WHERE name='식비' AND kind='EXPENSE' LIMIT 1), 110
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='배달의민족');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '쿠팡이츠',  (SELECT id FROM categories WHERE name='식비' AND kind='EXPENSE' LIMIT 1), 110
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='쿠팡이츠');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '요기요',    (SELECT id FROM categories WHERE name='식비' AND kind='EXPENSE' LIMIT 1), 110
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='요기요');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '이마트',    (SELECT id FROM categories WHERE name='쇼핑/생활용품' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='이마트');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '홈플러스',  (SELECT id FROM categories WHERE name='쇼핑/생활용품' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='홈플러스');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '롯데마트',  (SELECT id FROM categories WHERE name='쇼핑/생활용품' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='롯데마트');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '쿠팡',      (SELECT id FROM categories WHERE name='쇼핑/생활용품' AND kind='EXPENSE' LIMIT 1), 95
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='쿠팡');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '11번가',    (SELECT id FROM categories WHERE name='쇼핑/생활용품' AND kind='EXPENSE' LIMIT 1), 95
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='11번가');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT 'SSG',       (SELECT id FROM categories WHERE name='쇼핑/생활용품' AND kind='EXPENSE' LIMIT 1), 95
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='SSG');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '지하철',    (SELECT id FROM categories WHERE name='교통' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='지하철');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '버스',      (SELECT id FROM categories WHERE name='교통' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='버스');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '택시',      (SELECT id FROM categories WHERE name='교통' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='택시');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '카카오T',   (SELECT id FROM categories WHERE name='교통' AND kind='EXPENSE' LIMIT 1), 105
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='카카오T');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '티머니',    (SELECT id FROM categories WHERE name='교통' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='티머니');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT 'SK텔레콤',  (SELECT id FROM categories WHERE name='통신' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='SK텔레콤');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT 'KT',        (SELECT id FROM categories WHERE name='통신' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='KT');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT 'LGU+',      (SELECT id FROM categories WHERE name='통신' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='LGU+');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '넷플릭스',  (SELECT id FROM categories WHERE name='여가/문화' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='넷플릭스');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '유튜브',    (SELECT id FROM categories WHERE name='여가/문화' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='유튜브');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT 'CGV',       (SELECT id FROM categories WHERE name='여가/문화' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='CGV');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '메가박스',  (SELECT id FROM categories WHERE name='여가/문화' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='메가박스');

INSERT INTO merchant_rules (pattern, category_id, priority)
SELECT '롯데시네마',(SELECT id FROM categories WHERE name='여가/문화' AND kind='EXPENSE' LIMIT 1), 100
WHERE NOT EXISTS (SELECT 1 FROM merchant_rules WHERE pattern='롯데시네마');

-- ─── 카드사별 SMS 정규식 (Phase 7 에서 본격 사용) ─────────────────────
INSERT INTO sms_parser_rules (card_name, regex_pattern, enabled, priority)
SELECT 'KB국민', '(?:KB)?국민카드?\\(?\\d+\\)?\\s*(?<amount>[\\d,]+)원\\s*(?<installment>일시불|\\d+개월)?\\s*(?<date>\\d{1,2}/\\d{1,2})\\s*(?<time>\\d{2}:\\d{2})\\s*(?<store>.+)', TRUE, 100
WHERE NOT EXISTS (SELECT 1 FROM sms_parser_rules WHERE card_name='KB국민');

INSERT INTO sms_parser_rules (card_name, regex_pattern, enabled, priority)
SELECT '신한', '신한카드\\s*승인\\s*\\S+\\s*(?<amount>[\\d,]+)원\\(?(?<installment>일시불|\\d+개월)?\\)?\\s*(?<date>\\d{1,2}/\\d{1,2})\\s*(?<time>\\d{2}:\\d{2})\\s*(?<store>.+)', TRUE, 100
WHERE NOT EXISTS (SELECT 1 FROM sms_parser_rules WHERE card_name='신한');

INSERT INTO sms_parser_rules (card_name, regex_pattern, enabled, priority)
SELECT '삼성', '삼성카드\\s*(?<amount>[\\d,]+)원\\s*(?<installment>일시불|\\d+개월)?\\s*(?<date>\\d{1,2}/\\d{1,2})\\s*(?<time>\\d{2}:\\d{2})\\s*(?<store>.+)', TRUE, 100
WHERE NOT EXISTS (SELECT 1 FROM sms_parser_rules WHERE card_name='삼성');

INSERT INTO sms_parser_rules (card_name, regex_pattern, enabled, priority)
SELECT '현대', '현대카드\\s*(?<amount>[\\d,]+)원\\s*(?<installment>일시불|\\d+개월)?\\s*(?<date>\\d{1,2}/\\d{1,2})\\s*(?<time>\\d{2}:\\d{2})\\s*(?<store>.+)', TRUE, 100
WHERE NOT EXISTS (SELECT 1 FROM sms_parser_rules WHERE card_name='현대');

INSERT INTO sms_parser_rules (card_name, regex_pattern, enabled, priority)
SELECT '롯데', '롯데카드\\s*(?<amount>[\\d,]+)원\\s*(?<installment>일시불|\\d+개월)?\\s*(?<date>\\d{1,2}/\\d{1,2})\\s*(?<time>\\d{2}:\\d{2})\\s*(?<store>.+)', TRUE, 100
WHERE NOT EXISTS (SELECT 1 FROM sms_parser_rules WHERE card_name='롯데');

INSERT INTO sms_parser_rules (card_name, regex_pattern, enabled, priority)
SELECT '우리', '우리카드\\s*(?<amount>[\\d,]+)원\\s*(?<installment>일시불|\\d+개월)?\\s*(?<date>\\d{1,2}/\\d{1,2})\\s*(?<time>\\d{2}:\\d{2})\\s*(?<store>.+)', TRUE, 100
WHERE NOT EXISTS (SELECT 1 FROM sms_parser_rules WHERE card_name='우리');

INSERT INTO sms_parser_rules (card_name, regex_pattern, enabled, priority)
SELECT '하나', '하나카드\\s*(?<amount>[\\d,]+)원\\s*(?<installment>일시불|\\d+개월)?\\s*(?<date>\\d{1,2}/\\d{1,2})\\s*(?<time>\\d{2}:\\d{2})\\s*(?<store>.+)', TRUE, 100
WHERE NOT EXISTS (SELECT 1 FROM sms_parser_rules WHERE card_name='하나');

INSERT INTO sms_parser_rules (card_name, regex_pattern, enabled, priority)
SELECT 'BC', 'BC카드\\s*(?<amount>[\\d,]+)원\\s*(?<installment>일시불|\\d+개월)?\\s*(?<date>\\d{1,2}/\\d{1,2})\\s*(?<time>\\d{2}:\\d{2})\\s*(?<store>.+)', TRUE, 100
WHERE NOT EXISTS (SELECT 1 FROM sms_parser_rules WHERE card_name='BC');
EOF
ok "data.sql 시드 데이터 (계좌 2 + 카테고리 21 + 가맹점 33 + SMS규칙 8)"

# ─── application.yml 패치 ──────────────────────────────────────────────
APP_YML="$RES/application.yml"
if [ -f "$APP_YML" ]; then
  if ! grep -q "defer-datasource-initialization" "$APP_YML"; then
    # spring.jpa 섹션 끝에 deferred 설정 추가
    info "application.yml 에 defer-datasource-initialization 추가"

    # 임시 파일에 다시 작성 (yml 정렬 유지)
    cat > "$APP_YML" <<'EOF'
spring:
  application:
    name: budget-book-backend
  profiles:
    active: dev

  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
    defer-datasource-initialization: true
    properties:
      hibernate:
        format_sql: true

  sql:
    init:
      mode: always
      continue-on-error: false

  datasource:
    url: jdbc:h2:file:./data/mybudget_codex;DB_CLOSE_DELAY=-1;MODE=MySQL
    driver-class-name: org.h2.Driver
    username: sa
    password:

  h2:
    console:
      enabled: true
      path: /h2-console

server:
  port: 18080

management:
  endpoints:
    web:
      exposure:
        include: health,info

logging:
  level:
    org.hibernate.SQL: DEBUG
    com.mybudget.backend: DEBUG
EOF
    ok "application.yml 갱신 (data.sql 자동 로드 활성화)"
  else
    info "application.yml 이미 defer 설정 있음 — 건너뜀"
  fi
else
  err "application.yml 이 없습니다 — Phase 2 가 정상 완료되었는지 확인"
fi

# =============================================================================
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║  🎉  Phase 4 도메인 레이어 생성 완료!                                       ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}생성 결과${NC}"
echo "  • Enum 4개         → $DOMAIN/{AccountType,CategoryKind,TransactionKind,TransactionSource}.java"
echo "  • Entity 14개      → $DOMAIN/*.java"
echo "  • Repository 14개  → $REPO/*Repository.java"
echo "  • 시드 데이터       → $RES/data.sql"
echo "  • application.yml  → defer-datasource-initialization: true"
echo ""
echo -e "${BOLD}다음 단계${NC}"
echo ""
echo "  1) 백엔드 재시작 (스키마 생성 + 시드 데이터 로드):"
echo -e "       ${BLUE}cd backend && ./gradlew bootRun${NC}"
echo ""
echo "  2) H2 콘솔에서 테이블 확인:"
echo -e "       ${BLUE}http://localhost:18080/h2-console${NC}"
echo "     JDBC URL: jdbc:h2:file:./data/mybudget_codex"
echo "     User: sa, Password: (비워두기)"
echo "     → 'SELECT * FROM CATEGORIES' 으로 21개 카테고리 확인"
echo "     → 'SELECT * FROM MERCHANT_RULES' 으로 33개 가맹점 규칙 확인"
echo ""
echo "  3) Phase 5 (REST API 컨트롤러) 로 진입 준비"
echo ""
echo -e "${DIM}이미 data/mybudget_codex DB 가 만들어진 적이 있다면, 새 컬럼/테이블이 안 보일 수 있습니다.${NC}"
echo -e "${DIM}그 경우 'backend/data/' 폴더를 삭제하고 다시 bootRun 하세요.${NC}"
echo ""
