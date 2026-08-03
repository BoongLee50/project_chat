package com.moonlighttalk.server.garden.dto;

/// 번역 결과 + 남은 무료 쿼터.
///
/// 쿼터를 함께 돌려주는 이유는 클라가 **다음 번역 전에** 패스를 권할 수 있어야 해서다.
/// 다 쓴 뒤에 막고 안내하면 이미 늦다.
///
/// [unlimited]면 [remaining]은 의미가 없다(패스·프라임 보유자).
public record TranslateResponse(
        String text,
        String provider,
        boolean unlimited,
        int remaining
) {
    /// 패스·프라임 보유자 — 쿼터를 세지 않는다.
    public static TranslateResponse unlimited(String text, String provider) {
        return new TranslateResponse(text, provider, true, 0);
    }

    public static TranslateResponse free(String text, String provider, int remaining) {
        return new TranslateResponse(text, provider, false, remaining);
    }
}
