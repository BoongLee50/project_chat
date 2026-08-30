package com.moonlighttalk.server.dailyquestion.dto;

/**
 * [타이틀] 화면(기획 8-1) — 오늘의 질문 + 참여 인원 + 남은 시간.
 *
 * @param remainingSeconds 다음 초기화(KST 18시)까지 남은 초.
 *                         <b>서버가 계산해 준다</b> — 기기 시계를 믿으면 사람마다 다른 시간이 보인다
 * @param answered         내가 오늘 이미 답했는가([내 한마디]가 열리는 조건)
 */
public record DailyQuestionTodayResponse(
        String questionId,
        String question,
        int participants,
        long remainingSeconds,
        boolean answered,
        String myAnswerId
) {
}
