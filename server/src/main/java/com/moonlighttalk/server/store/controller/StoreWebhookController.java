package com.moonlighttalk.server.store.controller;

import com.moonlighttalk.server.common.security.NoAuth;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/**
 * 스토어 웹훅 수신구(Google RTDN / App Store Server Notifications V2).
 * 갱신·취소·환불을 서버 상태에 반영하는 자리다. (01 §1.8 결제 흐름 ④)
 *
 * <p><b>지금은 수신만 하고 상태를 바꾸지 않는다.</b> 서명 검증에 필요한 스토어 키가 아직 없는데,
 * 검증 없이 본문을 믿고 구독을 켜거나 끄면 아무나 남의 구독을 조작할 수 있다.
 * 그래서 200으로 받아 로그만 남긴다(스토어가 재전송을 반복하지 않도록).
 *
 * <p>TODO(키 발급 후): Google은 Pub/Sub 메시지의 JWT 서명을,
 * Apple은 signedPayload(JWS)의 인증서 체인을 검증한 뒤 구독 상태를 동기화할 것.
 */
@RestController
public class StoreWebhookController {

    private static final Logger log = LoggerFactory.getLogger(StoreWebhookController.class);

    @NoAuth
    @PostMapping("/store/webhooks/google")
    public ResponseEntity<Void> google(@RequestBody(required = false) String body) {
        log.info("[웹훅] Google 수신(서명 검증 미구현 — 상태 반영 안 함) len={}",
                body == null ? 0 : body.length());
        return ResponseEntity.ok().build();
    }

    @NoAuth
    @PostMapping("/store/webhooks/apple")
    public ResponseEntity<Void> apple(@RequestBody(required = false) String body) {
        log.info("[웹훅] Apple 수신(서명 검증 미구현 — 상태 반영 안 함) len={}",
                body == null ? 0 : body.length());
        return ResponseEntity.ok().build();
    }
}
