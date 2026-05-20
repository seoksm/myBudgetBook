package com.mybudget.backend.controller;

import com.mybudget.backend.dto.FavoriteTransactionDto;
import com.mybudget.backend.service.FavoriteTransactionService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/favorites")
@RequiredArgsConstructor
@Tag(name = "Favorite", description = "즐겨찾기 거래 (빠른 입력)")
public class FavoriteTransactionController {

    private final FavoriteTransactionService service;

    @GetMapping
    public List<FavoriteTransactionDto.Response> list() { return service.findAll(); }

    @PostMapping
    public FavoriteTransactionDto.Response create(@Valid @RequestBody FavoriteTransactionDto.CreateRequest req) {
        return service.create(req);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
