package com.smartaid.platform.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties("smartaid.security")
public record SecurityProperties(
        String jwtSecret,
        long accessTokenMinutes,
        long refreshTokenDays,
        String corsAllowedOrigins) {
}
