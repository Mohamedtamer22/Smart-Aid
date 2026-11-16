package com.smartaid.platform.healthcare;

import java.util.Set;
import java.util.UUID;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;

final class AuthContextHelper {
    private AuthContextHelper() { }

    static UUID userId(Authentication auth) {
        return (UUID) auth.getPrincipal();
    }

    static boolean hasAnyRole(Authentication auth, String... roles) {
        Set<String> target = Set.of(roles);
        return auth.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .map(a -> a.startsWith("ROLE_") ? a.substring(5) : a)
                .anyMatch(target::contains);
    }
}
