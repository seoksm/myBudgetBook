package com.mybudget.backend.controller;

import com.mybudget.backend.dto.RecurringRuleDto;
import com.mybudget.backend.service.RecurringRuleService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/recurring-rules")
@RequiredArgsConstructor
@Tag(name = "RecurringRule", description = "고정지출/반복거래 규칙")
public class RecurringRuleController {

    private final RecurringRuleService service;

    @GetMapping
    public List<RecurringRuleDto.Response> list() { return service.findAll(); }

    @PostMapping
    public RecurringRuleDto.Response create(@Valid @RequestBody RecurringRuleDto.CreateRequest req) {
        return service.create(req);
    }

    @PutMapping("/{id}")
    public RecurringRuleDto.Response update(@PathVariable Long id,
                                            @Valid @RequestBody RecurringRuleDto.UpdateRequest req) {
        return service.update(id, req);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
