package com.mybudget.backend.service;

import com.mybudget.backend.config.AuthContext;
import com.mybudget.backend.domain.Account;
import com.mybudget.backend.domain.SavingsGoal;
import com.mybudget.backend.domain.User;
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
        User user = AuthContext.requireUser();
        return repo.findByUserIdOrderByDueDateAsc(user.getId()).stream()
                .map(SavingsGoalDto.Response::from).toList();
    }

    @Transactional
    public SavingsGoalDto.Response create(SavingsGoalDto.CreateRequest req) {
        User user = AuthContext.requireUser();
        Account account = req.accountId() != null
                ? accountRepo.findByIdAndUserId(req.accountId(), user.getId())
                    .orElseThrow(() -> new NotFoundException("Account", req.accountId()))
                : null;
        SavingsGoal g = SavingsGoal.builder()
                .user(user)
                .name(req.name()).targetAmount(req.targetAmount())
                .currentAmount(req.currentAmount() != null ? req.currentAmount() : 0L)
                .dueDate(req.dueDate()).account(account).build();
        return SavingsGoalDto.Response.from(repo.save(g));
    }

    @Transactional
    public void delete(Long id) {
        User user = AuthContext.requireUser();
        SavingsGoal savingsGoal = repo.findByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new NotFoundException("SavingsGoal", id));
        repo.delete(savingsGoal);
    }
}
