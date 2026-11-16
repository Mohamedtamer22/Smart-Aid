package com.smartaid.platform.websocket;

import com.smartaid.platform.incident.IncidentRepository;
import com.smartaid.platform.security.JwtService;
import com.smartaid.platform.volunteer.EmergencyResponseRepository;
import io.jsonwebtoken.Claims;
import java.util.List;
import java.util.UUID;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;

@Component
public class WebSocketAuthorizationInterceptor implements ChannelInterceptor {
    private final JwtService jwt;
    private final IncidentRepository incidents;
    private final EmergencyResponseRepository responses;
    public WebSocketAuthorizationInterceptor(JwtService jwt, IncidentRepository incidents, EmergencyResponseRepository responses) {
        this.jwt = jwt; this.incidents = incidents; this.responses = responses;
    }
    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        // Retrieve the original accessor instead of wrapping the message. The
        // original carries Spring's user-change callback, which persists the
        // authenticated CONNECT principal for subsequent STOMP frames.
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        if (accessor == null) return message;
        if (StompCommand.CONNECT.equals(accessor.getCommand())) {
            authenticate(accessor);
        }
        if (StompCommand.SUBSCRIBE.equals(accessor.getCommand())) authorizeSubscription(accessor);
        return message;
    }
    private void authenticate(StompHeaderAccessor accessor) {
        String header = accessor.getFirstNativeHeader("Authorization");
        if (header == null || !header.startsWith("Bearer ")) throw new AccessDeniedException("Missing WebSocket access token");
        try {
            Claims claims = jwt.parse(header.substring(7));
            @SuppressWarnings("unchecked") List<String> roles = claims.get("roles", List.class);
            accessor.setUser(new UsernamePasswordAuthenticationToken(UUID.fromString(claims.getSubject()), null,
                    roles.stream().map(role -> new SimpleGrantedAuthority("ROLE_" + role)).toList()));
        } catch (RuntimeException invalid) { throw new AccessDeniedException("Invalid WebSocket access token"); }
    }
    private void authorizeSubscription(StompHeaderAccessor accessor) {
        if (!(accessor.getUser() instanceof UsernamePasswordAuthenticationToken user)) throw new AccessDeniedException("WebSocket authentication required");
        String destination = accessor.getDestination();
        if (destination == null || !destination.startsWith("/topic/incidents/")) throw new AccessDeniedException("Subscription is not allowed");
        try {
            UUID incidentId = UUID.fromString(destination.substring("/topic/incidents/".length()));
            boolean coordinator = user.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_EMS") || a.getAuthority().equals("ROLE_ADMIN"));
            UUID userId = (UUID) user.getPrincipal();
            boolean reporter = incidents.existsByIdAndReporterId(incidentId, userId);
            boolean assignedVolunteer = responses.existsByIncidentIdAndVolunteerId(incidentId, userId);
            if (!coordinator && !reporter && !assignedVolunteer) throw new AccessDeniedException("Incident access is not allowed");
        } catch (IllegalArgumentException invalid) { throw new AccessDeniedException("Invalid incident subscription"); }
    }
}
