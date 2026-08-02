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

    // ── 06시 종료 처리 ──

    /** 아직 살아있는 매칭 대화방. 친구(FRIEND) 방은 24시간 유지라 제외한다. */
    List<ChatRoom> selectActiveMatchRooms();

    int endAllActiveMatchRooms(@Param("endedAt") LocalDateTime endedAt);

    // ── 06시 지난 영업일 정리 ──

    /** 지난 영업일 사진의 스토리지 key(파일을 먼저 지우기 위해 필요). */
    List<String> selectPhotoKeysBefore(@Param("sessionDate") LocalDate sessionDate);

    int deletePhotosBefore(@Param("sessionDate") LocalDate sessionDate);

    int deleteStatsBefore(@Param("sessionDate") LocalDate sessionDate);

    int deleteSkipsBefore(@Param("sessionDate") LocalDate sessionDate);

    int deleteDailyUsageBefore(@Param("sessionDate") LocalDate sessionDate);

    /**
     * 지난 영업일 posts 정리. 단 <b>사용자별 가장 최근 1건은 남긴다</b> —
     * 하루 한 마디(one_liner)가 이 row에 있고, 다음 영업일 첫 진입 때 값을 이어받기 때문이다.
     */
    int deleteStalePosts(@Param("sessionDate") LocalDate sessionDate);
}
