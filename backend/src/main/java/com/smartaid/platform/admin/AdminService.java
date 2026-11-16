package com.smartaid.platform.admin;

import com.smartaid.platform.audit.AuditLog;
import com.smartaid.platform.audit.AuditLogRepository;
import com.smartaid.platform.audit.AuditService;
import com.smartaid.platform.auth.Role;
import com.smartaid.platform.auth.RoleRepository;
import com.smartaid.platform.auth.UserAccount;
import com.smartaid.platform.auth.UserAccountRepository;
import com.smartaid.platform.incident.IncidentRepository;
import com.smartaid.platform.incident.IncidentStatus;
import com.smartaid.platform.resource.AedDeviceRepository;
import com.smartaid.platform.resource.AmbulanceRepository;
import com.smartaid.platform.smarter.Hospital;
import com.smartaid.platform.smarter.HospitalRepository;
import com.smartaid.platform.volunteer.VolunteerProfile;
import com.smartaid.platform.volunteer.VolunteerProfileRepository;
import java.time.Instant;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class AdminService {
    private final UserAccountRepository users;
    private final RoleRepository roles;
    private final VolunteerProfileRepository volunteers;
    private final IncidentRepository incidents;
    private final HospitalRepository hospitals;
    private final AmbulanceRepository ambulances;
    private final AedDeviceRepository aeds;
    private final AuditLogRepository auditLogs;
    private final AuditService audit;
    private final JdbcTemplate jdbc;

    public AdminService(
        UserAccountRepository users,
        RoleRepository roles,
        VolunteerProfileRepository volunteers,
        IncidentRepository incidents,
        HospitalRepository hospitals,
        AmbulanceRepository ambulances,
        AedDeviceRepository aeds,
        AuditLogRepository auditLogs,
        AuditService audit,
        JdbcTemplate jdbc
    ) {
        this.users = users;
        this.roles = roles;
        this.volunteers = volunteers;
        this.incidents = incidents;
        this.hospitals = hospitals;
        this.ambulances = ambulances;
        this.aeds = aeds;
        this.auditLogs = auditLogs;
        this.audit = audit;
        this.jdbc = jdbc;
    }

    public AdminDtos.SystemOverview getOverview() {
        long totalUsers = users.count();
        long totalVolunteers = volunteers.count();
        long pendingVolunteers = volunteers.countByVerifiedFalse();
        long activeIncidents = incidents.countByStatusIn(List.of(
            IncidentStatus.NEW, IncidentStatus.SEARCHING, IncidentStatus.RESPONDER_ASSIGNED,
            IncidentStatus.EMS_ASSIGNED, IncidentStatus.AMBULANCE_ASSIGNED, IncidentStatus.IN_TRANSIT
        ));
        long totalHospitals = hospitals.count();
        long totalAmbulances = ambulances.count();
        long totalAeds = aeds.count();

        return new AdminDtos.SystemOverview(
            totalUsers,
            totalVolunteers,
            pendingVolunteers,
            activeIncidents,
            totalHospitals,
            totalAmbulances,
            totalAeds
        );
    }

    public List<AdminDtos.UserSummary> listUsers() {
        return users.findAll().stream().map(u -> new AdminDtos.UserSummary(
            u.getId(),
            u.getEmail(),
            u.getDisplayName(),
            u.isEnabled(),
            u.getRoles().stream().map(Role::getCode).toList(),
            u.getCreatedAt()
        )).toList();
    }

    @Transactional
    public AdminDtos.UserSummary updateUserRoles(UUID adminId, UUID targetUserId, List<String> roleCodes) {
        UserAccount user = users.findById(targetUserId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        Set<Role> newRoles = new HashSet<>();
        for (String code : roleCodes) {
            Role role = roles.findByCode(code.toUpperCase())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Unknown role: " + code));
            newRoles.add(role);
        }

        user.setRoles(newRoles);
        UserAccount saved = users.save(user);

        audit.record(adminId, "USER_ROLES_UPDATED", "USER", targetUserId, Map.of("roles", roleCodes));

        return new AdminDtos.UserSummary(
            saved.getId(),
            saved.getEmail(),
            saved.getDisplayName(),
            saved.isEnabled(),
            saved.getRoles().stream().map(Role::getCode).toList(),
            saved.getCreatedAt()
        );
    }

    @Transactional
    public AdminDtos.UserSummary updateUserStatus(UUID adminId, UUID targetUserId, boolean enabled) {
        UserAccount user = users.findById(targetUserId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        user.setEnabled(enabled);
        UserAccount saved = users.save(user);

        audit.record(adminId, "USER_STATUS_UPDATED", "USER", targetUserId, Map.of("enabled", enabled));

        return new AdminDtos.UserSummary(
            saved.getId(),
            saved.getEmail(),
            saved.getDisplayName(),
            saved.isEnabled(),
            saved.getRoles().stream().map(Role::getCode).toList(),
            saved.getCreatedAt()
        );
    }

    public List<AdminDtos.VolunteerSummary> listVolunteers() {
        return volunteers.findAll().stream().map(v -> {
            UserAccount account = users.findById(v.getUserId()).orElse(null);
            String email = account != null ? account.getEmail() : "unknown";
            String name = account != null ? account.getDisplayName() : "Unknown Volunteer";
            return new AdminDtos.VolunteerSummary(
                v.getUserId(),
                email,
                name,
                v.isVerified(),
                v.isAvailable(),
                v.getLatitude(),
                v.getLongitude(),
                v.getUpdatedAt()
            );
        }).toList();
    }

    @Transactional
    public void verifyVolunteer(UUID adminId, UUID volunteerId) {
        VolunteerProfile profile = volunteers.findById(volunteerId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Volunteer profile not found"));

        profile.setVerified(true);
        volunteers.save(profile);

        audit.record(adminId, "VOLUNTEER_VERIFIED", "VOLUNTEER_PROFILE", volunteerId, Map.of());
    }

    @Transactional
    public Hospital createHospital(UUID adminId, AdminDtos.CreateHospitalRequest request) {
        Hospital hospital = new Hospital(
            request.name(),
            request.latitude(),
            request.longitude(),
            true,
            request.estimatedCongestion() != null ? request.estimatedCongestion() : 25
        );
        Hospital saved = hospitals.save(hospital);

        if (request.specialties() != null) {
            for (String spec : request.specialties()) {
                jdbc.update("INSERT INTO hospital_specialties (hospital_id, specialty, verified) VALUES (?, ?, true) ON CONFLICT DO NOTHING",
                    saved.getId(), spec);
            }
        }

        if (request.resources() != null) {
            for (String res : request.resources()) {
                jdbc.update("INSERT INTO hospital_resources (hospital_id, resource_code, available, verified_at) VALUES (?, ?, true, now()) ON CONFLICT DO NOTHING",
                    saved.getId(), res);
            }
        }

        audit.record(adminId, "HOSPITAL_CREATED", "HOSPITAL", saved.getId(), Map.of("name", request.name()));
        return saved;
    }

    public List<AdminDtos.AuditLogEntry> listAuditLogs() {
        return auditLogs.findTop50ByOrderByCreatedAtDesc().stream().map(log -> new AdminDtos.AuditLogEntry(
            log.getId(),
            log.getActorId(),
            log.getAction(),
            log.getEntityType(),
            log.getEntityId(),
            log.getTraceId(),
            log.getCreatedAt()
        )).toList();
    }
}
