package com.moonlighttalk.server.chat.mapper;

import com.moonlighttalk.server.chat.entity.*;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;
import java.util.List;

@Mapper
public interface ChatMapper {

    // ── 대화 신청 ──
    void insertRequest(ChatRequestEntity request);

    ChatRequestEntity selectRequest(@Param("id") String id);

    void updateRequestStatus(@Param("id") String id, @Param("status") String status,
                              @Param("respondedAt") java.time.LocalDateTime respondedAt);

    /**
     * 거절당한 지 얼마 안 됐는가 — 거절 후 1일간 다시 신청할 수 없다(기획 §2-5).
     *
     * <p>{@code responded_at}이 NULL인 옛 행은 세지 않는다. 그때는 시각을 남기지 않았을 뿐이라
     * 지금 그 사람을 막을 근거가 되지 못한다.
     */
    boolean existsRecentRejection(@Param("fromUser") String fromUser,
                                   @Param("toUser") String toUser,
                                   @Param("since") java.time.LocalDateTime since);

    /** 내가 받은 신청(PENDING). */
    List<ChatRequestEntity> selectReceivedRequests(@Param("userId") String userId);

    /** 내가 보낸 신청 전체(대기/종료 표시용). */
    /** 같은 상대에게 이미 대기 중인 신청이 있는지. */
    boolean existsPendingRequest(@Param("fromUser") String fromUser, @Param("toUser") String toUser);

    /**
     * 두 사람 사이의 대기 중인 대화 신청 <b>한 건</b>. [포스트 정보] 화면이 신청 메시지와
     * 수락/거절에 쓸 id를 함께 봐야 해서 존재 여부(boolean)로는 모자란다.
     */
    ChatRequestEntity selectPendingRequestBetween(@Param("fromUser") String fromUser,
                                                   @Param("toUser") String toUser);

    // ── 대화방 ──
    void insertRoom(ChatRoom room);

    ChatRoom selectRoom(@Param("id") String id);

    /** 내 대화방 목록(상대 정보·마지막 메시지·미확인 수 포함). */
    List<ChatRoomSummary> selectMyRooms(@Param("userId") String userId);

    void endRoom(@Param("id") String id, @Param("endedAt") LocalDateTime endedAt);

    /** 두 사람 사이에 지금 살아있는 방(친구 수락 시 새로 만들지, 승격할지 판단용). */
    ChatRoom selectActiveRoomByPairKey(@Param("pairKey") String pairKey);

    void updateRoomType(@Param("id") String id, @Param("type") String type);

    /** 친구 삭제 시 상시 대화방 종료용. */
    ChatRoom selectActiveRoomByPairKeyAndType(@Param("pairKey") String pairKey,
                                               @Param("type") String type);

    // ── 메시지 ──
    void insertMessage(ChatMessage message);

    /** 커서(이전 메시지 id) 기준 과거로 페이징. cursor가 null이면 최신부터. */
    List<ChatMessage> selectMessages(@Param("roomId") String roomId,
                                      @Param("beforeCreatedAt") LocalDateTime beforeCreatedAt,
                                      @Param("limit") int limit);

    ChatMessage selectMessage(@Param("id") String id);

    /** 상대가 보낸 미확인 메시지를 읽음 처리. */
    void markRead(@Param("roomId") String roomId, @Param("readerId") String readerId,
                   @Param("readAt") LocalDateTime readAt);

    int countUnread(@Param("roomId") String roomId, @Param("readerId") String readerId);
}
