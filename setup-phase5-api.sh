#!/usr/bin/env bash
# =============================================================================
# 가계부 웹앱 - Phase 5 REST API 레이어 자동 생성
#
# 사용법:
#   source activate-env.sh           ← Phase 1 환경 활성화
#   bash setup-phase5-api.sh          ← Phase 5 실행
#                                       (Phase 2, Phase 4 가 먼저 완료되어야 함)
#
# 생성물:
#   - Controller 10개  : Account, Category, Tag, Transaction, Transfer,
#                        Budget, RecurringRule, SavingsGoal, FavoriteTransaction, Stats
#   - Service    10개  : 위와 동일 도메인 (@Transactional + 잔액 자동 재계산)
#   - DTO       30+개  : Java 21 record 기반 요청/응답
#   - 공통 인프라      : GlobalExceptionHandler, ErrorResponse, OpenApi 설정
#   - build.gradle 패치: springdoc-openapi 의존성 추가 → /swagger-ui.html
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

CTL="$BE/controller"
SVC="$BE/service"
DTO="$BE/dto"
EXC="$BE/exception"
CFG="$BE/config"

# =============================================================================
echo ""
echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║  가계부 웹앱 — Phase 5 REST API 레이어 자동 생성                            ║${NC}"
echo -e "${BOLD}${BLUE}║  Controller 10 + Service 10 + DTO 30+ + Swagger UI                        ║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 사전 점검
if [ ! -d "$BE/domain" ] || [ ! -d "$BE/repository" ]; then
  err "Phase 4 (도메인) 가 먼저 완료되어야 합니다. 'bash setup-phase4-domain.sh' 를 먼저 실행하세요."
  exit 1
fi

mkdir -p "$CTL" "$SVC" "$DTO" "$EXC" "$CFG"
rm -f "$CTL/.gitkeep" "$SVC/.gitkeep" "$DTO/.gitkeep" "$EXC/.gitkeep" "$CFG/.gitkeep"

# =============================================================================
say "1/5. build.gradle 패치 + 공통 인프라"
# =============================================================================

# ─── build.gradle 에 springdoc 추가 ────────────────────────────────────
GRADLE_FILE="$PROJECT_DIR/backend/build.gradle"
if [ -f "$GRADLE_FILE" ]; then
  if ! grep -q "springdoc-openapi-starter-webmvc-ui" "$GRADLE_FILE"; then
    # dependencies { ... } 블록 안에 추가 - 'implementation ... spring-boot-starter-web' 다음에 삽입
    # 안전을 위해 dependencies { 뒤에 한 줄 추가
    awk '
      BEGIN { added = 0 }
      /^dependencies \{/ && !added {
        print
        print "\timplementation '\''org.springdoc:springdoc-openapi-starter-webmvc-ui:2.8.0'\''"
        added = 1
        next
      }
      { print }
    ' "$GRADLE_FILE" > "${GRADLE_FILE}.tmp" && mv "${GRADLE_FILE}.tmp" "$GRADLE_FILE"
    ok "build.gradle 에 springdoc-openapi 2.6.0 추가"
  else
    info "springdoc-openapi 이미 있음"
  fi
fi

# ─── ErrorResponse (공통 에러 응답) ────────────────────────────────────
cat > "$DTO/ErrorResponse.java" <<'EOF'
package com.mybudget.backend.dto;

import java.time.LocalDateTime;
import java.util.List;

/** 전역 표준 에러 응답 형식. */
public record ErrorResponse(
        LocalDateTime timestamp,
        int status,
        String code,
        String message,
        String path,
        List<FieldError> errors
) {
    public record FieldError(String field, String message, Object rejectedValue) {}

    public static ErrorResponse of(int status, String code, String message, String path) {
        return new ErrorResponse(LocalDateTime.now(), status, code, message, path, List.of());
    }
}
EOF
ok "ErrorResponse.java"

# ─── 도메인 예외 ────────────────────────────────────────────────────────
cat > "$EXC/NotFoundException.java" <<'EOF'
package com.mybudget.backend.exception;

/** 리소스 없음 (404). */
public class NotFoundException extends RuntimeException {
    public NotFoundException(String message) { super(message); }
    public NotFoundException(String entityName, Long id) {
        super(entityName + " not found: id=" + id);
    }
}
EOF
ok "NotFoundException.java"

cat > "$EXC/BusinessException.java" <<'EOF'
package com.mybudget.backend.exception;

/** 비즈니스 규칙 위반 (400). */
public class BusinessException extends RuntimeException {
    private final String code;
    public BusinessException(String code, String message) {
        super(message);
        this.code = code;
    }
    public String getCode() { return code; }
}
EOF
ok "BusinessException.java"

# ─── GlobalExceptionHandler ────────────────────────────────────────────
cat > "$EXC/GlobalExceptionHandler.java" <<'EOF'
package com.mybudget.backend.exception;

import com.mybudget.backend.dto.ErrorResponse;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.LocalDateTime;
import java.util.List;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(NotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(NotFoundException e, HttpServletRequest req) {
        log.warn("NotFound: {}", e.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ErrorResponse.of(404, "NOT_FOUND", e.getMessage(), req.getRequestURI()));
    }

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ErrorResponse> handleBusiness(BusinessException e, HttpServletRequest req) {
        log.warn("Business: [{}] {}", e.getCode(), e.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ErrorResponse.of(400, e.getCode(), e.getMessage(), req.getRequestURI()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException e, HttpServletRequest req) {
        List<ErrorResponse.FieldError> fields = e.getBindingResult().getFieldErrors().stream()
                .map(this::toFieldError)
                .toList();
        ErrorResponse body = new ErrorResponse(
                LocalDateTime.now(), 400, "VALIDATION_FAILED",
                "입력값 검증에 실패했습니다", req.getRequestURI(), fields);
        return ResponseEntity.badRequest().body(body);
    }

    private ErrorResponse.FieldError toFieldError(FieldError fe) {
        return new ErrorResponse.FieldError(fe.getField(), fe.getDefaultMessage(), fe.getRejectedValue());
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ErrorResponse> handleIllegalArg(IllegalArgumentException e, HttpServletRequest req) {
        log.warn("IllegalArg: {}", e.getMessage());
        return ResponseEntity.badRequest()
                .body(ErrorResponse.of(400, "BAD_REQUEST", e.getMessage(), req.getRequestURI()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleUnknown(Exception e, HttpServletRequest req) {
        log.error("Unhandled error", e);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ErrorResponse.of(500, "INTERNAL_ERROR",
                        "서버에 예상치 못한 오류가 발생했습니다", req.getRequestURI()));
    }
}
EOF
ok "GlobalExceptionHandler.java"

# ─── OpenApiConfig (Swagger) ───────────────────────────────────────────
cat > "$CFG/OpenApiConfig.java" <<'EOF'
package com.mybudget.backend.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI mybudgetOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("MyBudgetBook API")
                        .description("가계부 웹앱 REST API")
                        .version("v1.0.0")
                        .contact(new Contact().name("MyBudgetBook").email("dev@mybudget.local"))
                        .license(new License().name("MIT")))
                .servers(List.of(
                        new Server().url("http://localhost:18080").description("Local dev")
                ));
    }
}
EOF
ok "OpenApiConfig.java"

# =============================================================================
say "2/5. 마스터 도메인 API (Account / Category / Tag)"
# =============================================================================

# ============ Account ============
cat > "$DTO/AccountDto.java" <<'EOF'
package com.mybudget.backend.dto;

import com.mybudget.backend.domain.Account;
import com.mybudget.backend.domain.AccountType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;

public class AccountDto {

    public record CreateRequest(
            @NotBlank @Size(max = 50) String name,
            @NotNull AccountType type,
            Long balance,
            String currency,
            String color,
            Integer statementDay,
            Integer paymentDay
    ) {}

    public record UpdateRequest(
            @NotBlank @Size(max = 50) String name,
            String color,
            Integer statementDay,
            Integer paymentDay,
            Integer sortOrder,
            Boolean archived
    ) {}

    public record Response(
            Long id,
            String name,
            AccountType type,
            Long balance,
            String currency,
            String color,
            Integer statementDay,
            Integer paymentDay,
            Integer sortOrder,
            Boolean archived,
            LocalDateTime createdAt
    ) {
        public static Response from(Account a) {
            return new Response(
                    a.getId(), a.getName(), a.getType(), a.getBalance(),
                    a.getCurrency(), a.getColor(),
                    a.getStatementDay(), a.getPaymentDay(),
                    a.getSortOrder(), a.getArchived(), a.getCreatedAt());
        }
    }
}
EOF
ok "AccountDto.java"

cat > "$SVC/AccountService.java" <<'EOF'
package com.mybudget.backend.service;

import com.mybudget.backend.domain.Account;
import com.mybudget.backend.dto.AccountDto;
import com.mybudget.backend.exception.NotFoundException;
import com.mybudget.backend.repository.AccountRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AccountService {

    private final AccountRepository repo;

    public List<AccountDto.Response> findAll() {
        return repo.findByArchivedFalseOrderBySortOrderAsc().stream()
                .map(AccountDto.Response::from).toList();
    }

    public AccountDto.Response findOne(Long id) {
        return repo.findById(id).map(AccountDto.Response::from)
                .orElseThrow(() -> new NotFoundException("Account", id));
    }

    @Transactional
    public AccountDto.Response create(AccountDto.CreateRequest req) {
        Account a = Account.builder()
                .name(req.name())
                .type(req.type())
                .balance(req.balance() != null ? req.balance() : 0L)
                .currency(req.currency() != null ? req.currency() : "KRW")
                .color(req.color())
                .statementDay(req.statementDay())
                .paymentDay(req.paymentDay())
                .sortOrder(0)
                .archived(false)
                .build();
        return AccountDto.Response.from(repo.save(a));
    }

    @Transactional
    public AccountDto.Response update(Long id, AccountDto.UpdateRequest req) {
        Account a = repo.findById(id).orElseThrow(() -> new NotFoundException("Account", id));
        a.setName(req.name());
        if (req.color() != null) a.setColor(req.color());
        if (req.statementDay() != null) a.setStatementDay(req.statementDay());
        if (req.paymentDay() != null) a.setPaymentDay(req.paymentDay());
        if (req.sortOrder() != null) a.setSortOrder(req.sortOrder());
        if (req.archived() != null) a.setArchived(req.archived());
        return AccountDto.Response.from(a);
    }

    @Transactional
    public void delete(Long id) {
        if (!repo.existsById(id)) throw new NotFoundException("Account", id);
        repo.deleteById(id);
    }
}
EOF
ok "AccountService.java"

cat > "$CTL/AccountController.java" <<'EOF'
package com.mybudget.backend.controller;

import com.mybudget.backend.dto.AccountDto;
import com.mybudget.backend.service.AccountService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/accounts")
@RequiredArgsConstructor
@Tag(name = "Account", description = "자산 계좌 관리")
public class AccountController {

    private final AccountService service;

    @GetMapping
    @Operation(summary = "활성 계좌 목록")
    public List<AccountDto.Response> list() { return service.findAll(); }

    @GetMapping("/{id}")
    @Operation(summary = "계좌 단건 조회")
    public AccountDto.Response get(@PathVariable Long id) { return service.findOne(id); }

    @PostMapping
    @Operation(summary = "계좌 생성")
    public AccountDto.Response create(@Valid @RequestBody AccountDto.CreateRequest req) {
        return service.create(req);
    }

    @PutMapping("/{id}")
    @Operation(summary = "계좌 수정")
    public AccountDto.Response update(@PathVariable Long id,
                                      @Valid @RequestBody AccountDto.UpdateRequest req) {
        return service.update(id, req);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "계좌 삭제")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
EOF
ok "AccountController.java"

# ============ Category ============
cat > "$DTO/CategoryDto.java" <<'EOF'
package com.mybudget.backend.dto;

import com.mybudget.backend.domain.Category;
import com.mybudget.backend.domain.CategoryKind;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public class CategoryDto {

    public record CreateRequest(
            @NotBlank @Size(max = 50) String name,
            @NotNull CategoryKind kind,
            Long parentId,
            String icon,
            String color,
            Integer sortOrder
    ) {}

    public record UpdateRequest(
            @NotBlank @Size(max = 50) String name,
            String icon,
            String color,
            Integer sortOrder,
            Boolean archived
    ) {}

    public record Response(
            Long id,
            String name,
            CategoryKind kind,
            Long parentId,
            String icon,
            String color,
            Integer sortOrder,
            Boolean archived
    ) {
        public static Response from(Category c) {
            return new Response(
                    c.getId(), c.getName(), c.getKind(),
                    c.getParent() != null ? c.getParent().getId() : null,
                    c.getIcon(), c.getColor(), c.getSortOrder(), c.getArchived());
        }
    }
}
EOF
ok "CategoryDto.java"

cat > "$SVC/CategoryService.java" <<'EOF'
package com.mybudget.backend.service;

import com.mybudget.backend.domain.Category;
import com.mybudget.backend.domain.CategoryKind;
import com.mybudget.backend.dto.CategoryDto;
import com.mybudget.backend.exception.NotFoundException;
import com.mybudget.backend.repository.CategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CategoryService {

    private final CategoryRepository repo;

    public List<CategoryDto.Response> findByKind(CategoryKind kind) {
        return repo.findByKindAndArchivedFalseOrderBySortOrderAsc(kind).stream()
                .map(CategoryDto.Response::from).toList();
    }

    public List<CategoryDto.Response> findAll() {
        return repo.findAll().stream().map(CategoryDto.Response::from).toList();
    }

    @Transactional
    public CategoryDto.Response create(CategoryDto.CreateRequest req) {
        Category parent = req.parentId() != null
                ? repo.findById(req.parentId()).orElseThrow(() -> new NotFoundException("Category", req.parentId()))
                : null;
        Category c = Category.builder()
                .name(req.name()).kind(req.kind()).parent(parent)
                .icon(req.icon()).color(req.color())
                .sortOrder(req.sortOrder() != null ? req.sortOrder() : 0)
                .archived(false).build();
        return CategoryDto.Response.from(repo.save(c));
    }

    @Transactional
    public CategoryDto.Response update(Long id, CategoryDto.UpdateRequest req) {
        Category c = repo.findById(id).orElseThrow(() -> new NotFoundException("Category", id));
        c.setName(req.name());
        if (req.icon() != null) c.setIcon(req.icon());
        if (req.color() != null) c.setColor(req.color());
        if (req.sortOrder() != null) c.setSortOrder(req.sortOrder());
        if (req.archived() != null) c.setArchived(req.archived());
        return CategoryDto.Response.from(c);
    }

    @Transactional
    public void delete(Long id) {
        if (!repo.existsById(id)) throw new NotFoundException("Category", id);
        repo.deleteById(id);
    }
}
EOF
ok "CategoryService.java"

cat > "$CTL/CategoryController.java" <<'EOF'
package com.mybudget.backend.controller;

import com.mybudget.backend.domain.CategoryKind;
import com.mybudget.backend.dto.CategoryDto;
import com.mybudget.backend.service.CategoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/categories")
@RequiredArgsConstructor
@Tag(name = "Category", description = "수입/지출 카테고리")
public class CategoryController {

    private final CategoryService service;

    @GetMapping
    @Operation(summary = "카테고리 목록 (kind 필터)")
    public List<CategoryDto.Response> list(@RequestParam(required = false) CategoryKind kind) {
        return kind != null ? service.findByKind(kind) : service.findAll();
    }

    @PostMapping
    public CategoryDto.Response create(@Valid @RequestBody CategoryDto.CreateRequest req) {
        return service.create(req);
    }

    @PutMapping("/{id}")
    public CategoryDto.Response update(@PathVariable Long id,
                                       @Valid @RequestBody CategoryDto.UpdateRequest req) {
        return service.update(id, req);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
EOF
ok "CategoryController.java"

# ============ Tag ============
cat > "$DTO/TagDto.java" <<'EOF'
package com.mybudget.backend.dto;

import com.mybudget.backend.domain.Tag;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class TagDto {

    public record CreateRequest(
            @NotBlank @Size(max = 50) String name,
            String color
    ) {}

    public record Response(Long id, String name, String color) {
        public static Response from(Tag t) {
            return new Response(t.getId(), t.getName(), t.getColor());
        }
    }
}
EOF
ok "TagDto.java"

cat > "$SVC/TagService.java" <<'EOF'
package com.mybudget.backend.service;

import com.mybudget.backend.domain.Tag;
import com.mybudget.backend.dto.TagDto;
import com.mybudget.backend.exception.NotFoundException;
import com.mybudget.backend.repository.TagRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TagService {

    private final TagRepository repo;

    public List<TagDto.Response> findAll() {
        return repo.findAll().stream().map(TagDto.Response::from).toList();
    }

    @Transactional
    public TagDto.Response createOrGet(TagDto.CreateRequest req) {
        return repo.findByName(req.name())
                .map(TagDto.Response::from)
                .orElseGet(() -> TagDto.Response.from(
                        repo.save(Tag.builder().name(req.name()).color(req.color()).build())));
    }

    @Transactional
    public void delete(Long id) {
        if (!repo.existsById(id)) throw new NotFoundException("Tag", id);
        repo.deleteById(id);
    }
}
EOF
ok "TagService.java"

cat > "$CTL/TagController.java" <<'EOF'
package com.mybudget.backend.controller;

import com.mybudget.backend.dto.TagDto;
import com.mybudget.backend.service.TagService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tags")
@RequiredArgsConstructor
@Tag(name = "Tag", description = "자유 태그")
public class TagController {

    private final TagService service;

    @GetMapping
    public List<TagDto.Response> list() { return service.findAll(); }

    @PostMapping
    public TagDto.Response create(@Valid @RequestBody TagDto.CreateRequest req) {
        return service.createOrGet(req);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
EOF
ok "TagController.java"

# =============================================================================
say "3/5. 거래 API (Transaction / Transfer) + 잔액 자동 재계산"
# =============================================================================

# ============ Transaction ============
cat > "$DTO/TransactionDto.java" <<'EOF'
package com.mybudget.backend.dto;

import com.mybudget.backend.domain.Transaction;
import com.mybudget.backend.domain.TransactionKind;
import com.mybudget.backend.domain.TransactionSource;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;
import java.util.Set;
import java.util.stream.Collectors;

public class TransactionDto {

    public record CreateRequest(
            @NotNull TransactionKind kind,
            @NotNull @Positive Long amount,
            @NotNull Long accountId,
            Long categoryId,
            @Size(max = 500) String memo,
            @NotNull LocalDateTime occurredAt,
            Integer installmentMonths,
            Set<String> tags,
            TransactionSource source,
            String rawSms
    ) {}

    public record UpdateRequest(
            @NotNull TransactionKind kind,
            @NotNull @Positive Long amount,
            @NotNull Long accountId,
            Long categoryId,
            @Size(max = 500) String memo,
            @NotNull LocalDateTime occurredAt,
            Set<String> tags
    ) {}

    public record Response(
            Long id,
            TransactionKind kind,
            Long amount,
            Long accountId,
            String accountName,
            Long categoryId,
            String categoryName,
            String memo,
            LocalDateTime occurredAt,
            TransactionSource source,
            Integer installmentMonths,
            Integer installmentSeq,
            Set<String> tags,
            LocalDateTime createdAt,
            LocalDateTime updatedAt
    ) {
        public static Response from(Transaction t) {
            return new Response(
                    t.getId(), t.getKind(), t.getAmount(),
                    t.getAccount().getId(), t.getAccount().getName(),
                    t.getCategory() != null ? t.getCategory().getId() : null,
                    t.getCategory() != null ? t.getCategory().getName() : null,
                    t.getMemo(), t.getOccurredAt(), t.getSource(),
                    t.getInstallmentMonths(), t.getInstallmentSeq(),
                    t.getTags().stream().map(tag -> tag.getName()).collect(Collectors.toSet()),
                    t.getCreatedAt(), t.getUpdatedAt());
        }
    }
}
EOF
ok "TransactionDto.java"

cat > "$SVC/TransactionService.java" <<'EOF'
package com.mybudget.backend.service;

import com.mybudget.backend.domain.*;
import com.mybudget.backend.dto.TransactionDto;
import com.mybudget.backend.exception.BusinessException;
import com.mybudget.backend.exception.NotFoundException;
import com.mybudget.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TransactionService {

    private final TransactionRepository repo;
    private final AccountRepository accountRepo;
    private final CategoryRepository categoryRepo;
    private final TagRepository tagRepo;

    public List<TransactionDto.Response> findByPeriod(LocalDateTime from, LocalDateTime to,
                                                     Long accountId, Long categoryId) {
        List<Transaction> list;
        if (accountId != null) {
            list = repo.findByAccountIdAndOccurredAtBetweenOrderByOccurredAtDesc(accountId, from, to);
        } else if (categoryId != null) {
            list = repo.findByCategoryIdAndOccurredAtBetweenOrderByOccurredAtDesc(categoryId, from, to);
        } else {
            list = repo.findByOccurredAtBetweenOrderByOccurredAtDesc(from, to);
        }
        return list.stream().map(TransactionDto.Response::from).toList();
    }

    public List<TransactionDto.Response> search(String keyword) {
        return repo.searchByKeyword(keyword).stream().map(TransactionDto.Response::from).toList();
    }

    public TransactionDto.Response findOne(Long id) {
        return repo.findById(id).map(TransactionDto.Response::from)
                .orElseThrow(() -> new NotFoundException("Transaction", id));
    }

    @Transactional
    public TransactionDto.Response create(TransactionDto.CreateRequest req) {
        Account account = accountRepo.findById(req.accountId())
                .orElseThrow(() -> new NotFoundException("Account", req.accountId()));
        Category category = req.categoryId() != null
                ? categoryRepo.findById(req.categoryId())
                    .orElseThrow(() -> new NotFoundException("Category", req.categoryId()))
                : null;

        if (req.kind() != TransactionKind.TRANSFER && category == null) {
            throw new BusinessException("CATEGORY_REQUIRED", "수입/지출 거래는 카테고리가 필수입니다");
        }

        Transaction t = Transaction.builder()
                .kind(req.kind()).amount(req.amount())
                .account(account).category(category)
                .memo(req.memo()).occurredAt(req.occurredAt())
                .source(req.source() != null ? req.source() : TransactionSource.MANUAL)
                .rawSms(req.rawSms())
                .installmentMonths(req.installmentMonths())
                .tags(resolveTags(req.tags()))
                .build();

        Transaction saved = repo.save(t);
        applyBalance(account, saved.getKind(), saved.getAmount(), +1);
        return TransactionDto.Response.from(saved);
    }

    @Transactional
    public TransactionDto.Response update(Long id, TransactionDto.UpdateRequest req) {
        Transaction t = repo.findById(id).orElseThrow(() -> new NotFoundException("Transaction", id));

        // 잔액 되돌리기 (기존 거래 효과 제거)
        applyBalance(t.getAccount(), t.getKind(), t.getAmount(), -1);

        Account newAccount = accountRepo.findById(req.accountId())
                .orElseThrow(() -> new NotFoundException("Account", req.accountId()));
        Category newCategory = req.categoryId() != null
                ? categoryRepo.findById(req.categoryId())
                    .orElseThrow(() -> new NotFoundException("Category", req.categoryId()))
                : null;

        t.setKind(req.kind());
        t.setAmount(req.amount());
        t.setAccount(newAccount);
        t.setCategory(newCategory);
        t.setMemo(req.memo());
        t.setOccurredAt(req.occurredAt());
        t.setTags(resolveTags(req.tags()));

        // 잔액 다시 반영 (새 값)
        applyBalance(newAccount, req.kind(), req.amount(), +1);

        return TransactionDto.Response.from(t);
    }

    @Transactional
    public void delete(Long id) {
        Transaction t = repo.findById(id).orElseThrow(() -> new NotFoundException("Transaction", id));
        applyBalance(t.getAccount(), t.getKind(), t.getAmount(), -1);
        repo.delete(t);
    }

    private Set<Tag> resolveTags(Set<String> tagNames) {
        if (tagNames == null || tagNames.isEmpty()) return new HashSet<>();
        Set<Tag> result = new HashSet<>();
        for (String name : tagNames) {
            Tag tag = tagRepo.findByName(name)
                    .orElseGet(() -> tagRepo.save(Tag.builder().name(name).build()));
            result.add(tag);
        }
        return result;
    }

    /**
     * 잔액 자동 재계산:
     *   sign = +1 → 거래 적용,  -1 → 거래 되돌림
     *   INCOME    →  잔액 + amount
     *   EXPENSE   →  잔액 - amount
     *   TRANSFER  →  여기서는 처리 안 함 (TransferService 가 처리)
     */
    private void applyBalance(Account account, TransactionKind kind, Long amount, int sign) {
        long delta = switch (kind) {
            case INCOME -> +amount;
            case EXPENSE -> -amount;
            case TRANSFER -> 0L;
        } * sign;
        account.setBalance(account.getBalance() + delta);
    }
}
EOF
ok "TransactionService.java (잔액 자동 재계산 포함)"

cat > "$CTL/TransactionController.java" <<'EOF'
package com.mybudget.backend.controller;

import com.mybudget.backend.dto.TransactionDto;
import com.mybudget.backend.service.TransactionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/transactions")
@RequiredArgsConstructor
@Tag(name = "Transaction", description = "거래 (수입/지출)")
public class TransactionController {

    private final TransactionService service;

    @GetMapping
    @Operation(summary = "기간 + 필터로 거래 목록 조회")
    public List<TransactionDto.Response> list(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to,
            @RequestParam(required = false) Long accountId,
            @RequestParam(required = false) Long categoryId) {
        return service.findByPeriod(from, to, accountId, categoryId);
    }

    @GetMapping("/search")
    @Operation(summary = "메모 키워드 검색")
    public List<TransactionDto.Response> search(@RequestParam String q) {
        return service.search(q);
    }

    @GetMapping("/{id}")
    public TransactionDto.Response get(@PathVariable Long id) { return service.findOne(id); }

    @PostMapping
    @Operation(summary = "거래 생성 (계좌 잔액 자동 갱신)")
    public TransactionDto.Response create(@Valid @RequestBody TransactionDto.CreateRequest req) {
        return service.create(req);
    }

    @PutMapping("/{id}")
    @Operation(summary = "거래 수정 (잔액 재계산)")
    public TransactionDto.Response update(@PathVariable Long id,
                                          @Valid @RequestBody TransactionDto.UpdateRequest req) {
        return service.update(id, req);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "거래 삭제 (잔액 되돌림)")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
EOF
ok "TransactionController.java"

# ============ Transfer ============
cat > "$DTO/TransferDto.java" <<'EOF'
package com.mybudget.backend.dto;

import com.mybudget.backend.domain.Transfer;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;

public class TransferDto {

    public record CreateRequest(
            @NotNull Long fromAccountId,
            @NotNull Long toAccountId,
            @NotNull @Positive Long amount,
            @NotNull LocalDateTime occurredAt,
            @Size(max = 500) String memo
    ) {}

    public record Response(
            Long id,
            Long fromAccountId,
            String fromAccountName,
            Long toAccountId,
            String toAccountName,
            Long amount,
            LocalDateTime occurredAt,
            String memo
    ) {
        public static Response from(Transfer t) {
            return new Response(t.getId(),
                    t.getFromAccount().getId(), t.getFromAccount().getName(),
                    t.getToAccount().getId(), t.getToAccount().getName(),
                    t.getAmount(), t.getOccurredAt(), t.getMemo());
        }
    }
}
EOF
ok "TransferDto.java"

cat > "$SVC/TransferService.java" <<'EOF'
package com.mybudget.backend.service;

import com.mybudget.backend.domain.Account;
import com.mybudget.backend.domain.Transfer;
import com.mybudget.backend.dto.TransferDto;
import com.mybudget.backend.exception.BusinessException;
import com.mybudget.backend.exception.NotFoundException;
import com.mybudget.backend.repository.AccountRepository;
import com.mybudget.backend.repository.TransferRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TransferService {

    private final TransferRepository repo;
    private final AccountRepository accountRepo;

    public List<TransferDto.Response> findByPeriod(LocalDateTime from, LocalDateTime to) {
        return repo.findByOccurredAtBetweenOrderByOccurredAtDesc(from, to).stream()
                .map(TransferDto.Response::from).toList();
    }

    @Transactional
    public TransferDto.Response create(TransferDto.CreateRequest req) {
        if (req.fromAccountId().equals(req.toAccountId())) {
            throw new BusinessException("SAME_ACCOUNT", "출금/입금 계좌가 동일할 수 없습니다");
        }
        Account from = accountRepo.findById(req.fromAccountId())
                .orElseThrow(() -> new NotFoundException("Account", req.fromAccountId()));
        Account to = accountRepo.findById(req.toAccountId())
                .orElseThrow(() -> new NotFoundException("Account", req.toAccountId()));

        from.setBalance(from.getBalance() - req.amount());
        to.setBalance(to.getBalance() + req.amount());

        Transfer t = Transfer.builder()
                .fromAccount(from).toAccount(to)
                .amount(req.amount()).occurredAt(req.occurredAt())
                .memo(req.memo()).build();
        return TransferDto.Response.from(repo.save(t));
    }

    @Transactional
    public void delete(Long id) {
        Transfer t = repo.findById(id).orElseThrow(() -> new NotFoundException("Transfer", id));
        // 잔액 되돌림
        t.getFromAccount().setBalance(t.getFromAccount().getBalance() + t.getAmount());
        t.getToAccount().setBalance(t.getToAccount().getBalance() - t.getAmount());
        repo.delete(t);
    }
}
EOF
ok "TransferService.java"

cat > "$CTL/TransferController.java" <<'EOF'
package com.mybudget.backend.controller;

import com.mybudget.backend.dto.TransferDto;
import com.mybudget.backend.service.TransferService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/transfers")
@RequiredArgsConstructor
@Tag(name = "Transfer", description = "계좌 간 이체")
public class TransferController {

    private final TransferService service;

    @GetMapping
    public List<TransferDto.Response> list(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to) {
        return service.findByPeriod(from, to);
    }

    @PostMapping
    public TransferDto.Response create(@Valid @RequestBody TransferDto.CreateRequest req) {
        return service.create(req);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
EOF
ok "TransferController.java"

# =============================================================================
say "4/5. 부가 API (Budget / RecurringRule / SavingsGoal / FavoriteTransaction / Stats)"
# =============================================================================

# ============ Budget ============
cat > "$DTO/BudgetDto.java" <<'EOF'
package com.mybudget.backend.dto;

import com.mybudget.backend.domain.Budget;
import jakarta.validation.constraints.*;

public class BudgetDto {

    public record UpsertRequest(
            @NotNull @Min(2000) @Max(2100) Integer year,
            @NotNull @Min(1) @Max(12) Integer month,
            @NotNull Long categoryId,
            @NotNull @PositiveOrZero Long amount
    ) {}

    public record Response(Long id, Integer year, Integer month,
                           Long categoryId, String categoryName, Long amount) {
        public static Response from(Budget b) {
            return new Response(b.getId(), b.getYear(), b.getMonth(),
                    b.getCategory().getId(), b.getCategory().getName(), b.getAmount());
        }
    }

    public record Progress(
            Long categoryId, String categoryName, String color,
            Long budgetAmount, Long spentAmount, Double percentage) {}
}
EOF
ok "BudgetDto.java"

cat > "$SVC/BudgetService.java" <<'EOF'
package com.mybudget.backend.service;

import com.mybudget.backend.domain.*;
import com.mybudget.backend.dto.BudgetDto;
import com.mybudget.backend.exception.NotFoundException;
import com.mybudget.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class BudgetService {

    private final BudgetRepository repo;
    private final CategoryRepository categoryRepo;
    private final TransactionRepository txRepo;

    public List<BudgetDto.Response> findByYearMonth(Integer year, Integer month) {
        return repo.findByYearAndMonth(year, month).stream()
                .map(BudgetDto.Response::from).toList();
    }

    @Transactional
    public BudgetDto.Response upsert(BudgetDto.UpsertRequest req) {
        Category category = categoryRepo.findById(req.categoryId())
                .orElseThrow(() -> new NotFoundException("Category", req.categoryId()));

        Budget b = repo.findByYearAndMonthAndCategoryId(req.year(), req.month(), req.categoryId())
                .orElseGet(() -> Budget.builder()
                        .year(req.year()).month(req.month())
                        .category(category).amount(req.amount()).build());
        b.setAmount(req.amount());
        return BudgetDto.Response.from(repo.save(b));
    }

    @Transactional
    public void delete(Long id) {
        if (!repo.existsById(id)) throw new NotFoundException("Budget", id);
        repo.deleteById(id);
    }

    /** 카테고리별 예산 진행률 (이달 지출 / 예산 * 100) */
    public List<BudgetDto.Progress> progress(Integer year, Integer month) {
        YearMonth ym = YearMonth.of(year, month);
        LocalDateTime from = ym.atDay(1).atStartOfDay();
        LocalDateTime to = ym.atEndOfMonth().atTime(23, 59, 59);
        List<Transaction> txs = txRepo.findByOccurredAtBetweenOrderByOccurredAtDesc(from, to);

        return repo.findByYearAndMonth(year, month).stream()
                .map(b -> {
                    long spent = txs.stream()
                            .filter(t -> t.getKind() == TransactionKind.EXPENSE)
                            .filter(t -> t.getCategory() != null
                                    && t.getCategory().getId().equals(b.getCategory().getId()))
                            .mapToLong(Transaction::getAmount)
                            .sum();
                    double pct = b.getAmount() > 0
                            ? Math.round(spent * 10000.0 / b.getAmount()) / 100.0
                            : 0.0;
                    return new BudgetDto.Progress(
                            b.getCategory().getId(), b.getCategory().getName(),
                            b.getCategory().getColor(),
                            b.getAmount(), spent, pct);
                }).toList();
    }
}
EOF
ok "BudgetService.java"

cat > "$CTL/BudgetController.java" <<'EOF'
package com.mybudget.backend.controller;

import com.mybudget.backend.dto.BudgetDto;
import com.mybudget.backend.service.BudgetService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/budgets")
@RequiredArgsConstructor
@Tag(name = "Budget", description = "월별 예산")
public class BudgetController {

    private final BudgetService service;

    @GetMapping
    public List<BudgetDto.Response> list(@RequestParam Integer year, @RequestParam Integer month) {
        return service.findByYearMonth(year, month);
    }

    @PostMapping
    @Operation(summary = "예산 설정 (있으면 갱신, 없으면 생성)")
    public BudgetDto.Response upsert(@Valid @RequestBody BudgetDto.UpsertRequest req) {
        return service.upsert(req);
    }

    @GetMapping("/progress")
    @Operation(summary = "카테고리별 예산 진행률")
    public List<BudgetDto.Progress> progress(@RequestParam Integer year,
                                             @RequestParam Integer month) {
        return service.progress(year, month);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
EOF
ok "BudgetController.java"

# ============ RecurringRule ============
cat > "$DTO/RecurringRuleDto.java" <<'EOF'
package com.mybudget.backend.dto;

import com.mybudget.backend.domain.RecurringRule;
import com.mybudget.backend.domain.TransactionKind;
import jakarta.validation.constraints.*;

import java.time.LocalDate;

public class RecurringRuleDto {

    public record CreateRequest(
            @NotBlank @Size(max = 100) String name,
            @NotNull TransactionKind kind,
            @NotNull @Positive Long amount,
            @NotNull Long accountId,
            Long categoryId,
            @NotNull @Min(1) @Max(31) Integer dayOfMonth,
            @NotNull LocalDate startDate,
            LocalDate endDate,
            @Size(max = 500) String memo
    ) {}

    public record UpdateRequest(
            @NotBlank @Size(max = 100) String name,
            @NotNull @Positive Long amount,
            @NotNull @Min(1) @Max(31) Integer dayOfMonth,
            LocalDate endDate,
            String memo,
            Boolean active
    ) {}

    public record Response(
            Long id, String name, TransactionKind kind, Long amount,
            Long accountId, String accountName,
            Long categoryId, String categoryName,
            Integer dayOfMonth, LocalDate startDate, LocalDate endDate,
            String memo, Boolean active
    ) {
        public static Response from(RecurringRule r) {
            return new Response(r.getId(), r.getName(), r.getKind(), r.getAmount(),
                    r.getAccount().getId(), r.getAccount().getName(),
                    r.getCategory() != null ? r.getCategory().getId() : null,
                    r.getCategory() != null ? r.getCategory().getName() : null,
                    r.getDayOfMonth(), r.getStartDate(), r.getEndDate(),
                    r.getMemo(), r.getActive());
        }
    }
}
EOF
ok "RecurringRuleDto.java"

cat > "$SVC/RecurringRuleService.java" <<'EOF'
package com.mybudget.backend.service;

import com.mybudget.backend.domain.*;
import com.mybudget.backend.dto.RecurringRuleDto;
import com.mybudget.backend.exception.NotFoundException;
import com.mybudget.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class RecurringRuleService {

    private final RecurringRuleRepository repo;
    private final AccountRepository accountRepo;
    private final CategoryRepository categoryRepo;

    public List<RecurringRuleDto.Response> findAll() {
        return repo.findByActiveTrueOrderByDayOfMonthAsc().stream()
                .map(RecurringRuleDto.Response::from).toList();
    }

    @Transactional
    public RecurringRuleDto.Response create(RecurringRuleDto.CreateRequest req) {
        Account account = accountRepo.findById(req.accountId())
                .orElseThrow(() -> new NotFoundException("Account", req.accountId()));
        Category category = req.categoryId() != null
                ? categoryRepo.findById(req.categoryId())
                    .orElseThrow(() -> new NotFoundException("Category", req.categoryId()))
                : null;
        RecurringRule r = RecurringRule.builder()
                .name(req.name()).kind(req.kind()).amount(req.amount())
                .account(account).category(category)
                .dayOfMonth(req.dayOfMonth())
                .startDate(req.startDate()).endDate(req.endDate())
                .memo(req.memo()).active(true).build();
        return RecurringRuleDto.Response.from(repo.save(r));
    }

    @Transactional
    public RecurringRuleDto.Response update(Long id, RecurringRuleDto.UpdateRequest req) {
        RecurringRule r = repo.findById(id).orElseThrow(() -> new NotFoundException("RecurringRule", id));
        r.setName(req.name());
        r.setAmount(req.amount());
        r.setDayOfMonth(req.dayOfMonth());
        r.setEndDate(req.endDate());
        r.setMemo(req.memo());
        if (req.active() != null) r.setActive(req.active());
        return RecurringRuleDto.Response.from(r);
    }

    @Transactional
    public void delete(Long id) {
        if (!repo.existsById(id)) throw new NotFoundException("RecurringRule", id);
        repo.deleteById(id);
    }
}
EOF
ok "RecurringRuleService.java"

cat > "$CTL/RecurringRuleController.java" <<'EOF'
package com.mybudget.backend.controller;

import com.mybudget.backend.dto.RecurringRuleDto;
import com.mybudget.backend.service.RecurringRuleService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/recurring-rules")
@RequiredArgsConstructor
@Tag(name = "RecurringRule", description = "고정지출/반복거래 규칙")
public class RecurringRuleController {

    private final RecurringRuleService service;

    @GetMapping
    public List<RecurringRuleDto.Response> list() { return service.findAll(); }

    @PostMapping
    public RecurringRuleDto.Response create(@Valid @RequestBody RecurringRuleDto.CreateRequest req) {
        return service.create(req);
    }

    @PutMapping("/{id}")
    public RecurringRuleDto.Response update(@PathVariable Long id,
                                            @Valid @RequestBody RecurringRuleDto.UpdateRequest req) {
        return service.update(id, req);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
EOF
ok "RecurringRuleController.java"

# ============ SavingsGoal ============
cat > "$DTO/SavingsGoalDto.java" <<'EOF'
package com.mybudget.backend.dto;

import com.mybudget.backend.domain.SavingsGoal;
import jakarta.validation.constraints.*;

import java.time.LocalDate;

public class SavingsGoalDto {

    public record CreateRequest(
            @NotBlank @Size(max = 100) String name,
            @NotNull @Positive Long targetAmount,
            Long currentAmount,
            @NotNull LocalDate dueDate,
            Long accountId
    ) {}

    public record Response(
            Long id, String name, Long targetAmount, Long currentAmount,
            Double progressPct, LocalDate dueDate,
            Long accountId, String accountName
    ) {
        public static Response from(SavingsGoal g) {
            double pct = g.getTargetAmount() > 0
                    ? Math.round(g.getCurrentAmount() * 10000.0 / g.getTargetAmount()) / 100.0
                    : 0.0;
            return new Response(g.getId(), g.getName(),
                    g.getTargetAmount(), g.getCurrentAmount(), pct, g.getDueDate(),
                    g.getAccount() != null ? g.getAccount().getId() : null,
                    g.getAccount() != null ? g.getAccount().getName() : null);
        }
    }
}
EOF
ok "SavingsGoalDto.java"

cat > "$SVC/SavingsGoalService.java" <<'EOF'
package com.mybudget.backend.service;

import com.mybudget.backend.domain.Account;
import com.mybudget.backend.domain.SavingsGoal;
import com.mybudget.backend.dto.SavingsGoalDto;
import com.mybudget.backend.exception.NotFoundException;
import com.mybudget.backend.repository.AccountRepository;
import com.mybudget.backend.repository.SavingsGoalRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SavingsGoalService {

    private final SavingsGoalRepository repo;
    private final AccountRepository accountRepo;

    public List<SavingsGoalDto.Response> findAll() {
        return repo.findAllByOrderByDueDateAsc().stream()
                .map(SavingsGoalDto.Response::from).toList();
    }

    @Transactional
    public SavingsGoalDto.Response create(SavingsGoalDto.CreateRequest req) {
        Account account = req.accountId() != null
                ? accountRepo.findById(req.accountId())
                    .orElseThrow(() -> new NotFoundException("Account", req.accountId()))
                : null;
        SavingsGoal g = SavingsGoal.builder()
                .name(req.name()).targetAmount(req.targetAmount())
                .currentAmount(req.currentAmount() != null ? req.currentAmount() : 0L)
                .dueDate(req.dueDate()).account(account).build();
        return SavingsGoalDto.Response.from(repo.save(g));
    }

    @Transactional
    public void delete(Long id) {
        if (!repo.existsById(id)) throw new NotFoundException("SavingsGoal", id);
        repo.deleteById(id);
    }
}
EOF
ok "SavingsGoalService.java"

cat > "$CTL/SavingsGoalController.java" <<'EOF'
package com.mybudget.backend.controller;

import com.mybudget.backend.dto.SavingsGoalDto;
import com.mybudget.backend.service.SavingsGoalService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/savings-goals")
@RequiredArgsConstructor
@Tag(name = "SavingsGoal", description = "목표 저축")
public class SavingsGoalController {

    private final SavingsGoalService service;

    @GetMapping
    public List<SavingsGoalDto.Response> list() { return service.findAll(); }

    @PostMapping
    public SavingsGoalDto.Response create(@Valid @RequestBody SavingsGoalDto.CreateRequest req) {
        return service.create(req);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
EOF
ok "SavingsGoalController.java"

# ============ FavoriteTransaction ============
cat > "$DTO/FavoriteTransactionDto.java" <<'EOF'
package com.mybudget.backend.dto;

import com.mybudget.backend.domain.FavoriteTransaction;
import com.mybudget.backend.domain.TransactionKind;
import jakarta.validation.constraints.*;

public class FavoriteTransactionDto {

    public record CreateRequest(
            @NotBlank @Size(max = 100) String label,
            @NotNull TransactionKind kind,
            @NotNull @Positive Long amount,
            @NotNull Long accountId,
            Long categoryId,
            String memo
    ) {}

    public record Response(
            Long id, String label, TransactionKind kind, Long amount,
            Long accountId, String accountName,
            Long categoryId, String categoryName, String memo, Integer sortOrder
    ) {
        public static Response from(FavoriteTransaction f) {
            return new Response(f.getId(), f.getLabel(), f.getKind(), f.getAmount(),
                    f.getAccount().getId(), f.getAccount().getName(),
                    f.getCategory() != null ? f.getCategory().getId() : null,
                    f.getCategory() != null ? f.getCategory().getName() : null,
                    f.getMemo(), f.getSortOrder());
        }
    }
}
EOF
ok "FavoriteTransactionDto.java"

cat > "$SVC/FavoriteTransactionService.java" <<'EOF'
package com.mybudget.backend.service;

import com.mybudget.backend.domain.*;
import com.mybudget.backend.dto.FavoriteTransactionDto;
import com.mybudget.backend.exception.NotFoundException;
import com.mybudget.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class FavoriteTransactionService {

    private final FavoriteTransactionRepository repo;
    private final AccountRepository accountRepo;
    private final CategoryRepository categoryRepo;

    public List<FavoriteTransactionDto.Response> findAll() {
        return repo.findAllByOrderBySortOrderAsc().stream()
                .map(FavoriteTransactionDto.Response::from).toList();
    }

    @Transactional
    public FavoriteTransactionDto.Response create(FavoriteTransactionDto.CreateRequest req) {
        Account account = accountRepo.findById(req.accountId())
                .orElseThrow(() -> new NotFoundException("Account", req.accountId()));
        Category category = req.categoryId() != null
                ? categoryRepo.findById(req.categoryId())
                    .orElseThrow(() -> new NotFoundException("Category", req.categoryId()))
                : null;
        FavoriteTransaction f = FavoriteTransaction.builder()
                .label(req.label()).kind(req.kind()).amount(req.amount())
                .account(account).category(category).memo(req.memo()).sortOrder(0).build();
        return FavoriteTransactionDto.Response.from(repo.save(f));
    }

    @Transactional
    public void delete(Long id) {
        if (!repo.existsById(id)) throw new NotFoundException("FavoriteTransaction", id);
        repo.deleteById(id);
    }
}
EOF
ok "FavoriteTransactionService.java"

cat > "$CTL/FavoriteTransactionController.java" <<'EOF'
package com.mybudget.backend.controller;

import com.mybudget.backend.dto.FavoriteTransactionDto;
import com.mybudget.backend.service.FavoriteTransactionService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/favorites")
@RequiredArgsConstructor
@Tag(name = "Favorite", description = "즐겨찾기 거래 (빠른 입력)")
public class FavoriteTransactionController {

    private final FavoriteTransactionService service;

    @GetMapping
    public List<FavoriteTransactionDto.Response> list() { return service.findAll(); }

    @PostMapping
    public FavoriteTransactionDto.Response create(@Valid @RequestBody FavoriteTransactionDto.CreateRequest req) {
        return service.create(req);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
EOF
ok "FavoriteTransactionController.java"

# ============ Stats ============
cat > "$DTO/StatsDto.java" <<'EOF'
package com.mybudget.backend.dto;

import java.time.LocalDate;
import java.util.List;

public class StatsDto {

    public record MonthlySummary(
            int year, int month,
            Long totalIncome, Long totalExpense, Long net,
            int transactionCount
    ) {}

    public record CategoryBreakdown(
            Long categoryId, String name, String color,
            Long amount, Double percentage
    ) {}

    public record CalendarDay(LocalDate date, Long income, Long expense) {}

    public record CalendarMonth(
            int year, int month,
            List<CalendarDay> days,
            Long totalIncome, Long totalExpense
    ) {}
}
EOF
ok "StatsDto.java"

cat > "$SVC/StatsService.java" <<'EOF'
package com.mybudget.backend.service;

import com.mybudget.backend.domain.Category;
import com.mybudget.backend.domain.Transaction;
import com.mybudget.backend.domain.TransactionKind;
import com.mybudget.backend.dto.StatsDto;
import com.mybudget.backend.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class StatsService {

    private final TransactionRepository txRepo;

    public StatsDto.MonthlySummary monthly(int year, int month) {
        YearMonth ym = YearMonth.of(year, month);
        LocalDateTime from = ym.atDay(1).atStartOfDay();
        LocalDateTime to = ym.atEndOfMonth().atTime(23, 59, 59);
        List<Transaction> txs = txRepo.findByOccurredAtBetweenOrderByOccurredAtDesc(from, to);

        long income = txs.stream().filter(t -> t.getKind() == TransactionKind.INCOME)
                .mapToLong(Transaction::getAmount).sum();
        long expense = txs.stream().filter(t -> t.getKind() == TransactionKind.EXPENSE)
                .mapToLong(Transaction::getAmount).sum();

        return new StatsDto.MonthlySummary(year, month, income, expense, income - expense, txs.size());
    }

    public List<StatsDto.CategoryBreakdown> byCategory(LocalDateTime from, LocalDateTime to,
                                                      TransactionKind kind) {
        List<Transaction> txs = txRepo.findByOccurredAtBetweenOrderByOccurredAtDesc(from, to).stream()
                .filter(t -> t.getKind() == kind && t.getCategory() != null)
                .toList();

        long total = txs.stream().mapToLong(Transaction::getAmount).sum();

        Map<Category, Long> grouped = txs.stream().collect(Collectors.groupingBy(
                Transaction::getCategory, Collectors.summingLong(Transaction::getAmount)));

        return grouped.entrySet().stream()
                .map(e -> new StatsDto.CategoryBreakdown(
                        e.getKey().getId(), e.getKey().getName(), e.getKey().getColor(),
                        e.getValue(),
                        total > 0 ? Math.round(e.getValue() * 10000.0 / total) / 100.0 : 0.0))
                .sorted(Comparator.comparingLong(StatsDto.CategoryBreakdown::amount).reversed())
                .toList();
    }

    public StatsDto.CalendarMonth calendar(int year, int month) {
        YearMonth ym = YearMonth.of(year, month);
        LocalDateTime from = ym.atDay(1).atStartOfDay();
        LocalDateTime to = ym.atEndOfMonth().atTime(23, 59, 59);
        List<Transaction> txs = txRepo.findByOccurredAtBetweenOrderByOccurredAtDesc(from, to);

        Map<LocalDate, long[]> byDay = new TreeMap<>();
        for (Transaction t : txs) {
            LocalDate d = t.getOccurredAt().toLocalDate();
            byDay.computeIfAbsent(d, k -> new long[2]);
            if (t.getKind() == TransactionKind.INCOME) byDay.get(d)[0] += t.getAmount();
            else if (t.getKind() == TransactionKind.EXPENSE) byDay.get(d)[1] += t.getAmount();
        }

        List<StatsDto.CalendarDay> days = byDay.entrySet().stream()
                .map(e -> new StatsDto.CalendarDay(e.getKey(), e.getValue()[0], e.getValue()[1]))
                .toList();

        long totalIncome = txs.stream().filter(t -> t.getKind() == TransactionKind.INCOME)
                .mapToLong(Transaction::getAmount).sum();
        long totalExpense = txs.stream().filter(t -> t.getKind() == TransactionKind.EXPENSE)
                .mapToLong(Transaction::getAmount).sum();

        return new StatsDto.CalendarMonth(year, month, days, totalIncome, totalExpense);
    }
}
EOF
ok "StatsService.java"

cat > "$CTL/StatsController.java" <<'EOF'
package com.mybudget.backend.controller;

import com.mybudget.backend.domain.TransactionKind;
import com.mybudget.backend.dto.StatsDto;
import com.mybudget.backend.service.StatsService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/stats")
@RequiredArgsConstructor
@Tag(name = "Stats", description = "통계 - 월간/카테고리/달력")
public class StatsController {

    private final StatsService service;

    @GetMapping("/monthly")
    @Operation(summary = "이달 수입/지출/잔액 요약")
    public StatsDto.MonthlySummary monthly(@RequestParam int year, @RequestParam int month) {
        return service.monthly(year, month);
    }

    @GetMapping("/by-category")
    @Operation(summary = "기간 + 종류로 카테고리별 합계 (파이차트용)")
    public List<StatsDto.CategoryBreakdown> byCategory(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to,
            @RequestParam(defaultValue = "EXPENSE") TransactionKind kind) {
        return service.byCategory(from, to, kind);
    }

    @GetMapping("/calendar")
    @Operation(summary = "달력 뷰 — 일자별 수입/지출")
    public StatsDto.CalendarMonth calendar(@RequestParam int year, @RequestParam int month) {
        return service.calendar(year, month);
    }
}
EOF
ok "StatsController.java"

# =============================================================================
say "5/5. WebConfig CORS 갱신 (Swagger UI 경로 허용)"
# =============================================================================

# Phase 2 의 WebConfig 가 /api/** 만 허용하므로, springdoc UI 가 별도 도메인
# 호출에서 막히지 않도록 그대로 둠. (스웨거는 동일 origin 18080 이라 문제 없음)
info "WebConfig 는 변경 불필요 (Swagger 는 동일 origin)"

# =============================================================================
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║  🎉  Phase 5 REST API 레이어 생성 완료!                                     ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}생성 결과 (총 35 파일)${NC}"
echo "  • Controller 10개 → $CTL/"
echo "  • Service    10개 → $SVC/"
echo "  • DTO        10개 → $DTO/ (각 파일에 record 2~4개 포함)"
echo "  • 예외 처리   3개 → $EXC/"
echo "  • OpenAPI 설정 1개 → $CFG/OpenApiConfig.java"
echo "  • build.gradle 패치 → springdoc-openapi 2.6.0"
echo ""
echo -e "${BOLD}다음 단계${NC}"
echo ""
echo "  1) 백엔드 재시작:"
echo -e "       ${BLUE}cd backend && ./gradlew bootRun${NC}"
echo ""
echo "  2) Swagger UI 에서 API 탐색:"
echo -e "       ${BLUE}http://localhost:18080/swagger-ui.html${NC}"
echo "     → 10개 도메인의 모든 엔드포인트 확인 가능"
echo ""
echo "  3) 간단 동작 시험 (새 터미널, jq 있으면):"
echo -e "       ${BLUE}curl http://localhost:18080/api/accounts | jq${NC}"
echo -e "       ${BLUE}curl 'http://localhost:18080/api/categories?kind=EXPENSE' | jq${NC}"
echo ""
echo "  4) 거래 추가 시험 (POST):"
cat <<'SAMPLE'
       curl -X POST http://localhost:18080/api/transactions \
         -H 'Content-Type: application/json' \
         -d '{
           "kind": "EXPENSE",
           "amount": 5500,
           "accountId": 1,
           "categoryId": 1,
           "memo": "점심 백반",
           "occurredAt": "2026-05-17T12:30:00"
         }'
SAMPLE
echo "     → 거래 추가 + 계좌 잔액 자동 감소 확인"
echo ""
echo -e "${DIM}계속해서 Phase 6 (프론트엔드 화면 자동 생성) 또는${NC}"
echo -e "${DIM}Phase 7 (SMS 파서 본격 구현) 으로 진입 가능합니다.${NC}"
echo ""
