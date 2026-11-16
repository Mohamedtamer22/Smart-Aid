package com.smartaid.platform.security;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.ReadListener;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletInputStream;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import jakarta.servlet.http.HttpServletResponse;
import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Locale;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/** Local development guard; production must use a shared, proxy-aware limiter. */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 1)
public class AuthRateLimitFilter extends OncePerRequestFilter {
    private static final int MAX_REQUESTS = 10;
    private static final long WINDOW_SECONDS = 60;
    private static final int MAX_AUTH_REQUEST_BYTES = 8 * 1024;
    private final ConcurrentHashMap<String, Window> windows = new ConcurrentHashMap<>();
    private final SecurityErrorWriter errors;
    private final ObjectMapper objectMapper;

    public AuthRateLimitFilter(SecurityErrorWriter errors, ObjectMapper objectMapper) {
        this.errors = errors;
        this.objectMapper = objectMapper;
    }

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain chain) throws ServletException, IOException {
        boolean guarded = "POST".equals(request.getMethod()) &&
                ("/api/auth/login".equals(request.getRequestURI()) ||
                 "/api/auth/register".equals(request.getRequestURI()) ||
                 "/api/auth/refresh".equals(request.getRequestURI()));
        HttpServletRequest requestForChain = request;
        if (guarded) {
            CachedAuthRequest cached;
            try {
                cached = new CachedAuthRequest(request);
            } catch (RequestTooLargeException tooLarge) {
                errors.write(request, response, 413, "REQUEST_TOO_LARGE", "Authentication request is too large");
                return;
            }
            String bucket = clientIp(request) + "|" + request.getRequestURI() + "|" + submittedEmail(cached.body());
            if (!windows.computeIfAbsent(bucket, ignored -> new Window()).allow()) {
                errors.write(request, response, 429, "RATE_LIMITED", "Too many authentication attempts; try again later");
                return;
            }
            requestForChain = cached;
        }
        chain.doFilter(requestForChain, response);
    }

    private String clientIp(HttpServletRequest request) {
        String xff = request.getHeader("X-Forwarded-For");
        if (xff != null && !xff.isBlank()) {
            return xff.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }

    private String submittedEmail(byte[] body) {
        try {
            JsonNode tree = objectMapper.readTree(body);
            JsonNode emailNode = tree.path("email");
            if (emailNode.isTextual() && !emailNode.asText().isBlank()) {
                return emailNode.asText().trim().toLowerCase(Locale.ROOT);
            }
            JsonNode refreshNode = tree.path("refreshToken");
            if (refreshNode.isTextual() && !refreshNode.asText().isBlank()) {
                String token = refreshNode.asText();
                return "refresh:" + (token.length() > 8 ? token.substring(0, 8) : token);
            }
            return "anonymous";
        } catch (IOException malformed) {
            return "anonymous";
        }
    }

    private static final class Window {
        private Instant started = Instant.now(); private int count;
        synchronized boolean allow() {
            if (started.plusSeconds(WINDOW_SECONDS).isBefore(Instant.now())) { started = Instant.now(); count = 0; }
            return ++count <= MAX_REQUESTS;
        }
    }

    private static final class CachedAuthRequest extends HttpServletRequestWrapper {
        private final byte[] body;

        CachedAuthRequest(HttpServletRequest request) throws IOException {
            super(request);
            if (request.getContentLengthLong() > MAX_AUTH_REQUEST_BYTES) throw new RequestTooLargeException();
            body = request.getInputStream().readNBytes(MAX_AUTH_REQUEST_BYTES + 1);
            if (body.length > MAX_AUTH_REQUEST_BYTES) throw new RequestTooLargeException();
        }

        byte[] body() { return body; }

        @Override public ServletInputStream getInputStream() {
            ByteArrayInputStream source = new ByteArrayInputStream(body);
            return new ServletInputStream() {
                @Override public int read() { return source.read(); }
                @Override public boolean isFinished() { return source.available() == 0; }
                @Override public boolean isReady() { return true; }
                @Override public void setReadListener(ReadListener listener) {
                    throw new UnsupportedOperationException("Asynchronous request reads are not supported");
                }
            };
        }

        @Override public BufferedReader getReader() {
            return new BufferedReader(new InputStreamReader(getInputStream(), StandardCharsets.UTF_8));
        }

        @Override public int getContentLength() { return body.length; }
        @Override public long getContentLengthLong() { return body.length; }
    }

    private static final class RequestTooLargeException extends RuntimeException { }
}
