package com.mybudget.backend.controller;

import com.mybudget.backend.dto.SavingsGoalDto;
import com.mybudget.backend.service.SavingsGoalService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/savings-goals")
@RequiredArgsConstructor
@Tag(name = "SavingsGoal", description = "목표 저축")
public class SavingsGoalController {

    private final SavingsGoalService service;

    @GetMapping
    public List<SavingsGoalDto.Response> list() { return service.findAll(); }

    @PostMapping
    public SavingsGoalDto.Response create(@Valid @RequestBody SavingsGoalDto.CreateRequest req) {
        return service.create(req);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
