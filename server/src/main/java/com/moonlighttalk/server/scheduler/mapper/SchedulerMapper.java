package com.moonlighttalk.server.scheduler.mapper;

import com.moonlighttalk.server.chat.entity.ChatRoom;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/** 배치가 쓰는 벌크 조회/삭제. (02 문서 §4) */
@Mapper
public interface SchedulerMapper {

    // ── 대화방 종료 ──

    /**
     * <b>비어 버린 대화방</b> — 마지막 메시지(없으면 방 생성)로부터 보관 기간이 지난 살아 있는 방.
     *
     * <p>🚨 "메시지 0건"으로 찾으면 **갓 만든 방까지 잡힌다**(둘 다 0건이라 구분이 안 된다).
     */
    List<ChatRoom> selectRoomsIdleSince(@Param("before") LocalDateTime before);

    /** 방 하나를 ENDED로 닫는다(`active_pair_key`를 비워 같은 상대와 새 방을 허용). */
    int endRoom(@Param("id") String id, @Param("endedAt") LocalDateTime endedAt);

    // ── 무응답 신청 만료 ──

    /**
     * 답하지 않은 채 기간이 지난 <b>대화 신청</b>을 EXPIRED로 바꾼다(기획 6-2, V24).
     *
     * <p>🚨 <b>REJECTED로 바꾸면 안 된다</b> — 거절에는 "1일간 재신청 금지"가 딸려 있어
     * 내가 답을 안 했을 뿐인데 <b>상대가 벌을 받는다</b>. 만료는 아무 일도 없었던 것에 가깝다.
     *
     * <p>행을 지우지 않는 이유: 목록 조회가 전부 {@code status = 'PENDING'}이라
     * 상태만 바꿔도 사라지고, 누가 언제 신청했는지는 남는다.
     */
    int expireChatRequestsBefore(@Param("before") LocalDateTime before);

    /**
     * 답하지 않은 채 기간이 지난 <b>친구 신청</b>을 지운다(같은 규칙).
     *
     * <p>이쪽만 <b>행을 지우는</b> 이유: {@code friendships.pair_key}가 UNIQUE라
     * 만료 행을 남기면 그 사람에게 <b>다시 신청할 수 없다</b>. 거절도 이미 행 삭제다.
     */
    int deleteFriendRequestsBefore(@Param("before") LocalDateTime before);

    // ── 지난 영업일 정리 ──

    /** 지난 영업일 사진의 스토리지 key(파일을 먼저 지우기 위해 필요). */
    List<String> selectPhotoKeysBefore(@Param("sessionDate") LocalDate sessionDate);

    int deletePhotosBefore(@Param("sessionDate") LocalDate sessionDate);

    /** 사진을 지운 뒤 떠 버린 대표 사진 참조를 비운다(V11 — main_photo_id에는 FK가 없다). */
    int clearMainPhotosBefore(@Param("sessionDate") LocalDate sessionDate);

    /** 15분 판정용 노출 기록(V12) 중 하루가 지난 것을 지운다. */
    int deleteExposuresBefore(@Param("before") java.time.LocalDateTime before);

    int deleteStatsBefore(@Param("sessionDate") LocalDate sessionDate);

    int deleteSkipsBefore(@Param("sessionDate") LocalDate sessionDate);

    int deleteDailyUsageBefore(@Param("sessionDate") LocalDate sessionDate);


    /**
     * 지난 영업일 posts 정리. 단 <b>사용자별 가장 최근 1건은 남긴다</b> —
     * 하루 한 마디(one_liner)가 이 row에 있고, 다음 영업일 첫 진입 때 값을 이어받기 때문이다.
     */
    int deleteStalePosts(@Param("sessionDate") LocalDate sessionDate);

    // ── 메시지 보관 만료(FIFO) ──

    /**
     * 보관 기간이 지난 메시지 id를 오래된 순으로 [limit]개까지.
     * <b>방 타입과 무관하게 같은 기간</b>이다(기획 답변 2026-09-06).
     *
     * <p>다중 테이블 DELETE는 MariaDB에서 LIMIT을 못 쓰므로 id를 먼저 뽑아 나눠 지운다.
     */
    List<String> selectExpiredMessageIds(@Param("before") LocalDateTime before,
                                          @Param("limit") int limit);

    int deleteMessagesByIds(@Param("ids") List<String> ids);
}
