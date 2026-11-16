package com.smartaid.platform.profile;

import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ProfileController {
    private final ProfileService profiles;
    public ProfileController(ProfileService profiles) { this.profiles = profiles; }
    @GetMapping("/api/medical-profile") ProfileDtos.MedicalProfileResponse medical(Authentication auth) { return profiles.medicalProfile(userId(auth)); }
    @PutMapping("/api/medical-profile") ProfileDtos.MedicalProfileResponse updateMedical(@Valid @RequestBody ProfileDtos.MedicalProfileRequest request, Authentication auth) { return profiles.updateMedicalProfile(userId(auth), request); }
    @GetMapping("/api/emergency-contacts") List<ProfileDtos.ContactResponse> contacts(Authentication auth) { return profiles.contacts(userId(auth)); }
    @PostMapping("/api/emergency-contacts") ResponseEntity<ProfileDtos.ContactResponse> createContact(@Valid @RequestBody ProfileDtos.ContactRequest request, Authentication auth) { return ResponseEntity.status(HttpStatus.CREATED).body(profiles.createContact(userId(auth), request)); }
    @PutMapping("/api/emergency-contacts/{id}") ProfileDtos.ContactResponse updateContact(@PathVariable UUID id, @Valid @RequestBody ProfileDtos.ContactRequest request, Authentication auth) { return profiles.updateContact(userId(auth), id, request); }
    @DeleteMapping("/api/emergency-contacts/{id}") ResponseEntity<Void> deleteContact(@PathVariable UUID id, Authentication auth) { profiles.deleteContact(userId(auth), id); return ResponseEntity.noContent().build(); }
    private UUID userId(Authentication auth) { return (UUID) auth.getPrincipal(); }
}
