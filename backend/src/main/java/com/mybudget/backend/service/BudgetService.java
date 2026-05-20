package com.mybudget.backend.service;

import com.mybudget.backend.config.AuthContext;
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
        User user = AuthContext.requireUser();
        return repo.findByUserIdAndYearAndMonth(user.getId(), year, month).stream()
                .map(BudgetDto.Response::from).toList();
    }

    @Transactional
    public BudgetDto.Response upsert(BudgetDto.UpsertRequest req) {
        User user = AuthContext.requireUser();
        Category category = categoryRepo.findByIdAndUserId(req.categoryId(), user.getId())
                .orElseThrow(() -> new NotFoundException("Category", req.categoryId()));

        Budget b = repo.findByUserIdAndYearAndMonthAndCategoryId(user.getId(), req.year(), req.month(), req.categoryId())
                .orElseGet(() -> Budget.builder()
                        .user(user)
                        .year(req.year()).month(req.month())
                        .category(category).amount(req.amount()).build());
        b.setAmount(req.amount());
        return BudgetDto.Response.from(repo.save(b));
    }

    @Transactional
    public void delete(Long id) {
        User user = AuthContext.requireUser();
        Budget budget = repo.findByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new NotFoundException("Budget", id));
        repo.delete(budget);
    }

    /** 카테고리별 예산 진행률 (이달 지출 / 예산 * 100) */
    public List<BudgetDto.Progress> progress(Integer year, Integer month) {
        User user = AuthContext.requireUser();
        YearMonth ym = YearMonth.of(year, month);
        LocalDateTime from = ym.atDay(1).atStartOfDay();
        LocalDateTime to = ym.atEndOfMonth().atTime(23, 59, 59);
        List<Transaction> txs = txRepo.findByUserIdAndOccurredAtBetweenOrderByOccurredAtDesc(user.getId(), from, to);

        return repo.findByUserIdAndYearAndMonth(user.getId(), year, month).stream()
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
