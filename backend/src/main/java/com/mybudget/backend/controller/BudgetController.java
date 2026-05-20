package com.mybudget.backend.controller;

import com.mybudget.backend.dto.BudgetDto;
import com.mybudget.backend.service.BudgetService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/budgets")
@RequiredArgsConstructor
@Tag(name = "Budget", description = "월별 예산")
public class BudgetController {

    private final BudgetService service;

    @GetMapping
    public List<BudgetDto.Response> list(@RequestParam Integer year, @RequestParam Integer month) {
        return service.findByYearMonth(year, month);
    }

    @PostMapping
    @Operation(summary = "예산 설정 (있으면 갱신, 없으면 생성)")
    public BudgetDto.Response upsert(@Valid @RequestBody BudgetDto.UpsertRequest req) {
        return service.upsert(req);
    }

    @GetMapping("/progress")
    @Operation(summary = "카테고리별 예산 진행률")
    public List<BudgetDto.Progress> progress(@RequestParam Integer year,
                                             @RequestParam Integer month) {
        return service.progress(year, month);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
