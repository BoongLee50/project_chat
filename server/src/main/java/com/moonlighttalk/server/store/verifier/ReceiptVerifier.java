package com.moonlighttalk.server.store.verifier;

/**
 * 인앱결제 영수증 검증. <b>클라가 "샀다"고 말하는 것을 믿지 않는다</b>(01 §1.8).
 *
 * <p>실제 구현은 Google Play Developer API / App Store Server API를 직접 호출해야 하며
 * 스토어 개발자 계정·키가 필요하다. 계정이 없는 지금은 {@link MockReceiptVerifier}가
 * local 프로필에서만 자리를 대신한다(소셜 로그인의 MockAuthProvider와 같은 방식).
 */
public interface ReceiptVerifier {

    /** 이 검증기가 담당하는 플랫폼(GOOGLE / APPLE). */
    String platform();

    /**
     * 영수증이 유효하고 productId와 일치하면 true.
     * 네트워크·서명 오류 등은 예외로 던져 호출부가 실패 응답을 주도록 한다.
     */
    boolean verify(String productId, String purchaseToken);
}
