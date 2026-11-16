package com.smartaid.platform.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties("smartaid.demo")
public record DemoProperties(boolean seed) { }
