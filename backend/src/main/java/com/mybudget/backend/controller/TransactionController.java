package com.mybudget.backend.controller;

import com.mybudget.backend.dto.TransactionDto;
import com.mybudget.backend.service.TransactionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/transactions")
@RequiredArgsConstructor
@Tag(name = "Transaction", description = "거래 (수입/지출)")
public class TransactionController {

    private final TransactionService service;

    @GetMapping
    @Operation(summary = "기간 + 필터로 거래 목록 조회")
    public List<TransactionDto.Response> list(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to,
            @RequestParam(required = false) Long accountId,
            @RequestParam(required = false) Long categoryId) {
        return service.findByPeriod(from, to, accountId, categoryId);
    }

    @GetMapping("/search")
    @Operation(summary = "메모 키워드 검색")
    public List<TransactionDto.Response> search(@RequestParam String q) {
        return service.search(q);
    }

    @GetMapping("/{id}")
    public TransactionDto.Response get(@PathVariable Long id) { return service.findOne(id); }

    @PostMapping
    @Operation(summary = "거래 생성 (계좌 잔액 자동 갱신)")
    public TransactionDto.Response create(@Valid @RequestBody TransactionDto.CreateRequest req) {
        return service.create(req);
    }

    @PutMapping("/{id}")
    @Operation(summary = "거래 수정 (잔액 재계산)")
    public TransactionDto.Response update(@PathVariable Long id,
                                          @Valid @RequestBody TransactionDto.UpdateRequest req) {
        return service.update(id, req);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "거래 삭제 (잔액 되돌림)")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
