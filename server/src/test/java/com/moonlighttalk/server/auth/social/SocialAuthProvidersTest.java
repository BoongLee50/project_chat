package com.moonlighttalk.server.auth.social;

import com.sun.net.httpserver.HttpServer;
import io.jsonwebtoken.Jwts;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.interfaces.RSAPublicKey;
import java.time.Instant;
import java.util.Base64;
import java.util.Date;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * 소셜 토큰 검사 — 진짜 키 없이 **가짜 공급자 서버**(JDK 내장 HttpServer)를 띄워 검사 규칙만 본다(2026-11-15).
 *
 * <ul>
 *   <li>애플: 서명·iss·aud·exp — 우리가 만든 RSA 키로 서명하고 그 공개키를 JWKS로 내준다</li>
 *   <li>카카오: 🚨 <b>다른 앱의 토큰</b>(app_id 불일치)을 거절하는가 — 예전엔 통과했다</li>
 *   <li>구글: 클라이언트 ID가 <b>여럿</b>일 때 어느 것이든 받는가 · iss가 구글이 아니면 거절</li>
 * </ul>
 */
class SocialAuthProvidersTest {

    private HttpServer server;
    private final AtomicReference<String> response = new AtomicReference<>("{}");
    private String base;

    @BeforeEach
    void startFakeProvider() throws Exception {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/", ex -> {
            byte[] b = response.get().getBytes(StandardCharsets.UTF_8);
            ex.getResponseHeaders().add("Content-Type", "application/json");
            ex.sendResponseHeaders(200, b.length);
            try (OutputStream os = ex.getResponseBody()) {
                os.write(b);
            }
        });
        server.start();
        base = "http://127.0.0.1:" + server.getAddress().getPort() + "/";
    }

    @AfterEach
    void stop() {
        server.stop(0);
    }

    // ── 애플 ──────────────────────────────────────────────

    private static final String BUNDLE = "com.example.dalbittalk";

    private KeyPair appleKeys() throws Exception {
        KeyPairGenerator g = KeyPairGenerator.getInstance("RSA");
        g.initialize(2048);
        KeyPair kp = g.generateKeyPair();
        RSAPublicKey pub = (RSAPublicKey) kp.getPublic();
        Base64.Encoder enc = Base64.getUrlEncoder().withoutPadding();
        response.set("{\"keys\":[{\"kty\":\"RSA\",\"kid\":\"k1\",\"alg\":\"RS256\",\"use\":\"sig\","
                + "\"n\":\"" + enc.encodeToString(unsigned(pub.getModulus().toByteArray())) + "\","
                + "\"e\":\"" + enc.encodeToString(unsigned(pub.getPublicExponent().toByteArray())) + "\"}]}");
        return kp;
    }

    private static byte[] unsigned(byte[] b) {
        return b.length > 1 && b[0] == 0 ? java.util.Arrays.copyOfRange(b, 1, b.length) : b;
    }

    private AppleAuthProvider apple() {
        SocialAuthProperties p = new SocialAuthProperties();
        p.getApple().setClientId(BUNDLE);
        p.getApple().setClientIds(List.of("com.example.dalbittalk.web"));
        p.getApple().setJwksUrl(base + "auth/keys");
        return new AppleAuthProvider(p);
    }

    private String appleToken(KeyPair kp, String kid, String iss, String aud, Instant exp) {
        return Jwts.builder()
                .header().keyId(kid).and()
                .issuer(iss).audience().add(aud).and()
                .subject("001234.apple-user")
                .issuedAt(Date.from(Instant.now().minusSeconds(10)))
                .expiration(Date.from(exp))
                .signWith(kp.getPrivate(), Jwts.SIG.RS256)
                .compact();
    }

    @Test
    void apple_validToken_givesSub() throws Exception {
        KeyPair kp = appleKeys();
        String t = appleToken(kp, "k1", AppleAuthProvider.ISSUER, BUNDLE, Instant.now().plusSeconds(600));
        assertThat(apple().verify(t).providerUid()).isEqualTo("001234.apple-user");
    }

    @Test
    void apple_servicesIdAudience_alsoAccepted() throws Exception {
        KeyPair kp = appleKeys();
        String t = appleToken(kp, "k1", AppleAuthProvider.ISSUER, "com.example.dalbittalk.web",
                Instant.now().plusSeconds(600));
        assertThat(apple().verify(t).providerUid()).isEqualTo("001234.apple-user");
    }

    @Test
    void apple_otherAppAudience_rejected() throws Exception {
        KeyPair kp = appleKeys();
        String t = appleToken(kp, "k1", AppleAuthProvider.ISSUER, "com.someone.else",
                Instant.now().plusSeconds(600));
        assertThatThrownBy(() -> apple().verify(t)).hasMessageContaining("aud");
    }

    @Test
    void apple_wrongIssuer_rejected() throws Exception {
        KeyPair kp = appleKeys();
        String t = appleToken(kp, "k1", "https://evil.example", BUNDLE, Instant.now().plusSeconds(600));
        assertThatThrownBy(() -> apple().verify(t)).isInstanceOf(RuntimeException.class);
    }

    @Test
    void apple_expired_rejected() throws Exception {
        KeyPair kp = appleKeys();
        String t = appleToken(kp, "k1", AppleAuthProvider.ISSUER, BUNDLE, Instant.now().minusSeconds(600));
        assertThatThrownBy(() -> apple().verify(t)).isInstanceOf(RuntimeException.class);
    }

    @Test
    void apple_signedByOtherKey_rejected() throws Exception {
        appleKeys();                       // JWKS에는 이 키
        KeyPair attacker = KeyPairGenerator.getInstance("RSA").generateKeyPair();
        String t = appleToken(attacker, "k1", AppleAuthProvider.ISSUER, BUNDLE, Instant.now().plusSeconds(600));
        assertThatThrownBy(() -> apple().verify(t)).isInstanceOf(RuntimeException.class);
    }

    @Test
    void apple_enabledWithoutClientId_refusesToStart() {
        SocialAuthProperties p = new SocialAuthProperties();
        assertThatThrownBy(() -> new AppleAuthProvider(p)).hasMessageContaining("APPLE_CLIENT_ID");
    }

    // ── 카카오 ────────────────────────────────────────────

    private KakaoAuthProvider kakao(String appId) {
        SocialAuthProperties p = new SocialAuthProperties();
        p.getKakao().setAppId(appId);
        p.getKakao().setVerifyUrl(base + "v1/user/access_token_info");
        return new KakaoAuthProvider(p);
    }

    @Test
    void kakao_ourApp_givesId() {
        response.set("{\"id\":4242,\"expires_in\":3600,\"app_id\":1111}");
        assertThat(kakao("1111").verify("tok").providerUid()).isEqualTo("4242");
    }

    @Test
    void kakao_otherAppsToken_rejected() {
        response.set("{\"id\":4242,\"expires_in\":3600,\"app_id\":9999}");
        assertThatThrownBy(() -> kakao("1111").verify("tok")).hasMessageContaining("다른 앱");
    }

    @Test
    void kakao_enabledWithoutAppId_refusesToStart() {
        assertThatThrownBy(() -> kakao(" ")).hasMessageContaining("KAKAO_APP_ID");
    }

    // ── 구글 ──────────────────────────────────────────────

    private GoogleAuthProvider google() {
        SocialAuthProperties p = new SocialAuthProperties();
        p.getGoogle().setClientId("web.apps.googleusercontent.com");
        p.getGoogle().setClientIds(List.of("android.apps.googleusercontent.com", "ios.apps.googleusercontent.com"));
        p.getGoogle().setVerifyUrl(base + "tokeninfo");
        return new GoogleAuthProvider(p);
    }

    @Test
    void google_anyOfOurClientIds_accepted() {
        response.set("{\"aud\":\"ios.apps.googleusercontent.com\",\"iss\":\"https://accounts.google.com\",\"sub\":\"g-1\"}");
        assertThat(google().verify("tok").providerUid()).isEqualTo("g-1");
    }

    @Test
    void google_otherClientId_rejected() {
        response.set("{\"aud\":\"someone.apps.googleusercontent.com\",\"iss\":\"accounts.google.com\",\"sub\":\"g-1\"}");
        assertThatThrownBy(() -> google().verify("tok")).hasMessageContaining("client-id");
    }

    @Test
    void google_wrongIssuer_rejected() {
        response.set("{\"aud\":\"web.apps.googleusercontent.com\",\"iss\":\"evil.example\",\"sub\":\"g-1\"}");
        assertThatThrownBy(() -> google().verify("tok")).hasMessageContaining("iss");
    }
}
