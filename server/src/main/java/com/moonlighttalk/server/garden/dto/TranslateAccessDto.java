package com.moonlighttalk.server.garden.dto;

/**
 * 어떤 자리(댓글창·대화방)에서 <b>지금 번역이 되는가</b>(기획 4-2 · 5장).
 *
 * <p>화면은 이 답으로 두 가지를 정한다 — 번역을 켤지, 그리고 `[번역 | …]` 버튼에
 * 뭐라고 쓸지. 시안이 *"무료 적용 및 구매 전과 후에 따라 버튼 명칭 변경"* 이라 했다.
 *
 * @param granted   이 창/방에서 번역이 적용되는가
 * @param unlimited 패스·프라임이라 세지 않는가
 * @param remaining 남은 무료 자리(창 호출 횟수 또는 방 수). {@code unlimited}면 의미 없다
 * @param free      무료 전체 자리 수 — 안내 문구가 "5회 중"을 말할 수 있게
 * @param provider  번역 공급자 이름. {@code none}이면 <b>아직 실제로 번역되지 않는다</b>
 * @param expiresAt 패스 만료까지 남은 <b>분</b>. 시안이 "일, 시간, 분"으로 표시하라고 했다.
 *                  패스가 없거나 프라임이면 null
 */
public record TranslateAccessDto(
        boolean granted,
        boolean unlimited,
        int remaining,
        int free,
        String provider,
        Long expiresAt
) {
}
