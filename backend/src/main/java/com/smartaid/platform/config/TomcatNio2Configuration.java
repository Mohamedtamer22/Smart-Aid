package com.smartaid.platform.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.web.embedded.tomcat.TomcatServletWebServerFactory;
import org.springframework.boot.web.server.WebServerFactoryCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Opt-in compatibility path for local Windows installations whose current JDK
 * cannot create Tomcat's default NIO loopback selector. Java 21 remains the
 * standard runtime; enable this only with SMARTAID_TOMCAT_NIO2=true.
 */
@Configuration
@ConditionalOnProperty(prefix = "smartaid.runtime", name = "tomcat-nio2", havingValue = "true")
public class TomcatNio2Configuration {

    @Bean
    WebServerFactoryCustomizer<TomcatServletWebServerFactory> useNio2Protocol() {
        return factory -> factory.setProtocol("org.apache.coyote.http11.Http11Nio2Protocol");
    }
}
