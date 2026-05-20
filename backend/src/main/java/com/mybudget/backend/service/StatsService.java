package com.mybudget.backend.service;

import com.mybudget.backend.config.AuthContext;
import com.mybudget.backend.domain.Category;
import com.mybudget.backend.domain.Transaction;
import com.mybudget.backend.domain.TransactionKind;
import com.mybudget.backend.domain.User;
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
        User user = AuthContext.requireUser();
        YearMonth ym = YearMonth.of(year, month);
        LocalDateTime from = ym.atDay(1).atStartOfDay();
        LocalDateTime to = ym.atEndOfMonth().atTime(23, 59, 59);
        List<Transaction> txs = txRepo.findByUserIdAndOccurredAtBetweenOrderByOccurredAtDesc(user.getId(), from, to);

        long income = txs.stream().filter(t -> t.getKind() == TransactionKind.INCOME)
                .mapToLong(Transaction::getAmount).sum();
        long expense = txs.stream().filter(t -> t.getKind() == TransactionKind.EXPENSE)
                .mapToLong(Transaction::getAmount).sum();

        return new StatsDto.MonthlySummary(year, month, income, expense, income - expense, txs.size());
    }

    public List<StatsDto.CategoryBreakdown> byCategory(LocalDateTime from, LocalDateTime to,
                                                      TransactionKind kind) {
        User user = AuthContext.requireUser();
        List<Transaction> txs = txRepo.findByUserIdAndOccurredAtBetweenOrderByOccurredAtDesc(user.getId(), from, to).stream()
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
        User user = AuthContext.requireUser();
        YearMonth ym = YearMonth.of(year, month);
        LocalDateTime from = ym.atDay(1).atStartOfDay();
        LocalDateTime to = ym.atEndOfMonth().atTime(23, 59, 59);
        List<Transaction> txs = txRepo.findByUserIdAndOccurredAtBetweenOrderByOccurredAtDesc(user.getId(), from, to);

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
