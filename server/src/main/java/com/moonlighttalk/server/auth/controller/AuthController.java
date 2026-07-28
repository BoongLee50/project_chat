package com.moonlighttalk.server.auth.controller;

import com.moonlighttalk.server.auth.dto.AuthResponse;
import com.moonlighttalk.server.auth.dto.RefreshRequest;
import com.moonlighttalk.server.auth.dto.SocialLoginRequest;
import com.moonlighttalk.server.auth.dto.TokenPairResponse;
import com.moonlighttalk.server.auth.service.AuthService;
import com.moonlighttalk.server.common.security.NoAuth;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/** 01 문서 §1.1 인증/게이트 */
@RestController
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @NoAuth
    @PostMapping("/auth/social")
    public AuthResponse socialLogin(@Valid @RequestBody SocialLoginRequest request) {
        return authService.socialLogin(request.provider(), request.providerToken());
    }

    @NoAuth
    @PostMapping("/auth/refresh")
    public TokenPairResponse refresh(@Valid @RequestBody RefreshRequest request) {
        return authService.refresh(request.refreshToken());
    }
}
