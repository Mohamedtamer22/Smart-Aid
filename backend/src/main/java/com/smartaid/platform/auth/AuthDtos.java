package com.smartaid.platform.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;

public final class AuthDtos {
    private AuthDtos() { }
    public record RegisterRequest(@Email @NotBlank String email, @NotBlank @Size(min = 2, max = 120) String displayName,
                                  @NotBlank @Size(min = 12, max = 128) String password, RegistrationType accountType,
                                  @Size(max = 160) String organizationName, @Size(max = 100) String registrationNumber) { }
    public record LoginRequest(@Email @NotBlank String email, @NotBlank String password) { }
    public record RefreshRequest(@NotBlank String refreshToken) { }
    public record TokenResponse(String accessToken, String refreshToken, String tokenType, long expiresInSeconds,
                                UserResponse user) { }
    public record UserResponse(String id, String email, String displayName, List<String> roles) { }
    public record HospitalPartnerStatusResponse(String organizationName, String registrationNumber, String status,
                                                Instant submittedAt) { }
}
