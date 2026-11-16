package com.smartaid.platform.incident;

import com.smartaid.platform.audit.AuditService;
import com.smartaid.platform.exception.ApiException;
import com.smartaid.platform.notification.NotificationService;
import com.smartaid.platform.notification.NotificationType;
import com.smartaid.platform.triage.TriageAssessment;
import com.smartaid.platform.triage.TriageAssessmentRepository;
import com.smartaid.platform.triage.TriageInput;
import com.smartaid.platform.triage.TriageService;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class IncidentService {
    private final IncidentRepository incidents;
    private final EmergencyTypeRepository emergencyTypes;
    private final IncidentStatusHistoryRepository history;
    private final TriageAssessmentRepository triageAssessments;
    private final TriageService triage;
    private final AuditService audit;
    private final SimpMessagingTemplate websocket;
    private final NotificationService notifications;
    private final IncidentIdempotencyKeyRepository idempotencyKeys;
    public IncidentService(IncidentRepository incidents, EmergencyTypeRepository emergencyTypes, IncidentStatusHistoryRepository history,
            TriageAssessmentRepository triageAssessments, TriageService triage, AuditService audit, SimpMessagingTemplate websocket,
            NotificationService notifications, IncidentIdempotencyKeyRepository idempotencyKeys) {
        this.incidents = incidents; this.emergencyTypes = emergencyTypes; this.history = history; this.triageAssessments = triageAssessments;
        this.triage = triage; this.audit = audit; this.websocket = websocket; this.notifications = notifications;
        this.idempotencyKeys = idempotencyKeys;
    }
    @Transactional
    public IncidentDtos.IncidentResponse createManual(UUID reporterId, IncidentDtos.CreateIncidentRequest request) {
        return createManual(reporterId, request, null);
    }
    @Transactional
    public IncidentDtos.IncidentResponse createManual(UUID reporterId, IncidentDtos.CreateIncidentRequest request, String idempotencyKey) {
        String key;
        try {
            key = IncidentRequestFingerprint.validatedKey(idempotencyKey);
        } catch (IllegalArgumentException invalid) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "INVALID_IDEMPOTENCY_KEY", invalid.getMessage());
        }
        String fingerprint = key == null ? null : IncidentRequestFingerprint.forRequest(request);
        if (key != null) {
            idempotencyKeys.lockForRequest(reporterId, key);
            java.util.Optional<IncidentIdempotencyKey> prior = idempotencyKeys.findByReporterIdAndRequestKey(reporterId, key);
            if (prior.isPresent()) {
                if (!prior.get().matchesFingerprint(fingerprint)) {
                    throw new ApiException(HttpStatus.CONFLICT, "IDEMPOTENCY_KEY_REUSED",
                            "This idempotency key was already used for a different emergency request");
                }
                return toResponse(find(prior.get().getIncidentId()));
            }
        }
        TriageInput triageInput = request.triage() == null ? new TriageInput(null, null, null, null, null, null) : request.triage();
        TriageService.TriageResult triageResult = triage.summarize(triageInput);
        EmergencyType type = emergencyTypes.findByCode(request.emergencyType().trim().toUpperCase())
                .orElseThrow(() -> new ApiException(HttpStatus.BAD_REQUEST, "UNKNOWN_EMERGENCY_TYPE", "Emergency type is not supported"));
        Incident incident = incidents.save(new Incident(reporterId, type, request.location().latitude(), request.location().longitude(), request.notes(), triageResult.priority()));
        if (key != null) idempotencyKeys.save(new IncidentIdempotencyKey(reporterId, key, fingerprint, incident.getId()));
        history.save(new IncidentStatusHistory(incident.getId(), null, IncidentStatus.NEW, reporterId, "Manual emergency created"));
        triageAssessments.save(new TriageAssessment(incident.getId(), triageInput, triageResult.summary()));
        transition(incident, IncidentStatus.SEARCHING, reporterId, "Starting responder search");
        notifications.create(reporterId, NotificationType.EMERGENCY_ALERT);
        audit.record(reporterId, "INCIDENT_CREATED", "INCIDENT", incident.getId());
        return toResponse(incident);
    }
    @Transactional(readOnly = true)
    public List<IncidentDtos.IncidentResponse> mine(UUID userId) { return incidents.findByReporterIdOrderByCreatedAtDesc(userId).stream().map(this::toResponse).toList(); }
    @Transactional(readOnly = true)
    public IncidentDtos.IncidentDetailResponse detail(UUID actorId, boolean canCoordinate, UUID incidentId) {
        Incident incident = find(incidentId);
        if (!canCoordinate && !incident.getReporterId().equals(actorId)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "ACCESS_DENIED", "You are not allowed to view this incident");
        }
        return new IncidentDtos.IncidentDetailResponse(toResponse(incident), history.findByIncidentIdOrderByCreatedAtAsc(incidentId).stream()
                .map(event -> new IncidentDtos.TimelineEvent(event.getToStatus().name(), event.getReason(), event.getCreatedAt())).toList());
    }
    @Transactional
    public IncidentDtos.IncidentResponse changeStatus(UUID actorId, boolean canCoordinate, UUID incidentId, IncidentDtos.ChangeStatusRequest request) {
        Incident incident = find(incidentId);
        boolean reporter = incident.getReporterId().equals(actorId);
        boolean ownerCancelling = reporter && request.status() == IncidentStatus.CANCELLED;
        if (!canCoordinate && !ownerCancelling) throw new ApiException(HttpStatus.FORBIDDEN, "ACCESS_DENIED", "You are not allowed to perform this action");
        if (ownerCancelling && !incident.getStatus().canBeCancelledByReporter()) {
            throw new ApiException(HttpStatus.CONFLICT, "INCIDENT_CANCELLATION_UNAVAILABLE",
                    "Only an authorized coordinator can cancel an incident after response coordination begins");
        }
        transition(incident, request.status(), actorId, request.reason());
        audit.record(actorId, "INCIDENT_STATUS_CHANGED", "INCIDENT", incidentId);
        return toResponse(incident);
    }
    @Transactional(readOnly = true)
    public Incident find(UUID id) { return incidents.findById(id).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "INCIDENT_NOT_FOUND", "Incident was not found")); }
    @Transactional
    public void assignResponder(Incident incident, UUID volunteerId) {
        if (incident.getStatus() != IncidentStatus.SEARCHING) {
            throw new ApiException(HttpStatus.CONFLICT, "INCIDENT_UNAVAILABLE", "This incident is no longer available for response");
        }
        transition(incident, IncidentStatus.RESPONDER_ASSIGNED, volunteerId, "Volunteer accepted emergency response");
        audit.record(volunteerId, "RESPONDER_ASSIGNED", "INCIDENT", incident.getId());
    }
    @Transactional
    public void assignEms(Incident incident, UUID emsUserId) {
        if (!incident.getStatus().allowedNext().contains(IncidentStatus.EMS_ASSIGNED)) {
            throw new ApiException(HttpStatus.CONFLICT, "INCIDENT_UNAVAILABLE", "This incident cannot be assigned to EMS at its current status");
        }
        transition(incident, IncidentStatus.EMS_ASSIGNED, emsUserId, "EMS coordination started");
        audit.record(emsUserId, "EMS_ASSIGNED", "INCIDENT", incident.getId());
    }
    private void transition(Incident incident, IncidentStatus next, UUID actorId, String reason) {
        if (!incident.getStatus().allowedNext().contains(next)) throw new ApiException(HttpStatus.CONFLICT, "INVALID_STATUS_TRANSITION", "This incident status transition is not allowed");
        IncidentStatus previous = incident.getStatus(); incident.moveTo(next); history.save(new IncidentStatusHistory(incident.getId(), previous, next, actorId, reason));
        websocket.convertAndSend("/topic/incidents/" + incident.getId(), toResponse(incident));
    }
    private IncidentDtos.IncidentResponse toResponse(Incident incident) {
        return new IncidentDtos.IncidentResponse(incident.getId().toString(), incident.getEmergencyType().getCode(), incident.getSource(), incident.getStatus().name(), incident.getPriority(), new IncidentDtos.Location(incident.getLatitude(), incident.getLongitude()), incident.getNotes(), incident.getCreatedAt());
    }
}
