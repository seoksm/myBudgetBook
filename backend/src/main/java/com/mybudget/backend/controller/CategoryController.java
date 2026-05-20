package com.mybudget.backend.controller;

import com.mybudget.backend.domain.CategoryKind;
import com.mybudget.backend.dto.CategoryDto;
import com.mybudget.backend.service.CategoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/categories")
@RequiredArgsConstructor
@Tag(name = "Category", description = "수입/지출 카테고리")
public class CategoryController {

    private final CategoryService service;

    @GetMapping
    @Operation(summary = "카테고리 목록 (kind 필터)")
    public List<CategoryDto.Response> list(@RequestParam(required = false) CategoryKind kind) {
        return kind != null ? service.findByKind(kind) : service.findAll();
    }

    @PostMapping
    public CategoryDto.Response create(@Valid @RequestBody CategoryDto.CreateRequest req) {
        return service.create(req);
    }

    @PutMapping("/{id}")
    public CategoryDto.Response update(@PathVariable Long id,
                                       @Valid @RequestBody CategoryDto.UpdateRequest req) {
        return service.update(id, req);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
