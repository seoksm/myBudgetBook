package com.mybudget.backend.service;

import com.mybudget.backend.config.AuthContext;
import com.mybudget.backend.domain.Account;
import com.mybudget.backend.domain.AccountType;
import com.mybudget.backend.domain.Transfer;
import com.mybudget.backend.domain.User;
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
        User user = AuthContext.requireUser();
        return repo.findByUserIdAndOccurredAtBetweenOrderByOccurredAtDesc(user.getId(), from, to).stream()
                .map(TransferDto.Response::from).toList();
    }

    @Transactional
    public TransferDto.Response create(TransferDto.CreateRequest req) {
        User user = AuthContext.requireUser();
        if (req.fromAccountId().equals(req.toAccountId())) {
            throw new BusinessException("SAME_ACCOUNT", "출금/입금 계좌가 동일할 수 없습니다");
        }
        Account from = accountRepo.findByIdAndUserId(req.fromAccountId(), user.getId())
                .orElseThrow(() -> new NotFoundException("Account", req.fromAccountId()));
        Account to = accountRepo.findByIdAndUserId(req.toAccountId(), user.getId())
                .orElseThrow(() -> new NotFoundException("Account", req.toAccountId()));
        if (from.getType() != AccountType.DEPOSIT || to.getType() != AccountType.DEPOSIT) {
            throw new BusinessException("TRANSFER_DEPOSIT_ONLY", "이체는 예금 계좌 간에만 가능합니다.");
        }

        from.setBalance(from.getBalance() - req.amount());
        to.setBalance(to.getBalance() + req.amount());

        Transfer t = Transfer.builder()
                .user(user)
                .fromAccount(from).toAccount(to)
                .amount(req.amount()).occurredAt(req.occurredAt())
                .memo(req.memo()).build();
        return TransferDto.Response.from(repo.save(t));
    }

    @Transactional
    public void delete(Long id) {
        User user = AuthContext.requireUser();
        Transfer t = repo.findByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new NotFoundException("Transfer", id));
        // 잔액 되돌림
        t.getFromAccount().setBalance(t.getFromAccount().getBalance() + t.getAmount());
        t.getToAccount().setBalance(t.getToAccount().getBalance() - t.getAmount());
        repo.delete(t);
    }
}
