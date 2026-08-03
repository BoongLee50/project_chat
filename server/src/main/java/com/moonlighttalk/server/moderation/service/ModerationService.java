package com.moonlighttalk.server.moderation.service;

import com.moonlighttalk.server.auth.mapper.UserMapper;
import com.moonlighttalk.server.chat.entity.ChatRoom;
import com.moonlighttalk.server.chat.mapper.ChatMapper;
import com.moonlighttalk.server.chat.socket.Opcodes;
import com.moonlighttalk.server.chat.socket.Packet;
import com.moonlighttalk.server.chat.socket.SocketRegistry;
import com.moonlighttalk.server.common.exception.ApiException;
import com.moonlighttalk.server.common.response.ErrorCode;
import com.moonlighttalk.server.friend.entity.Friendship;
import com.moonlighttalk.server.friend.mapper.FriendMapper;
import com.moonlighttalk.server.moderation.mapper.ModerationMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

/**
 * 신고 / 차단. (기획서 화면 16·17, 01 문서 §1.7)
 *
 * <p><b>정책</b>(02 문서 §1.6): 신고·차단이 발생하면 <b>친구 관계를 즉시 끊고 대화방을 종료</b>한다.
 * 상대가 내 프로필을 못 보게 되는 것은 피드 조회 쪽에서 {@code existsBlockOrReport}로 이미 걸러진다.
 *
 * <p>신고와 차단은 기록만 다르고 <b>부수효과가 같다</b> — 신고했는데 대화가 계속 이어지면
 * 신고한 의미가 없기 때문이다.
 */
@Service
public class ModerationService {

    private static final Logger log = LoggerFactory.getLogger(ModerationService.class);

    private final ModerationMapper moderationMapper;
    private final FriendMapper friendMapper;
    private final ChatMapper chatMapper;
    private final UserMapper userMapper;
    private final SocketRegistry socketRegistry;

    public ModerationService(ModerationMapper moderationMapper,
                              FriendMapper friendMapper,
                              ChatMapper chatMapper,
                              UserMapper userMapper,
                              SocketRegistry socketRegistry) {
        this.moderationMapper = moderationMapper;
        this.friendMapper = friendMapper;
        this.chatMapper = chatMapper;
        this.userMapper = userMapper;
        this.socketRegistry = socketRegistry;
    }

    /** 신고 — 사유를 남기고 관계를 정리한다. 상대에게는 신고 사실을 알리지 않는다. */
    @Transactional
    public void report(String userId, String targetUserId, String reason, String detail) {
        requireOther(userId, targetUserId);

        String stored = (detail == null || detail.isBlank()) ? reason : reason + ": " + detail;
        moderationMapper.insertReport(UUID.randomUUID().toString(), userId, targetUserId, stored);
        log.info("신고 접수 reporter={} target={} reason={}", userId, targetUserId, reason);

        severTies(userId, targetUserId);
    }

    /** 차단 — 이미 차단한 상대여도 성공으로 처리하고 관계 정리만 다시 보장한다. */
    @Transactional
    public void block(String userId, String targetUserId) {
        requireOther(userId, targetUserId);

        moderationMapper.insertBlock(UUID.randomUUID().toString(), userId, targetUserId);
        severTies(userId, targetUserId);
    }

    // ── 내부 ────────────────────────────────────────────────

    /**
     * 두 사람 사이의 친구 관계와 살아있는 대화방을 끊는다.
     * 상대 화면이 즉시 따라오도록 소켓으로도 알린다.
     */
    private void severTies(String userId, String targetUserId) {
        String pairKey = pairKey(userId, targetUserId);

        Friendship friendship = friendMapper.selectByPairKey(pairKey);
        if (friendship != null) {
            friendMapper.delete(friendship.getId());
            socketRegistry.sendTo(targetUserId, Packet.of(Opcodes.FRIEND_STATE, Map.of(
                    "friendshipId", friendship.getId(), "state", "removed")));
        }

        // 친구 방이든 매칭 방이든 살아 있으면 닫는다.
        ChatRoom room = chatMapper.selectActiveRoomByPairKey(pairKey);
        if (room != null) {
            chatMapper.endRoom(room.getId(), LocalDateTime.now());
            Packet packet = Packet.of(Opcodes.ROOM_STATE, Map.of(
                    "roomId", room.getId(), "state", "ended"));
            socketRegistry.sendTo(room.getUserA(), packet);
            socketRegistry.sendTo(room.getUserB(), packet);
        }
    }

    private void requireOther(String userId, String targetUserId) {
        if (userId.equals(targetUserId)) {
            throw new ApiException(ErrorCode.MODERATION_SELF, HttpStatus.BAD_REQUEST,
                    "자기 자신은 대상이 될 수 없어요.");
        }
        if (userMapper.findById(targetUserId) == null) {
            throw new ApiException(ErrorCode.USER_NOT_FOUND, HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다.");
        }
    }

    /** 방향과 무관하게 같은 값이 나오도록 정렬해 잇는다(friend·chat와 같은 규칙). */
    private String pairKey(String a, String b) {
        return a.compareTo(b) <= 0 ? a + "_" + b : b + "_" + a;
    }
}
