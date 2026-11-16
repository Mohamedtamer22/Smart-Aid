package com.smartaid.platform.volunteer;

import java.util.Comparator;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.springframework.stereotype.Service;

@Service
public class SmartDispatchService {
    public static Set<String> requiredSkillsFor(String emergencyType) {
        return switch (emergencyType) {
            case "CARDIAC" -> Set.of("CPR", "AED");
            case "TRAUMA", "ACCIDENT" -> Set.of("FIRST_AID");
            default -> Set.of();
        };
    }
    public List<DispatchRecommendation> rank(double incidentLatitude, double incidentLongitude, Set<String> requiredSkills, List<ResponderCandidate> candidates) {
        return candidates.stream().filter(ResponderCandidate::available).filter(ResponderCandidate::verified).filter(ResponderCandidate::certificationValid)
                .filter(candidate -> candidate.skills().containsAll(requiredSkills)).map(candidate -> score(incidentLatitude, incidentLongitude, requiredSkills, candidate))
                .sorted(Comparator.comparingDouble(DispatchRecommendation::score).reversed()).toList();
    }
    private DispatchRecommendation score(double latitude, double longitude, Set<String> requiredSkills, ResponderCandidate candidate) {
        double distance = haversineKm(latitude, longitude, candidate.latitude(), candidate.longitude());
        double eta = Math.ceil(distance / 0.5); // transparent development estimate: 30 km/h
        double distanceScore = Math.max(0, 100 - distance * 6);
        double etaScore = Math.max(0, 100 - eta * 5);
        double skillScore = requiredSkills.isEmpty() ? 100 : 100.0 * requiredSkills.size() / Math.max(1, candidate.skills().size());
        double score = round(distanceScore * .45 + etaScore * .25 + skillScore * .20 + 10.0);
        List<String> reasons = List.of(String.format("%.1f km estimated distance", distance), "verified availability", "valid certification", requiredSkills.isEmpty() ? "no specialty skill requested" : "required skills matched");
        return new DispatchRecommendation(candidate.userId(), score, (int) eta, candidate.skills().stream().filter(requiredSkills::contains).sorted().toList(), reasons);
    }
    public static double haversineKm(double lat1, double lon1, double lat2, double lon2) {
        double dLat = Math.toRadians(lat2 - lat1), dLon = Math.toRadians(lon2 - lon1);
        double a = Math.pow(Math.sin(dLat / 2), 2) + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) * Math.pow(Math.sin(dLon / 2), 2);
        return 6371.0088 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }
    private static double round(double value) { return Math.round(value * 100.0) / 100.0; }
    public record ResponderCandidate(UUID userId, boolean verified, boolean available, boolean certificationValid, double latitude, double longitude, Set<String> skills) { }
    public record DispatchRecommendation(UUID responderId, double score, int etaMinutes, List<String> matchingSkills, List<String> reasons) { }
}
