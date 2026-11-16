package com.smartaid.platform.incident;

import com.smartaid.platform.triage.TriageInput;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Locale;
import java.util.regex.Pattern;

/** Canonical, non-sensitive fingerprint for replay-safe incident creation. */
public final class IncidentRequestFingerprint {
    private static final Pattern KEY = Pattern.compile("[A-Za-z0-9._-]{8,128}");

    private IncidentRequestFingerprint() { }

    public static String validatedKey(String key) {
        if (key == null || key.isBlank()) {
            return null;
        }
        String normalized = key.trim();
        if (!KEY.matcher(normalized).matches()) {
            throw new IllegalArgumentException("An Idempotency-Key must use 8–128 URL-safe characters");
        }
        return normalized;
    }

    public static String forRequest(IncidentDtos.CreateIncidentRequest request) {
        TriageInput triage = request.triage();
        String canonical = String.join("|",
                request.emergencyType().trim().toUpperCase(Locale.ROOT),
                Double.toHexString(request.location().latitude()),
                Double.toHexString(request.location().longitude()),
                normalizedNotes(request.notes()),
                value(triage == null ? null : triage.conscious()),
                value(triage == null ? null : triage.breathing()),
                value(triage == null ? null : triage.severeBleeding()),
                value(triage == null ? null : triage.chestPain()),
                value(triage == null ? null : triage.fallOccurred()),
                value(triage == null ? null : triage.trafficAccident()));
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(canonical.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException unavailable) {
            throw new IllegalStateException("SHA-256 is unavailable", unavailable);
        }
    }

    private static String normalizedNotes(String notes) {
        return notes == null ? "" : notes.trim();
    }

    private static String value(Boolean value) {
        return value == null ? "unknown" : value.toString();
    }
}
