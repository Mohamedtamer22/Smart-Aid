package com.smartaid.platform.notification;

import java.time.Instant;
public final class NotificationDtos {
    private NotificationDtos() { }
    public record NotificationResponse(String id, String type, String title, String body, boolean read, Instant createdAt) { }
}
