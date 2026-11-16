package com.smartaid.platform.auth;

import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/users")
public class UserController {
    private final UserAccountRepository users;
    public UserController(UserAccountRepository users) { this.users = users; }

    @GetMapping("/me")
    AuthDtos.UserResponse me(Authentication authentication) {
        UserAccount user = users.findById((UUID) authentication.getPrincipal())
                .orElseThrow(() -> new com.smartaid.platform.exception.ApiException(HttpStatus.NOT_FOUND, "USER_NOT_FOUND", "User was not found"));
        return new AuthDtos.UserResponse(user.getId().toString(), user.getEmail(), user.getDisplayName(),
                user.getRoles().stream().map(Role::getCode).sorted().toList());
    }
}
