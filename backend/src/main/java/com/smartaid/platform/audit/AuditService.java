package com.smartaid.platform.audit;

import java.util.UUID;
import org.slf4j.MDC;
import org.springframework.stereotype.Service;

@Service
public class AuditService {
    private final AuditLogRepository logs;
    public AuditService(AuditLogRepository logs) { this.logs = logs; }
    public void record(UUID actorId, String action, String entityType, UUID entityId) {
        logs.save(new AuditLog(actorId, action, entityType, entityId, MDC.get("traceId")));
    }
    public void record(UUID actorId, String action, String entityType, UUID entityId, java.util.Map<String, ?> metadata) {
        logs.save(new AuditLog(actorId, action, entityType, entityId, MDC.get("traceId")));
    }
}
