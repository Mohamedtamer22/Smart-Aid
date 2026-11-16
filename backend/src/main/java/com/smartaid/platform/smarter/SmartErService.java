package com.smartaid.platform.smarter;

import com.smartaid.platform.config.SmartErProperties;
import java.util.Comparator;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class SmartErService {
    private final SmartErProperties weights;
    public SmartErService(SmartErProperties weights) {
        if (weights.totalWeight() <= 0) throw new IllegalArgumentException("Smart ER weights must total more than zero");
        this.weights = weights;
    }
    public List<HospitalRecommendation> rank(List<HospitalCandidate> candidates) {
        double longestEta = candidates.stream().mapToDouble(HospitalCandidate::etaMinutes).max().orElse(1);
        return candidates.stream().filter(HospitalCandidate::verified).filter(candidate -> candidate.specialtyMatch() && candidate.resourcesAvailable())
                .map(candidate -> score(candidate, longestEta)).sorted(Comparator.comparingDouble(HospitalRecommendation::score).reversed()).toList();
    }
    private HospitalRecommendation score(HospitalCandidate candidate, double longestEta) {
        double travel = Math.max(0, 100 * (1 - candidate.etaMinutes() / Math.max(longestEta, 1)));
        double capability = candidate.resourcesAvailable() ? 100 : 0;
        double specialty = candidate.specialtyMatch() ? 100 : 0;
        double congestion = candidate.congestionPercent() == null ? 0 : 100 - candidate.congestionPercent();
        double raw = weights.travelTimeWeight() * travel + weights.capabilityWeight() * capability + weights.specialtyWeight() * specialty + weights.congestionWeight() * congestion;
        double score = Math.round(raw / weights.totalWeight() * 100.0) / 100.0;
        List<String> reasons = new java.util.ArrayList<>(List.of("Verified specialty match", "Required resources marked available", "ETA is an estimate based on straight-line distance"));
        if (candidate.congestionPercent() == null) reasons.add("Congestion data is unavailable and receives no positive score"); else reasons.add("Reported congestion: " + candidate.congestionPercent() + "%");
        return new HospitalRecommendation(candidate.hospitalId(), candidate.name(), score, candidate.etaMinutes(), travel, capability, specialty, congestion, reasons);
    }
    public record HospitalCandidate(java.util.UUID hospitalId, String name, boolean verified, int etaMinutes, boolean specialtyMatch, boolean resourcesAvailable, Integer congestionPercent) { }
    public record HospitalRecommendation(java.util.UUID hospitalId, String hospitalName, double score, int etaMinutes, double travelTimeScore, double capabilityScore, double specialtyScore, double congestionScore, List<String> reasons) { }
}
