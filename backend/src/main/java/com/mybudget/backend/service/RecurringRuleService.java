package com.mybudget.backend.service;

import com.mybudget.backend.config.AuthContext;
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
        User user = AuthContext.requireUser();
        return repo.findByUserIdAndActiveTrueOrderByDayOfMonthAsc(user.getId()).stream()
                .map(RecurringRuleDto.Response::from).toList();
    }

    @Transactional
    public RecurringRuleDto.Response create(RecurringRuleDto.CreateRequest req) {
        User user = AuthContext.requireUser();
        Account account = accountRepo.findByIdAndUserId(req.accountId(), user.getId())
                .orElseThrow(() -> new NotFoundException("Account", req.accountId()));
        Category category = req.categoryId() != null
                ? categoryRepo.findByIdAndUserId(req.categoryId(), user.getId())
                    .orElseThrow(() -> new NotFoundException("Category", req.categoryId()))
                : null;
        RecurringRule r = RecurringRule.builder()
                .user(user)
                .name(req.name()).kind(req.kind()).amount(req.amount())
                .account(account).category(category)
                .dayOfMonth(req.dayOfMonth())
                .startDate(req.startDate()).endDate(req.endDate())
                .memo(req.memo()).active(true).build();
        return RecurringRuleDto.Response.from(repo.save(r));
    }

    @Transactional
    public RecurringRuleDto.Response update(Long id, RecurringRuleDto.UpdateRequest req) {
        User user = AuthContext.requireUser();
        RecurringRule r = repo.findByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new NotFoundException("RecurringRule", id));
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
        User user = AuthContext.requireUser();
        RecurringRule recurringRule = repo.findByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new NotFoundException("RecurringRule", id));
        repo.delete(recurringRule);
    }
}
