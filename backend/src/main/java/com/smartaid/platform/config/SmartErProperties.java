package com.smartaid.platform.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties("smartaid.smart-er")
public record SmartErProperties(
        double travelTimeWeight,
        double capabilityWeight,
        double specialtyWeight,
        double congestionWeight) {
    public double totalWeight() {
        return travelTimeWeight + capabilityWeight + specialtyWeight + congestionWeight;
    }
}
