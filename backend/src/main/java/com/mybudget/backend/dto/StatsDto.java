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
