package com.moonlighttalk.server.auth.controller;

import com.moonlighttalk.server.auth.dto.GateResponse;
import com.moonlighttalk.server.auth.service.GateService;
import com.moonlighttalk.server.common.security.NoAuth;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/** 01 문서 §1.1 — 로그인 전에도 조회 가능해야 하므로 인증 제외. */
@RestController
public class SystemController {

    private final GateService gateService;

    public SystemController(GateService gateService) {
        this.gateService = gateService;
    }

    @NoAuth
    @GetMapping("/system/gate")
    public GateResponse gate() {
        return gateService.currentGate();
    }
}
