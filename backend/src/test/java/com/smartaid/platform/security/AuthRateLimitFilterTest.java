package com.smartaid.platform.security;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class AuthRateLimitFilterTest {
    @Test
    void limitsRepeatedAuthenticationAttemptsForTheSameSubmittedEmail() throws Exception {
        AuthRateLimitFilter filter = filter();

        for (int attempt = 0; attempt < 10; attempt++) {
            assertEquals(200, invoke(filter, "same.person@smartaid.local"));
        }
        assertEquals(429, invoke(filter, "same.person@smartaid.local"));
    }

    @Test
    void doesNotLockOutDifferentLocalAccountsSharingOneAddress() throws Exception {
        AuthRateLimitFilter filter = filter();

        for (int attempt = 0; attempt < 10; attempt++) {
            assertEquals(200, invoke(filter, "first.person@smartaid.local"));
        }
        assertEquals(200, invoke(filter, "second.person@smartaid.local"));
    }

    private int invoke(AuthRateLimitFilter filter, String email) throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/auth/login");
        request.setRemoteAddr("127.0.0.1");
        request.setContentType("application/json");
        request.setContent(("{\"email\":\"" + email + "\",\"password\":\"test-password\"}").getBytes());
        MockHttpServletResponse response = new MockHttpServletResponse();
        filter.doFilter(request, response, new MockFilterChain());
        return response.getStatus();
    }

    private AuthRateLimitFilter filter() {
        ObjectMapper mapper = new ObjectMapper().findAndRegisterModules();
        return new AuthRateLimitFilter(new SecurityErrorWriter(mapper), mapper);
    }
}
