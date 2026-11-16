package com.smartaid.platform.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {
    @Bean
    OpenAPI smartAidOpenApi() {
        return new OpenAPI().info(new Info().title("Smart Aid API").version("0.1.0")
                .description("Local emergency-response decision support. Not an emergency service or diagnostic system."));
    }
}
