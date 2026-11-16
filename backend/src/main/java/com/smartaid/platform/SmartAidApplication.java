package com.smartaid.platform;

import com.smartaid.platform.config.DispatchProperties;
import com.smartaid.platform.config.DemoProperties;
import com.smartaid.platform.config.SecurityProperties;
import com.smartaid.platform.config.SmartErProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties({SecurityProperties.class, SmartErProperties.class, DispatchProperties.class, DemoProperties.class})
public class SmartAidApplication {
    public static void main(String[] args) {
        SpringApplication.run(SmartAidApplication.class, args);
    }
}
