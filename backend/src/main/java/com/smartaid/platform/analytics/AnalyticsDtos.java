package com.smartaid.platform.analytics;

import java.util.List;
import java.util.Map;

public class AnalyticsDtos {
    public record DashboardOverview(
        long totalIncidents,
        long activeIncidents,
        long resolvedIncidents,
        double averageResponseTimeMinutes,
        double volunteerAcceptanceRatePercent,
        Map<String, Long> incidentsByType,
        Map<String, Long> incidentsByPriority,
        long totalHospitals,
        long totalAeds,
        long availableAmbulances
    ) {}

    public record StrategyEvaluation(
        String strategyName,
        String hospitalName,
        int travelTimeEtaMinutes,
        boolean hasSpecialty,
        boolean hasResource,
        int congestionLevel,
        double compositeScore,
        String explanation
    ) {}

    public record ResearchComparison(
        String incidentId,
        String emergencyType,
        double patientLatitude,
        double patientLongitude,
        StrategyEvaluation nearestHospital,
        StrategyEvaluation randomHospital,
        StrategyEvaluation smartErRecommendation,
        String conclusion
    ) {}

    public record ResearchReport(
        List<ResearchComparison> benchmarks,
        double nearestAverageScore,
        double randomAverageScore,
        double smartErAverageScore,
        String summaryNotes
    ) {}
}
