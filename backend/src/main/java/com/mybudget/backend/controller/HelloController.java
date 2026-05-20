package com.mybudget.backend.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class HelloController {

    @GetMapping("/hello")
    public Map<String, Object> hello() {
        return Map.of(
            "message", "Hello from Spring Boot 3.5 !",
            "timestamp", LocalDateTime.now().toString(),
            "backend", "Spring Boot",
            "java", System.getProperty("java.version")
        );
    }
}
