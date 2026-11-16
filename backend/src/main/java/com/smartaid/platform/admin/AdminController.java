package com.smartaid.platform.admin;

import com.smartaid.platform.smarter.Hospital;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {
    private final AdminService admin;

    public AdminController(AdminService admin) {
        this.admin = admin;
    }

    @GetMapping("/overview")
    public AdminDtos.SystemOverview getOverview() {
        return admin.getOverview();
    }

    @GetMapping("/users")
    public List<AdminDtos.UserSummary> listUsers() {
        return admin.listUsers();
    }

    @PatchMapping("/users/{id}/roles")
    public AdminDtos.UserSummary updateUserRoles(
        @PathVariable UUID id,
        @Valid @RequestBody AdminDtos.UpdateUserRolesRequest request,
        Authentication authentication
    ) {
        UUID adminId = (UUID) authentication.getPrincipal();
        return admin.updateUserRoles(adminId, id, request.roles());
    }

    @PatchMapping("/users/{id}/status")
    public AdminDtos.UserSummary updateUserStatus(
        @PathVariable UUID id,
        @Valid @RequestBody AdminDtos.UpdateUserStatusRequest request,
        Authentication authentication
    ) {
        UUID adminId = (UUID) authentication.getPrincipal();
        return admin.updateUserStatus(adminId, id, request.enabled());
    }

    @GetMapping("/volunteers")
    public List<AdminDtos.VolunteerSummary> listVolunteers() {
        return admin.listVolunteers();
    }

    @PostMapping("/volunteers/{id}/verify")
    public void verifyVolunteer(@PathVariable UUID id, Authentication authentication) {
        UUID adminId = (UUID) authentication.getPrincipal();
        admin.verifyVolunteer(adminId, id);
    }

    @PostMapping("/hospitals")
    public ResponseEntity<Hospital> createHospital(
        @Valid @RequestBody AdminDtos.CreateHospitalRequest request,
        Authentication authentication
    ) {
        UUID adminId = (UUID) authentication.getPrincipal();
        Hospital created = admin.createHospital(adminId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @GetMapping("/audit-logs")
    public List<AdminDtos.AuditLogEntry> listAuditLogs() {
        return admin.listAuditLogs();
    }
}
