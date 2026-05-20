package com.mybudget.backend.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI mybudgetOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("MyBudgetBook API")
                        .description("가계부 웹앱 REST API")
                        .version("v1.0.0")
                        .contact(new Contact().name("MyBudgetBook").email("dev@mybudget.local"))
                        .license(new License().name("MIT")))
                .servers(List.of(
                        new Server().url("http://localhost:18080").description("budget_book_codex local dev")
                ));
    }
}
