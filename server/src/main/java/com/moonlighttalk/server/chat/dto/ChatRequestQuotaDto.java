package com.moonlighttalk.server.chat.dto;

/**
 * 대화 신청을 하기 <b>전에</b> 화면이 알아야 하는 것(기획 4-3 img09).
 *
 * <p>시안의 팝업은 버튼에 `대화 신청 (무료 2회)`라고 남은 횟수를 적고, 안내 상자에
 * *"처음 10회까지 무료 · 이후 5 루나 · Prime이면 무제한"* 을 보여 준다.
 * 이 값들이 없으면 화면은 <b>숫자를 지어내거나</b> 아무 말도 못 한다.
 *
 * <p>🚨 이것은 <b>안내</b>일 뿐 판정이 아니다. 실제 차감·차단은 신청할 때 서버가 다시 본다 —
 * 화면이 "무료 2회 남음"을 들고 있는 사이에 다른 기기에서 다 써 버릴 수 있다.
 *
 * @param freeRemaining 오늘 남은 무료 신청 횟수. {@code unlimited}면 의미 없다
 * @param freePerDay    하루 무료 횟수(안내 문구의 "처음 10회까지")
 * @param lunaCost      무료를 다 쓴 뒤 1건당 차감할 루나
 * @param maxLength     한마디 최대 글자 수 — 입력칸이 어디서 멈출지 정한다
 * @param unlimited     프라임·무제한 권리를 가지고 있는가
 */
public record ChatRequestQuotaDto(
        int freeRemaining,
        int freePerDay,
        int lunaCost,
        int maxLength,
        boolean unlimited
) {
}
