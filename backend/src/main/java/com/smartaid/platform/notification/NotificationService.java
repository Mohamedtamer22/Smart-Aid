package com.smartaid.platform.notification;

import com.smartaid.platform.exception.ApiException;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class NotificationService {
    private final NotificationRepository notifications;
    public NotificationService(NotificationRepository notifications) { this.notifications = notifications; }
    @Transactional
    public void create(UUID userId, NotificationType type) { notifications.save(new NotificationRecord(userId, type)); }
    @Transactional
    public void create(UUID userId, NotificationType type, String title, String body) { notifications.save(new NotificationRecord(userId, type, title, body)); }
    @Transactional
    public void broadcast(NotificationType type, String title, String body) {
        // Find users to notify (or insert broadcast record)
        try {
            notifications.save(new NotificationRecord(UUID.fromString("00000000-0000-0000-0000-000000000000"), type, title, body));
        } catch (Exception ignored) {
            // fallback
        }
    }
    @Transactional(readOnly = true)
    public List<NotificationDtos.NotificationResponse> list(UUID userId) { return notifications.findTop100ByUserIdOrderByCreatedAtDesc(userId).stream().map(this::toResponse).toList(); }
    @Transactional
    public NotificationDtos.NotificationResponse markRead(UUID userId, UUID id) {
        NotificationRecord notification = notifications.findByIdAndUserId(id, userId).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "NOTIFICATION_NOT_FOUND", "Notification was not found"));
        notification.markRead(); return toResponse(notification);
    }
    private NotificationDtos.NotificationResponse toResponse(NotificationRecord notification) {
        return new NotificationDtos.NotificationResponse(
            notification.getId().toString(),
            notification.getType().name(),
            notification.getTitle(),
            notification.getBody(),
            notification.getReadAt() != null,
            notification.getCreatedAt()
        );
    }
}
