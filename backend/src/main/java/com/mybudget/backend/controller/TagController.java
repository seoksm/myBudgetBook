package com.mybudget.backend.controller;

import com.mybudget.backend.dto.TagDto;
import com.mybudget.backend.service.TagService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tags")
@RequiredArgsConstructor
@Tag(name = "Tag", description = "자유 태그")
public class TagController {

    private final TagService service;

    @GetMapping
    public List<TagDto.Response> list() { return service.findAll(); }

    @PostMapping
    public TagDto.Response create(@Valid @RequestBody TagDto.CreateRequest req) {
        return service.createOrGet(req);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
