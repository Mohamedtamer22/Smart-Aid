package com.smartaid.platform.profile;

import com.smartaid.platform.audit.AuditService;
import com.smartaid.platform.exception.ApiException;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ProfileService {
    private final MedicalProfileRepository profiles;
    private final EmergencyContactRepository contacts;
    private final AuditService audit;
    public ProfileService(MedicalProfileRepository profiles, EmergencyContactRepository contacts, AuditService audit) {
        this.profiles = profiles; this.contacts = contacts; this.audit = audit;
    }
    @Transactional
    public ProfileDtos.MedicalProfileResponse medicalProfile(UUID userId) {
        audit.record(userId, "MEDICAL_PROFILE_ACCESSED", "MEDICAL_PROFILE", userId);
        return profiles.findById(userId).map(this::toMedical).orElse(new ProfileDtos.MedicalProfileResponse(null, null, null, null, false, null));
    }
    @Transactional
    public ProfileDtos.MedicalProfileResponse updateMedicalProfile(UUID userId, ProfileDtos.MedicalProfileRequest request) {
        MedicalProfile profile = profiles.findById(userId).orElseGet(() -> new MedicalProfile(userId));
        profile.update(request.bloodType(), request.allergies(), request.medications(), request.emergencyNotes(), request.sharingConsent());
        profile = profiles.save(profile); audit.record(userId, "MEDICAL_PROFILE_UPDATED", "MEDICAL_PROFILE", userId);
        return toMedical(profile);
    }
    @Transactional(readOnly = true)
    public List<ProfileDtos.ContactResponse> contacts(UUID userId) { return contacts.findByUserIdOrderByPrimaryDescCreatedAtAsc(userId).stream().map(this::toContact).toList(); }
    @Transactional
    public ProfileDtos.ContactResponse createContact(UUID userId, ProfileDtos.ContactRequest request) {
        if (request.primary()) contacts.findByUserIdOrderByPrimaryDescCreatedAtAsc(userId).stream().filter(EmergencyContact::isPrimary).forEach(contact -> contact.update(contact.getFullName(), contact.getRelationship(), contact.getPhone(), false));
        EmergencyContact contact = contacts.save(new EmergencyContact(userId, request.fullName(), request.relationship(), request.phone(), request.primary()));
        audit.record(userId, "EMERGENCY_CONTACT_CREATED", "EMERGENCY_CONTACT", contact.getId()); return toContact(contact);
    }
    @Transactional
    public ProfileDtos.ContactResponse updateContact(UUID userId, UUID id, ProfileDtos.ContactRequest request) {
        EmergencyContact contact = ownedContact(id, userId);
        if (request.primary()) contacts.findByUserIdOrderByPrimaryDescCreatedAtAsc(userId).stream().filter(other -> other.isPrimary() && !other.getId().equals(id)).forEach(other -> other.update(other.getFullName(), other.getRelationship(), other.getPhone(), false));
        contact.update(request.fullName(), request.relationship(), request.phone(), request.primary());
        audit.record(userId, "EMERGENCY_CONTACT_UPDATED", "EMERGENCY_CONTACT", id); return toContact(contact);
    }
    @Transactional
    public void deleteContact(UUID userId, UUID id) { contacts.delete(ownedContact(id, userId)); audit.record(userId, "EMERGENCY_CONTACT_DELETED", "EMERGENCY_CONTACT", id); }
    private EmergencyContact ownedContact(UUID id, UUID userId) { return contacts.findByIdAndUserId(id, userId).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "CONTACT_NOT_FOUND", "Emergency contact was not found")); }
    private ProfileDtos.MedicalProfileResponse toMedical(MedicalProfile profile) { return new ProfileDtos.MedicalProfileResponse(profile.getBloodType(), profile.getAllergies(), profile.getMedications(), profile.getEmergencyNotes(), profile.isSharingConsent(), profile.getUpdatedAt()); }
    private ProfileDtos.ContactResponse toContact(EmergencyContact contact) { return new ProfileDtos.ContactResponse(contact.getId().toString(), contact.getFullName(), contact.getRelationship(), contact.getPhone(), contact.isPrimary()); }
}
