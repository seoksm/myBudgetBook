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
