package com.smartaid.platform.auth;

import com.smartaid.platform.audit.AuditService;
import com.smartaid.platform.config.SecurityProperties;
import com.smartaid.platform.exception.ApiException;
import com.smartaid.platform.security.JwtService;
import com.smartaid.platform.volunteer.VolunteerProfile;
import com.smartaid.platform.volunteer.VolunteerProfileRepository;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {
    private final UserAccountRepository users;
    private final RoleRepository roles;
    private final RefreshTokenRepository refreshTokens;
    private final VolunteerProfileRepository volunteerProfiles;
    private final HospitalPartnerRequestRepository hospitalPartnerRequests;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final SecurityProperties properties;
    private final AuditService audit;
    private final SecureRandom random = new SecureRandom();

    public AuthService(UserAccountRepository users, RoleRepository roles, RefreshTokenRepository refreshTokens,
            VolunteerProfileRepository volunteerProfiles, HospitalPartnerRequestRepository hospitalPartnerRequests,
            PasswordEncoder passwordEncoder, JwtService jwtService, SecurityProperties properties, AuditService audit) {
        this.users = users; this.roles = roles; this.refreshTokens = refreshTokens; this.passwordEncoder = passwordEncoder;
        this.volunteerProfiles = volunteerProfiles; this.hospitalPartnerRequests = hospitalPartnerRequests;
        this.jwtService = jwtService; this.properties = properties; this.audit = audit;
    }
    @Transactional
    public AuthDtos.TokenResponse register(AuthDtos.RegisterRequest request) {
        String email = request.email().trim().toLowerCase();
        if (users.findByEmailIgnoreCase(email).isPresent()) throw new ApiException(HttpStatus.CONFLICT, "EMAIL_IN_USE", "An account already uses this email");
        RegistrationType accountType = request.accountType() == null ? RegistrationType.CITIZEN : request.accountType();
        Role userRole = role("USER");
        UserAccount user = users.save(new UserAccount(email, passwordEncoder.encode(request.password()), request.displayName().trim(), userRole));
        if (accountType == RegistrationType.VOLUNTEER) {
            user.grantRole(role("VOLUNTEER"));
            volunteerProfiles.save(new VolunteerProfile(user.getId()));
            audit.record(user.getId(), "VOLUNTEER_REGISTRATION_REQUESTED", "VOLUNTEER_PROFILE", user.getId());
        } else if (accountType == RegistrationType.HOSPITAL) {
            String organizationName = requiredOrganizationName(request.organizationName());
            user.grantRole(role("HOSPITAL"));
            hospitalPartnerRequests.save(new HospitalPartnerRequest(user.getId(), organizationName, blankToNull(request.registrationNumber())));
            audit.record(user.getId(), "HOSPITAL_PARTNER_REQUESTED", "HOSPITAL_PARTNER_REQUEST", user.getId());
        }
        audit.record(user.getId(), "REGISTER_" + accountType.name(), "USER", user.getId());
        return issueTokens(user);
    }
    @Transactional
    public AuthDtos.TokenResponse login(AuthDtos.LoginRequest request) {
        UserAccount user = users.findByEmailIgnoreCase(request.email().trim()).orElseThrow(() -> invalidLogin());
        if (!user.isEnabled() || !passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            audit.record(null, "FAILED_LOGIN", "USER", null); throw invalidLogin();
        }
        audit.record(user.getId(), "LOGIN", "USER", user.getId());
        return issueTokens(user);
    }
    @Transactional
    public AuthDtos.TokenResponse refresh(AuthDtos.RefreshRequest request) {
        RefreshToken oldToken = refreshTokens.findByTokenHash(hash(request.refreshToken()))
                .filter(RefreshToken::isActive).orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "INVALID_REFRESH_TOKEN", "Session has expired; please sign in again"));
        oldToken.revoke();
        audit.record(oldToken.getUser().getId(), "REFRESH_TOKEN", "SESSION", null);
        return issueTokens(oldToken.getUser());
    }
    @Transactional
    public void logout(AuthDtos.RefreshRequest request) {
        refreshTokens.findByTokenHash(hash(request.refreshToken())).ifPresent(token -> { token.revoke(); audit.record(token.getUser().getId(), "LOGOUT", "SESSION", null); });
    }
    private AuthDtos.TokenResponse issueTokens(UserAccount user) {
        List<String> roleCodes = user.getRoles().stream().map(Role::getCode).sorted().toList();
        String rawRefresh = newRefreshToken();
        refreshTokens.save(new RefreshToken(user, hash(rawRefresh), Instant.now().plusSeconds(properties.refreshTokenDays() * 86_400)));
        return new AuthDtos.TokenResponse(jwtService.createAccessToken(user.getId(), user.getEmail(), roleCodes), rawRefresh,
                "Bearer", properties.accessTokenMinutes() * 60, new AuthDtos.UserResponse(user.getId().toString(), user.getEmail(), user.getDisplayName(), roleCodes));
    }
    private Role role(String code) {
        return roles.findByCode(code).orElseThrow(() -> new IllegalStateException(code + " role missing"));
    }
    private String requiredOrganizationName(String value) {
        String normalized = blankToNull(value);
        if (normalized == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "ORGANIZATION_NAME_REQUIRED",
                    "An organization name is required for a hospital partner request");
        }
        return normalized;
    }
    private String blankToNull(String value) {
        if (value == null || value.trim().isEmpty()) return null;
        return value.trim();
    }
    private String newRefreshToken() { byte[] bytes = new byte[48]; random.nextBytes(bytes); return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes); }
    private String hash(String value) { try { return java.util.HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8))); } catch (Exception e) { throw new IllegalStateException(e); } }
    private ApiException invalidLogin() { return new ApiException(HttpStatus.UNAUTHORIZED, "INVALID_CREDENTIALS", "Email or password is incorrect"); }
}
