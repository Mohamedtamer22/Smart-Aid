package com.smartaid.platform.analytics;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/analytics")
public class AnalyticsController {
    private final AnalyticsService analyticsService;

    public AnalyticsController(AnalyticsService analyticsService) {
        this.analyticsService = analyticsService;
    }

    @GetMapping("/dashboard")
    @PreAuthorize("hasAnyRole('EMS', 'ADMIN', 'VOLUNTEER')")
    public AnalyticsDtos.DashboardOverview getDashboard() {
        return analyticsService.getDashboard();
    }

    @GetMapping("/research/smart-er-comparison")
    @PreAuthorize("hasAnyRole('EMS', 'ADMIN')")
    public AnalyticsDtos.ResearchReport runComparison() {
        return analyticsService.runHospitalStrategiesComparison();
    }
}
