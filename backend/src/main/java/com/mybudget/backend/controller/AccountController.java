package com.mybudget.backend.controller;

import com.mybudget.backend.dto.AccountDto;
import com.mybudget.backend.service.AccountService;
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
@RequestMapping("/api/accounts")
@RequiredArgsConstructor
@Tag(name = "Account", description = "자산 계좌 관리")
public class AccountController {

    private final AccountService service;

    @GetMapping
    @Operation(summary = "활성 계좌 목록")
    public List<AccountDto.Response> list() { return service.findAll(); }

    @GetMapping("/{id}")
    @Operation(summary = "계좌 단건 조회")
    public AccountDto.Response get(@PathVariable Long id) { return service.findOne(id); }

    @GetMapping("/{id}/activities")
    @Operation(summary = "계좌별 수입/지출/이체 내역")
    public List<AccountDto.ActivityResponse> activities(
            @PathVariable Long id,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to) {
        return service.activities(id, from, to);
    }

    @PostMapping
    @Operation(summary = "계좌 생성")
    public AccountDto.Response create(@Valid @RequestBody AccountDto.CreateRequest req) {
        return service.create(req);
    }

    @PostMapping("/recalculate-balances")
    @Operation(summary = "거래/이체 내역 기준 자산 잔액 재계산")
    public List<AccountDto.Response> recalculateBalances() {
        return service.recalculateBalances();
    }

    @PutMapping("/{id}")
    @Operation(summary = "계좌 수정")
    public AccountDto.Response update(@PathVariable Long id,
                                      @Valid @RequestBody AccountDto.UpdateRequest req) {
        return service.update(id, req);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "계좌 삭제")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
