package com.mybudget.backend.service;

import com.mybudget.backend.config.AuthContext;
import com.mybudget.backend.domain.Account;
import com.mybudget.backend.domain.AccountType;
import com.mybudget.backend.domain.Category;
import com.mybudget.backend.domain.CategoryKind;
import com.mybudget.backend.domain.Transaction;
import com.mybudget.backend.domain.TransactionKind;
import com.mybudget.backend.domain.TransactionSource;
import com.mybudget.backend.domain.Transfer;
import com.mybudget.backend.domain.User;
import com.mybudget.backend.dto.TransactionDto;
import com.mybudget.backend.repository.AccountRepository;
import com.mybudget.backend.repository.CategoryRepository;
import com.mybudget.backend.repository.TransactionRepository;
import com.mybudget.backend.repository.TransferRepository;
import com.mybudget.backend.repository.UserRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.time.LocalDateTime;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
class TransactionServiceBalanceTest {

    @Autowired
    private TransactionService transactionService;

    @Autowired
    private AccountService accountService;

    @Autowired
    private UserRepository userRepo;

    @Autowired
    private AccountRepository accountRepo;

    @Autowired
    private CategoryRepository categoryRepo;

    @Autowired
    private TransactionRepository transactionRepo;

    @Autowired
    private TransferRepository transferRepo;

    @AfterEach
    void tearDown() {
        AuthContext.clear();
    }

    @Test
    void updateLegacyTransactionWithoutBalanceAccountRevertsPreviousAccount() {
        User user = userRepo.save(User.builder()
                .email("legacy-balance@example.com")
                .passwordHash("hash")
                .displayName("legacy")
                .build());
        AuthContext.setUser(user);

        Account previous = accountRepo.save(Account.builder()
                .user(user)
                .name("이전 예금")
                .type(AccountType.DEPOSIT)
                .balance(90_000L)
                .currency("KRW")
                .archived(false)
                .sortOrder(1)
                .build());
        Account next = accountRepo.save(Account.builder()
                .user(user)
                .name("변경 예금")
                .type(AccountType.DEPOSIT)
                .balance(30_000L)
                .currency("KRW")
                .archived(false)
                .sortOrder(2)
                .build());
        Category category = categoryRepo.save(Category.builder()
                .user(user)
                .name("테스트 지출")
                .kind(CategoryKind.EXPENSE)
                .archived(false)
                .sortOrder(1)
                .build());

        Transaction legacy = transactionRepo.save(Transaction.builder()
                .user(user)
                .kind(TransactionKind.EXPENSE)
                .amount(10_000L)
                .account(previous)
                .balanceAccount(null)
                .category(category)
                .memo("legacy")
                .occurredAt(LocalDateTime.of(2026, 5, 20, 9, 0))
                .source(TransactionSource.MANUAL)
                .build());

        transactionService.update(legacy.getId(), new TransactionDto.UpdateRequest(
                TransactionKind.EXPENSE,
                12_000L,
                next.getId(),
                category.getId(),
                "updated",
                LocalDateTime.of(2026, 5, 20, 10, 0),
                Set.of()
        ));

        Account savedPrevious = accountRepo.findById(previous.getId()).orElseThrow();
        Account savedNext = accountRepo.findById(next.getId()).orElseThrow();

        assertThat(savedPrevious.getBalance()).isEqualTo(100_000L);
        assertThat(savedNext.getBalance()).isEqualTo(18_000L);
    }

    @Test
    void updateLegacyCheckCardTransactionWithoutBalanceAccountRevertsLinkedDeposit() {
        User user = userRepo.save(User.builder()
                .email("legacy-check-card-balance@example.com")
                .passwordHash("hash")
                .displayName("legacy-check-card")
                .build());
        AuthContext.setUser(user);

        Account livingExpense = accountRepo.save(Account.builder()
                .user(user)
                .name("생활비통장")
                .type(AccountType.DEPOSIT)
                .balance(90_000L)
                .currency("KRW")
                .archived(false)
                .sortOrder(1)
                .build());
        Account checkCard = accountRepo.save(Account.builder()
                .user(user)
                .name("생활비 체크카드")
                .type(AccountType.CHECK_CARD)
                .linkedDepositAccount(livingExpense)
                .balance(0L)
                .currency("KRW")
                .archived(false)
                .sortOrder(2)
                .build());
        Category category = categoryRepo.save(Category.builder()
                .user(user)
                .name("식비")
                .kind(CategoryKind.EXPENSE)
                .archived(false)
                .sortOrder(1)
                .build());

        Transaction legacy = transactionRepo.save(Transaction.builder()
                .user(user)
                .kind(TransactionKind.EXPENSE)
                .amount(10_000L)
                .account(checkCard)
                .balanceAccount(null)
                .category(category)
                .memo("legacy check card")
                .occurredAt(LocalDateTime.of(2026, 5, 20, 9, 0))
                .source(TransactionSource.MANUAL)
                .build());

        transactionService.update(legacy.getId(), new TransactionDto.UpdateRequest(
                TransactionKind.EXPENSE,
                12_000L,
                checkCard.getId(),
                category.getId(),
                "updated check card",
                LocalDateTime.of(2026, 5, 20, 10, 0),
                Set.of()
        ));

        Account savedLivingExpense = accountRepo.findById(livingExpense.getId()).orElseThrow();
        Transaction savedTransaction = transactionRepo.findById(legacy.getId()).orElseThrow();

        assertThat(savedLivingExpense.getBalance()).isEqualTo(88_000L);
        assertThat(savedTransaction.getBalanceAccount().getId()).isEqualTo(livingExpense.getId());
    }

    @Test
    void recalculateBalancesFromTransactionsAndTransfers() {
        User user = userRepo.save(User.builder()
                .email("recalculate-balance@example.com")
                .passwordHash("hash")
                .displayName("recalculate")
                .build());
        AuthContext.setUser(user);

        Account livingExpense = accountRepo.save(Account.builder()
                .user(user)
                .name("생활비통장")
                .type(AccountType.DEPOSIT)
                .balance(999_999L)
                .currency("KRW")
                .archived(false)
                .sortOrder(1)
                .build());
        Account savings = accountRepo.save(Account.builder()
                .user(user)
                .name("저축통장")
                .type(AccountType.DEPOSIT)
                .balance(888_888L)
                .currency("KRW")
                .archived(false)
                .sortOrder(2)
                .build());
        Account checkCard = accountRepo.save(Account.builder()
                .user(user)
                .name("생활비 체크카드")
                .type(AccountType.CHECK_CARD)
                .linkedDepositAccount(livingExpense)
                .balance(777_777L)
                .currency("KRW")
                .archived(false)
                .sortOrder(3)
                .build());
        Account creditCard = accountRepo.save(Account.builder()
                .user(user)
                .name("신용카드")
                .type(AccountType.CREDIT_CARD)
                .balance(666_666L)
                .currency("KRW")
                .archived(false)
                .sortOrder(4)
                .build());
        Category income = categoryRepo.save(Category.builder()
                .user(user)
                .name("월급")
                .kind(CategoryKind.INCOME)
                .archived(false)
                .sortOrder(1)
                .build());
        Category expense = categoryRepo.save(Category.builder()
                .user(user)
                .name("식비")
                .kind(CategoryKind.EXPENSE)
                .archived(false)
                .sortOrder(2)
                .build());

        transactionRepo.save(Transaction.builder()
                .user(user)
                .kind(TransactionKind.INCOME)
                .amount(20_000L)
                .account(livingExpense)
                .balanceAccount(livingExpense)
                .category(income)
                .occurredAt(LocalDateTime.of(2026, 5, 20, 9, 0))
                .source(TransactionSource.MANUAL)
                .build());
        Transaction legacyCheckCardExpense = transactionRepo.save(Transaction.builder()
                .user(user)
                .kind(TransactionKind.EXPENSE)
                .amount(10_000L)
                .account(checkCard)
                .balanceAccount(null)
                .category(expense)
                .occurredAt(LocalDateTime.of(2026, 5, 20, 10, 0))
                .source(TransactionSource.MANUAL)
                .build());
        transactionRepo.save(Transaction.builder()
                .user(user)
                .kind(TransactionKind.EXPENSE)
                .amount(30_000L)
                .account(creditCard)
                .balanceAccount(null)
                .category(expense)
                .occurredAt(LocalDateTime.of(2026, 5, 20, 11, 0))
                .source(TransactionSource.MANUAL)
                .build());
        transferRepo.save(Transfer.builder()
                .user(user)
                .fromAccount(livingExpense)
                .toAccount(savings)
                .amount(5_000L)
                .occurredAt(LocalDateTime.of(2026, 5, 20, 12, 0))
                .build());

        accountService.recalculateBalances();

        Account savedLivingExpense = accountRepo.findById(livingExpense.getId()).orElseThrow();
        Account savedSavings = accountRepo.findById(savings.getId()).orElseThrow();
        Account savedCheckCard = accountRepo.findById(checkCard.getId()).orElseThrow();
        Account savedCreditCard = accountRepo.findById(creditCard.getId()).orElseThrow();
        Transaction savedLegacyCheckCardExpense = transactionRepo.findById(legacyCheckCardExpense.getId()).orElseThrow();

        assertThat(savedLivingExpense.getBalance()).isEqualTo(5_000L);
        assertThat(savedSavings.getBalance()).isEqualTo(5_000L);
        assertThat(savedCheckCard.getBalance()).isZero();
        assertThat(savedCreditCard.getBalance()).isZero();
        assertThat(savedLegacyCheckCardExpense.getBalanceAccount().getId()).isEqualTo(livingExpense.getId());
    }
}
