package com.smartaid.platform.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties("smartaid.dispatch")
public record DispatchProperties(double maximumRadiusKm) { }
