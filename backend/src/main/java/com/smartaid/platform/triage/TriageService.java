package com.smartaid.platform.triage;

import java.util.ArrayList;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class TriageService {
    public TriageResult summarize(TriageInput input) {
        List<String> flags = new ArrayList<>();
        if (Boolean.FALSE.equals(input.breathing())) flags.add("breathing concern reported");
        if (Boolean.FALSE.equals(input.conscious())) flags.add("unconsciousness reported");
        if (Boolean.TRUE.equals(input.severeBleeding())) flags.add("severe bleeding reported");
        if (Boolean.TRUE.equals(input.chestPain())) flags.add("chest pain reported");
        if (Boolean.TRUE.equals(input.trafficAccident())) flags.add("traffic accident reported");
        if (Boolean.TRUE.equals(input.fallOccurred())) flags.add("fall reported");
        String priority = flags.stream().anyMatch(flag -> flag.contains("breathing") || flag.contains("unconscious") || flag.contains("bleeding")) ? "CRITICAL" : flags.isEmpty() ? "STANDARD" : "HIGH";
        String summary = flags.isEmpty() ? "No structured triage concerns were reported." : "Reported: " + String.join(", ", flags) + ".";
        return new TriageResult(priority, summary + " This is structured decision support, not a diagnosis.");
    }
    public record TriageResult(String priority, String summary) { }
}
