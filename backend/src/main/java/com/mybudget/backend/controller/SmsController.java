package com.mybudget.backend.controller;

import com.mybudget.backend.dto.SmsParseDto;
import com.mybudget.backend.service.SmsParserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/sms")
@RequiredArgsConstructor
@Tag(name = "Sms", description = "카드 SMS 자동 파싱")
public class SmsController {

    private final SmsParserService service;

    @PostMapping("/parse")
    @Operation(summary = "SMS 텍스트를 파싱하여 거래 후보 반환")
    public SmsParseDto.Response parse(@Valid @RequestBody SmsParseDto.Request req) {
        return service.parse(req.text());
    }
}
