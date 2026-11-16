package com.smartaid.platform.profile;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.Instant;

public final class ProfileDtos {
    private ProfileDtos() { }
    public record MedicalProfileRequest(@Size(max = 8) String bloodType, @Size(max = 2000) String allergies,
            @Size(max = 2000) String medications, @Size(max = 2000) String emergencyNotes, boolean sharingConsent) { }
    public record MedicalProfileResponse(String bloodType, String allergies, String medications, String emergencyNotes,
            boolean sharingConsent, Instant updatedAt) { }
    public record ContactRequest(@NotBlank @Size(max = 120) String fullName, @Size(max = 80) String relationship,
            @NotBlank @Size(max = 32) @Pattern(regexp = "^[+0-9()\\- ]+$", message = "must be a valid phone number") String phone, boolean primary) { }
    public record ContactResponse(String id, String fullName, String relationship, String phone, boolean primary) { }
}
