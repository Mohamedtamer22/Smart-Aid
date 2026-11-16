package com.smartaid.platform.notification;

import java.util.List;
import java.util.UUID;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {
    private final NotificationService notifications;
    public NotificationController(NotificationService notifications) { this.notifications = notifications; }
    @GetMapping List<NotificationDtos.NotificationResponse> list(Authentication auth) { return notifications.list(userId(auth)); }
    @PatchMapping("/{id}/read") NotificationDtos.NotificationResponse markRead(@PathVariable UUID id, Authentication auth) { return notifications.markRead(userId(auth), id); }
    private UUID userId(Authentication auth) { return (UUID) auth.getPrincipal(); }
}
