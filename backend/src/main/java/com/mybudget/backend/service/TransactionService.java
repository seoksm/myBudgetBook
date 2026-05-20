package com.mybudget.backend.service;

import com.mybudget.backend.config.AuthContext;
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
        User user = AuthContext.requireUser();
        List<Transaction> list;
        if (accountId != null) {
            list = repo.findByUserIdAndAccountIdAndOccurredAtBetweenOrderByOccurredAtDesc(user.getId(), accountId, from, to);
        } else if (categoryId != null) {
            list = repo.findByUserIdAndCategoryIdAndOccurredAtBetweenOrderByOccurredAtDesc(user.getId(), categoryId, from, to);
        } else {
            list = repo.findByUserIdAndOccurredAtBetweenOrderByOccurredAtDesc(user.getId(), from, to);
        }
        return list.stream().map(TransactionDto.Response::from).toList();
    }

    public List<TransactionDto.Response> search(String keyword) {
        User user = AuthContext.requireUser();
        return repo.searchByKeyword(user.getId(), keyword).stream().map(TransactionDto.Response::from).toList();
    }

    public TransactionDto.Response findOne(Long id) {
        User user = AuthContext.requireUser();
        return repo.findByIdAndUserId(id, user.getId()).map(TransactionDto.Response::from)
                .orElseThrow(() -> new NotFoundException("Transaction", id));
    }

    @Transactional
    public TransactionDto.Response create(TransactionDto.CreateRequest req) {
        User user = AuthContext.requireUser();
        if (req.kind() == TransactionKind.TRANSFER) {
            throw new BusinessException("USE_TRANSFER_API", "이체는 계좌 간 이체 기능을 사용해주세요.");
        }
        Account account = accountRepo.findByIdAndUserId(req.accountId(), user.getId())
                .orElseThrow(() -> new NotFoundException("Account", req.accountId()));
        Category category = req.categoryId() != null
                ? categoryRepo.findByIdAndUserId(req.categoryId(), user.getId())
                    .orElseThrow(() -> new NotFoundException("Category", req.categoryId()))
                : null;

        if (req.kind() != TransactionKind.TRANSFER && category == null) {
            throw new BusinessException("CATEGORY_REQUIRED", "수입/지출 거래는 카테고리가 필수입니다");
        }
        Account balanceAccount = resolveBalanceAccount(account, req.kind());

        Transaction t = Transaction.builder()
                .user(user)
                .kind(req.kind()).amount(req.amount())
                .account(account).balanceAccount(balanceAccount).category(category)
                .memo(req.memo()).occurredAt(req.occurredAt())
                .source(req.source() != null ? req.source() : TransactionSource.MANUAL)
                .rawSms(req.rawSms())
                .installmentMonths(req.installmentMonths())
                .tags(resolveTags(user, req.tags()))
                .build();

        Transaction saved = repo.save(t);
        applyBalance(saved, +1);
        return TransactionDto.Response.from(saved);
    }

    @Transactional
    public TransactionDto.Response update(Long id, TransactionDto.UpdateRequest req) {
        User user = AuthContext.requireUser();
        Transaction t = repo.findByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new NotFoundException("Transaction", id));
        if (req.kind() == TransactionKind.TRANSFER) {
            throw new BusinessException("USE_TRANSFER_API", "이체는 계좌 간 이체 기능을 사용해주세요.");
        }

        // 잔액 되돌리기 (기존 거래 효과 제거)
        applyBalance(t, -1);

        Account newAccount = accountRepo.findByIdAndUserId(req.accountId(), user.getId())
                .orElseThrow(() -> new NotFoundException("Account", req.accountId()));
        Category newCategory = req.categoryId() != null
                ? categoryRepo.findByIdAndUserId(req.categoryId(), user.getId())
                    .orElseThrow(() -> new NotFoundException("Category", req.categoryId()))
                : null;
        if (newCategory == null) {
            throw new BusinessException("CATEGORY_REQUIRED", "수입/지출 거래는 카테고리가 필수입니다");
        }

        t.setKind(req.kind());
        t.setAmount(req.amount());
        t.setAccount(newAccount);
        t.setBalanceAccount(resolveBalanceAccount(newAccount, req.kind()));
        t.setCategory(newCategory);
        t.setMemo(req.memo());
        t.setOccurredAt(req.occurredAt());
        t.setTags(resolveTags(user, req.tags()));

        // 잔액 다시 반영 (새 값)
        applyBalance(t, +1);

        return TransactionDto.Response.from(t);
    }

    @Transactional
    public void delete(Long id) {
        User user = AuthContext.requireUser();
        Transaction t = repo.findByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new NotFoundException("Transaction", id));
        applyBalance(t, -1);
        repo.delete(t);
    }

    private Account resolveBalanceAccount(Account account, TransactionKind kind) {
        if (account.getType() == AccountType.CREDIT_CARD) {
            return null;
        }
        if (account.getType() == AccountType.CHECK_CARD && kind != TransactionKind.EXPENSE) {
            return null;
        }
        if (kind == TransactionKind.EXPENSE && account.getType() == AccountType.CHECK_CARD) {
            Account linkedDeposit = account.getLinkedDepositAccount();
            if (linkedDeposit == null) {
                throw new BusinessException("CHECK_CARD_LINK_REQUIRED", "체크카드 지출은 연결 예금 계좌가 필요합니다.");
            }
            if (linkedDeposit.getType() != AccountType.DEPOSIT) {
                throw new BusinessException("CHECK_CARD_LINK_INVALID", "체크카드는 예금 계좌에만 연결할 수 있습니다.");
            }
            return linkedDeposit;
        }
        return account;
    }

    private Set<Tag> resolveTags(User user, Set<String> tagNames) {
        if (tagNames == null || tagNames.isEmpty()) return new HashSet<>();
        Set<Tag> result = new HashSet<>();
        for (String name : tagNames) {
            Tag tag = tagRepo.findByUserIdAndName(user.getId(), name)
                    .orElseGet(() -> tagRepo.save(Tag.builder().user(user).name(name).build()));
            result.add(tag);
        }
        return result;
    }

    /**
     * 잔액 자동 재계산:
     *   sign = +1 → 거래 적용,  -1 → 거래 되돌림
     *   INCOME    →  잔액 + amount
     *   EXPENSE   →  잔액 - amount
     *   체크카드 지출은 거래 계좌가 아니라 balanceAccount(연결 예금)의 잔액을 조정
     *   신용카드와 체크카드 자체 계좌는 잔액을 관리하지 않음
     *   balanceAccount 도입 전 거래는 계좌 유형에 맞춰 잔액 반영 계좌를 보정
     */
    private void applyBalance(Transaction transaction, int sign) {
        Account account = resolveAppliedBalanceAccount(transaction);
        if (account == null) {
            return;
        }
        long delta = switch (transaction.getKind()) {
            case INCOME -> +transaction.getAmount();
            case EXPENSE -> -transaction.getAmount();
            case TRANSFER -> 0L;
        } * sign;
        account.setBalance(account.getBalance() + delta);
    }

    private Account resolveAppliedBalanceAccount(Transaction transaction) {
        Account balanceAccount = transaction.getBalanceAccount();
        if (balanceAccount != null && isBalanceManaged(balanceAccount.getType())) {
            return balanceAccount;
        }

        Account account = transaction.getAccount();
        if (account != null
                && transaction.getKind() == TransactionKind.EXPENSE
                && account.getType() == AccountType.CHECK_CARD) {
            Account linkedDeposit = account.getLinkedDepositAccount();
            if (linkedDeposit != null && isBalanceManaged(linkedDeposit.getType())) {
                return linkedDeposit;
            }
        }
        if (account != null && isBalanceManaged(account.getType())) {
            return account;
        }
        return null;
    }

    private boolean isBalanceManaged(AccountType type) {
        return type != AccountType.CHECK_CARD && type != AccountType.CREDIT_CARD;
    }
}
