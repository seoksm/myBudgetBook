package com.mybudget.backend.service;

import com.mybudget.backend.config.AuthContext;
import com.mybudget.backend.domain.Account;
import com.mybudget.backend.domain.AccountType;
import com.mybudget.backend.domain.Transaction;
import com.mybudget.backend.domain.TransactionKind;
import com.mybudget.backend.domain.Transfer;
import com.mybudget.backend.domain.User;
import com.mybudget.backend.dto.AccountDto;
import com.mybudget.backend.exception.BusinessException;
import com.mybudget.backend.exception.NotFoundException;
import com.mybudget.backend.repository.AccountRepository;
import com.mybudget.backend.repository.TransactionRepository;
import com.mybudget.backend.repository.TransferRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AccountService {

    private final AccountRepository repo;
    private final TransactionRepository transactionRepo;
    private final TransferRepository transferRepo;

    public List<AccountDto.Response> findAll() {
        User user = AuthContext.requireUser();
        return repo.findByUserIdAndArchivedFalseOrderBySortOrderAsc(user.getId()).stream()
                .map(AccountDto.Response::from).toList();
    }

    public AccountDto.Response findOne(Long id) {
        User user = AuthContext.requireUser();
        return repo.findByIdAndUserId(id, user.getId()).map(AccountDto.Response::from)
                .orElseThrow(() -> new NotFoundException("Account", id));
    }

    @Transactional
    public AccountDto.Response create(AccountDto.CreateRequest req) {
        User user = AuthContext.requireUser();
        Account linkedDeposit = resolveLinkedDeposit(user, req.type(), req.linkedDepositAccountId());
        Account a = Account.builder()
                .user(user)
                .linkedDepositAccount(linkedDeposit)
                .name(req.name())
                .type(req.type())
                .balance(isBalanceManaged(req.type()) && req.balance() != null ? req.balance() : 0L)
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
        User user = AuthContext.requireUser();
        Account a = repo.findByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new NotFoundException("Account", id));
        a.setName(req.name());
        if (req.color() != null) a.setColor(req.color());
        if (req.statementDay() != null) a.setStatementDay(req.statementDay());
        if (req.paymentDay() != null) a.setPaymentDay(req.paymentDay());
        if (isBalanceManaged(a.getType()) && req.balance() != null) {
            a.setBalance(req.balance());
        }
        if (!isBalanceManaged(a.getType())) {
            a.setBalance(0L);
        }
        if (a.getType() == AccountType.CHECK_CARD && req.linkedDepositAccountId() != null) {
            a.setLinkedDepositAccount(resolveLinkedDeposit(user, a.getType(), req.linkedDepositAccountId()));
        }
        if (req.sortOrder() != null) a.setSortOrder(req.sortOrder());
        if (req.archived() != null) a.setArchived(req.archived());
        return AccountDto.Response.from(a);
    }

    @Transactional
    public void delete(Long id) {
        User user = AuthContext.requireUser();
        Account account = repo.findByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new NotFoundException("Account", id));
        repo.delete(account);
    }

    @Transactional
    public List<AccountDto.Response> recalculateBalances() {
        User user = AuthContext.requireUser();
        List<Account> accounts = repo.findByUserIdOrderBySortOrderAsc(user.getId());
        Map<Long, Account> accountById = accounts.stream()
                .collect(Collectors.toMap(Account::getId, Function.identity()));

        accounts.forEach(account -> account.setBalance(0L));

        transactionRepo.findByUserIdOrderByOccurredAtAsc(user.getId())
                .forEach(transaction -> applyTransactionBalance(transaction, accountById));
        transferRepo.findByUserIdOrderByOccurredAtAsc(user.getId())
                .forEach(transfer -> applyTransferBalance(transfer, accountById));

        return accounts.stream()
                .filter(account -> !Boolean.TRUE.equals(account.getArchived()))
                .map(AccountDto.Response::from)
                .toList();
    }

    public List<AccountDto.ActivityResponse> activities(Long id, LocalDateTime from, LocalDateTime to) {
        User user = AuthContext.requireUser();
        Account account = repo.findByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new NotFoundException("Account", id));

        List<AccountDto.ActivityResponse> activities = new ArrayList<>();
        transactionRepo.findAccountActivities(user.getId(), id, from, to).stream()
                .map(t -> toTransactionActivity(account, t))
                .forEach(activities::add);
        transferRepo.findAccountTransfers(user.getId(), id, from, to).stream()
                .map(t -> toTransferActivity(account, t))
                .forEach(activities::add);

        return activities.stream()
                .sorted(Comparator.comparing(AccountDto.ActivityResponse::occurredAt).reversed())
                .toList();
    }

    private Account resolveLinkedDeposit(User user, AccountType type, Long linkedDepositAccountId) {
        if (type != AccountType.CHECK_CARD) {
            return null;
        }
        if (linkedDepositAccountId == null) {
            return null;
        }

        Account linkedDeposit = repo.findByIdAndUserId(linkedDepositAccountId, user.getId())
                .orElseThrow(() -> new NotFoundException("Account", linkedDepositAccountId));
        if (linkedDeposit.getType() != AccountType.DEPOSIT) {
            throw new BusinessException("LINKED_ACCOUNT_NOT_DEPOSIT", "체크카드는 예금 계좌에만 연결할 수 있습니다.");
        }
        return linkedDeposit;
    }

    private boolean isBalanceManaged(AccountType type) {
        return type != AccountType.CHECK_CARD && type != AccountType.CREDIT_CARD;
    }

    private void applyTransactionBalance(Transaction transaction, Map<Long, Account> accountById) {
        Account balanceAccount = resolveTransactionBalanceAccount(transaction, accountById);
        transaction.setBalanceAccount(balanceAccount);
        if (balanceAccount == null) {
            return;
        }

        long delta = switch (transaction.getKind()) {
            case INCOME -> transaction.getAmount();
            case EXPENSE -> -transaction.getAmount();
            case TRANSFER -> 0L;
        };
        balanceAccount.setBalance(balanceAccount.getBalance() + delta);
    }

    private Account resolveTransactionBalanceAccount(Transaction transaction, Map<Long, Account> accountById) {
        Account existingBalanceAccount = transaction.getBalanceAccount();
        if (existingBalanceAccount != null) {
            Account managed = accountById.get(existingBalanceAccount.getId());
            if (managed != null && isBalanceManaged(managed.getType())) {
                return managed;
            }
        }

        Account account = accountById.get(transaction.getAccount().getId());
        if (account == null) {
            return null;
        }
        if (transaction.getKind() == TransactionKind.EXPENSE && account.getType() == AccountType.CHECK_CARD) {
            Account linkedDeposit = account.getLinkedDepositAccount();
            if (linkedDeposit == null) {
                return null;
            }
            Account managedLinkedDeposit = accountById.get(linkedDeposit.getId());
            return managedLinkedDeposit != null && isBalanceManaged(managedLinkedDeposit.getType())
                    ? managedLinkedDeposit
                    : null;
        }
        return isBalanceManaged(account.getType()) ? account : null;
    }

    private void applyTransferBalance(Transfer transfer, Map<Long, Account> accountById) {
        Account from = accountById.get(transfer.getFromAccount().getId());
        Account to = accountById.get(transfer.getToAccount().getId());
        if (from != null && isBalanceManaged(from.getType())) {
            from.setBalance(from.getBalance() - transfer.getAmount());
        }
        if (to != null && isBalanceManaged(to.getType())) {
            to.setBalance(to.getBalance() + transfer.getAmount());
        }
    }

    private AccountDto.ActivityResponse toTransactionActivity(Account account, Transaction t) {
        boolean balanceAccountActivity = t.getBalanceAccount() != null
                && t.getBalanceAccount().getId().equals(account.getId())
                && !t.getAccount().getId().equals(account.getId());
        long signedAmount = switch (t.getKind()) {
            case INCOME -> t.getAmount();
            case EXPENSE -> -t.getAmount();
            case TRANSFER -> 0L;
        };
        String title = t.getCategory() != null ? t.getCategory().getName() : "미분류";
        String subtitle = balanceAccountActivity
                ? t.getAccount().getName() + " 사용"
                : t.getAccount().getName();
        return new AccountDto.ActivityResponse(
                "TRANSACTION",
                t.getId(),
                t.getKind().name(),
                signedAmount,
                title,
                subtitle,
                t.getMemo(),
                t.getOccurredAt(),
                t.getAccount().getId(),
                t.getAccount().getName()
        );
    }

    private AccountDto.ActivityResponse toTransferActivity(Account account, Transfer t) {
        boolean outgoing = t.getFromAccount().getId().equals(account.getId());
        Account related = outgoing ? t.getToAccount() : t.getFromAccount();
        return new AccountDto.ActivityResponse(
                "TRANSFER",
                t.getId(),
                outgoing ? "TRANSFER_OUT" : "TRANSFER_IN",
                outgoing ? -t.getAmount() : t.getAmount(),
                outgoing ? related.getName() + "으로 이체" : related.getName() + "에서 이체",
                outgoing ? "출금" : "입금",
                t.getMemo(),
                t.getOccurredAt(),
                related.getId(),
                related.getName()
        );
    }
}
