package com.smartaid.platform.security;

import com.smartaid.platform.config.SecurityProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.List;
import java.util.UUID;
import javax.crypto.SecretKey;
import org.springframework.stereotype.Service;

@Service
public class JwtService {
    private final SecretKey key;
    private final SecurityProperties properties;

    public JwtService(SecurityProperties properties) {
        if (properties.jwtSecret() == null || properties.jwtSecret().getBytes(StandardCharsets.UTF_8).length < 32) {
            throw new IllegalStateException("JWT_SECRET must be configured with at least 32 bytes");
        }
        this.key = Keys.hmacShaKeyFor(properties.jwtSecret().getBytes(StandardCharsets.UTF_8));
        this.properties = properties;
    }

    public String createAccessToken(UUID userId, String email, List<String> roles) {
        Instant now = Instant.now();
        return Jwts.builder().subject(userId.toString()).claim("email", email).claim("roles", roles)
                .issuedAt(Date.from(now)).expiration(Date.from(now.plusSeconds(properties.accessTokenMinutes() * 60)))
                .signWith(key).compact();
    }

    public Claims parse(String token) {
        return Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload();
    }
}
