package com.moonlighttalk.server.chat.service;

import com.moonlighttalk.server.auth.entity.User;
import com.moonlighttalk.server.auth.mapper.UserMapper;
import com.moonlighttalk.server.auth.service.GateService;
import com.moonlighttalk.server.chat.dto.*;
import com.moonlighttalk.server.chat.entity.*;
import com.moonlighttalk.server.chat.mapper.ChatMapper;
import com.moonlighttalk.server.chat.socket.Opcodes;
import com.moonlighttalk.server.chat.socket.Packet;
import com.moonlighttalk.server.chat.socket.SocketRegistry;
import com.moonlighttalk.server.common.exception.ApiException;
import com.moonlighttalk.server.common.response.ErrorCode;
import com.moonlighttalk.server.common.storage.FileStorageService;
import com.moonlighttalk.server.garden.mapper.GardenMapper;
import com.moonlighttalk.server.luna.service.LunaService;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * 대화 신청 / 대화방 / 메시지 (기획서 4-3·5장, 01 문서 §1.5~1.6, §2).
 *
 * <p>대화 신청은 <b>하이브리드</b>: 생성은 REST(루나 차감 트랜잭션), 상대에게 도착 알림은 소켓.
 * 하루 무료 2회 후 건당 루나 5 차감(프리미엄은 무제한·무차감).
 */
@Service
public class ChatService {

    private static final int LUNA_COST = 5;
    private static final int FREE_REQUESTS_PER_DAY = 2;
    private static final int MESSAGE_PAGE_SIZE = 30;
    private static final String USAGE_CHAT_REQUEST = "CHAT_REQUEST";

    private final ChatMapper chatMapper;
    private final UserMapper userMapper;
    private final GardenMapper gardenMapper;
    private final LunaService lunaService;
    private final GateService gateService;
    private final SocketRegistry socketRegistry;
    private final FileStorageService fileStorageService;

    public ChatService(ChatMapper chatMapper,
                        UserMapper userMapper,
                        GardenMapper gardenMapper,
                        LunaService lunaService,
                        GateService gateService,
                        SocketRegistry socketRegistry,
                        FileStorageService fileStorageService) {
        this.chatMapper = chatMapper;
        this.userMapper = userMapper;
        this.gardenMapper = gardenMapper;
        this.lunaService = lunaService;
        this.gateService = gateService;
        this.socketRegistry = socketRegistry;
        this.fileStorageService = fileStorageService;
    }

    // ── 대화 신청 ───────────────────────────────────────────

    /** 대화 신청 생성 — 무료 2회 소진 후 루나 5 차감. 성공 시 상대에게 소켓 알림. */
    @Transactional
    public void createRequest(String userId, String targetUserId, String message) {
        if (userId.equals(targetUserId)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.BAD_REQUEST,
                    "자신에게는 대화를 신청할 수 없어요.");
        }
        if (gardenMapper.existsBlockOrReport(userId, targetUserId)) {
            throw new ApiException(ErrorCode.TARGET_BLOCKED_OR_REPORTED, HttpStatus.CONFLICT,
                    "현재 이 사용자에게 대화 신청을 보낼 수 없어요.");
        }
        if (chatMapper.existsPendingRequest(userId, targetUserId)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.CONFLICT,
                    "이미 대화를 신청했어요. 상대의 응답을 기다려 주세요.");
        }

        User me = getUserOrThrow(userId);
        boolean premium = Boolean.TRUE.equals(me.getPremium());
        int cost = 0;

        if (!premium) {
            int used = lunaService.dailyUsed(userId, gateService.currentSessionDate(), USAGE_CHAT_REQUEST);
            if (used >= FREE_REQUESTS_PER_DAY) {
                cost = LUNA_COST;
            }
        }

        String requestId = UUID.randomUUID().toString();
        if (cost > 0) {
            lunaService.deduct(userId, cost, USAGE_CHAT_REQUEST, requestId);
        }
        if (!premium) {
            lunaService.useDaily(userId, gateService.currentSessionDate(), USAGE_CHAT_REQUEST);
        }

        ChatRequestEntity request = new ChatRequestEntity();
        request.setId(requestId);
        request.setFromUser(userId);
        request.setToUser(targetUserId);
        request.setMessage(message);
        request.setStatus("PENDING");
        request.setLunaCost(cost);
        chatMapper.insertRequest(request);

        // 전환율(Engage) 반영 — 대화 신청도 분자에 포함(기획서 4-1)
        gardenMapper.incrementStat(targetUserId, gateService.currentSessionDate(), "requests", 1);

        socketRegistry.sendTo(targetUserId, Packet.of(Opcodes.CHAT_REQ_INCOMING, Map.of(
                "requestId", requestId,
                "fromUserId", userId,
                "fromNickname", me.getNickname() == null ? "" : me.getNickname(),
                "message", message
        )));
    }

    /** 신청 수락 → 대화방 생성. 양쪽에 방 상태를 알린다. */
    @Transactional
    public String acceptRequest(String userId, String requestId) {
        ChatRequestEntity request = requireRequest(requestId);
        if (!request.getToUser().equals(userId)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.FORBIDDEN,
                    "내가 받은 신청만 수락할 수 있어요.");
        }
        if (!"PENDING".equals(request.getStatus())) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.CONFLICT,
                    "이미 처리된 신청이에요.");
        }

        chatMapper.updateRequestStatus(requestId, "ACCEPTED");

        ChatRoom room = new ChatRoom();
        room.setId(UUID.randomUUID().toString());
        room.setUserA(request.getFromUser());
        room.setUserB(request.getToUser());
        room.setStatus("ACTIVE");
        room.setType("MATCH");
        room.setRequestId(requestId);
        try {
            chatMapper.insertRoom(room);
        } catch (DataIntegrityViolationException e) {
            // active_pair_key 유니크 위반 = 같은 상대와 이미 진행 중인 방이 있음(02 §1.5)
            throw new ApiException(ErrorCode.ROOM_ALREADY_ACTIVE, HttpStatus.CONFLICT,
                    "이미 진행 중인 대화가 있어요.");
        }

        notifyRoomState(room, "accepted");
        return room.getId();
    }

    @Transactional
    public void rejectRequest(String userId, String requestId) {
        ChatRequestEntity request = requireRequest(requestId);
        if (!request.getToUser().equals(userId)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.FORBIDDEN,
                    "내가 받은 신청만 거절할 수 있어요.");
        }
        chatMapper.updateRequestStatus(requestId, "REJECTED");

        socketRegistry.sendTo(request.getFromUser(), Packet.of(Opcodes.ROOM_STATE, Map.of(
                "requestId", requestId, "state", "rejected")));
    }

    public List<ChatRequestDto> receivedRequests(String userId) {
        return chatMapper.selectReceivedRequests(userId).stream().map(this::toRequestDto).toList();
    }

    public List<ChatRequestDto> sentRequests(String userId) {
        return chatMapper.selectSentRequests(userId).stream().map(this::toRequestDto).toList();
    }

    // ── 대화방 ─────────────────────────────────────────────

    public List<ChatRoomDto> myRooms(String userId) {
        return chatMapper.selectMyRooms(userId).stream()
                .map(s -> new ChatRoomDto(
                        s.getRoomId(),
                        s.getType(),
                        s.getPartnerId(),
                        s.getPartnerNickname(),
                        age(s.getPartnerBirthYear()),
                        s.getPartnerCountry(),
                        photoUrl(s.getPartnerPhotoKey()),
                        s.getLastMessage(),
                        s.getLastMessageAt(),
                        s.getUnreadCount()))
                .toList();
    }

    /** 대화방 나가기 — 방을 종료하고 상대에게 알린다. */
    @Transactional
    public void leaveRoom(String userId, String roomId) {
        ChatRoom room = requireMemberRoom(userId, roomId);
        chatMapper.endRoom(roomId, LocalDateTime.now());
        socketRegistry.sendTo(room.otherOf(userId), Packet.of(Opcodes.ROOM_STATE, Map.of(
                "roomId", roomId, "state", "ended")));
    }

    /** 메시지 히스토리(과거 방향 페이징). 오래된 순으로 정렬해 반환한다. */
    public MessagePageDto messages(String userId, String roomId, String cursor) {
        requireMemberRoom(userId, roomId);

        LocalDateTime before = null;
        if (cursor != null && !cursor.isBlank()) {
            ChatMessage anchor = chatMapper.selectMessage(cursor);
            if (anchor != null) before = anchor.getCreatedAt();
        }

        List<ChatMessage> rows = chatMapper.selectMessages(roomId, before, MESSAGE_PAGE_SIZE);
        List<ChatMessageDto> items = new ArrayList<>(rows.stream().map(this::toMessageDto).toList());
        java.util.Collections.reverse(items); // 오래된 → 최신

        String nextCursor = rows.size() < MESSAGE_PAGE_SIZE ? null : rows.get(rows.size() - 1).getId();
        return new MessagePageDto(items, nextCursor);
    }

    // ── 소켓에서 호출 ───────────────────────────────────────

    /** 메시지 저장 후 양쪽에 전달. 반환값은 발신자에게 줄 ACK 정보. */
    @Transactional
    public ChatMessageDto sendMessage(String userId, String roomId, String body) {
        ChatRoom room = requireMemberRoom(userId, roomId);

        ChatMessage message = new ChatMessage();
        message.setId(UUID.randomUUID().toString());
        message.setRoomId(roomId);
        message.setSenderId(userId);
        message.setBody(body);
        chatMapper.insertMessage(message);

        ChatMessage saved = chatMapper.selectMessage(message.getId());
        ChatMessageDto dto = toMessageDto(saved);

        String partnerId = room.otherOf(userId);
        socketRegistry.sendTo(partnerId, Packet.of(Opcodes.CHAT_RECV, toMap(dto)));
        socketRegistry.sendTo(partnerId, Packet.of(Opcodes.UNREAD_COUNT, Map.of(
                "roomId", roomId,
                "count", chatMapper.countUnread(roomId, partnerId))));
        return dto;
    }

    /** 읽음 처리 후 상대에게 영수증 전송. */
    @Transactional
    public void markRead(String userId, String roomId) {
        ChatRoom room = requireMemberRoom(userId, roomId);
        chatMapper.markRead(roomId, userId, LocalDateTime.now());
        socketRegistry.sendTo(room.otherOf(userId), Packet.of(Opcodes.CHAT_READ_RECEIPT, Map.of(
                "roomId", roomId, "readerId", userId)));
    }

    // ── 내부 ────────────────────────────────────────────────

    private void notifyRoomState(ChatRoom room, String state) {
        Packet packet = Packet.of(Opcodes.ROOM_STATE, Map.of(
                "roomId", room.getId(), "state", state));
        socketRegistry.sendTo(room.getUserA(), packet);
        socketRegistry.sendTo(room.getUserB(), packet);
    }

    private ChatRoom requireMemberRoom(String userId, String roomId) {
        ChatRoom room = chatMapper.selectRoom(roomId);
        if (room == null) {
            throw new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "대화방을 찾을 수 없어요.");
        }
        if (!room.hasMember(userId)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.FORBIDDEN,
                    "참여 중인 대화방이 아니에요.");
        }
        if ("ENDED".equals(room.getStatus())) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.CONFLICT, "종료된 대화방이에요.");
        }
        return room;
    }

    private ChatRequestEntity requireRequest(String requestId) {
        ChatRequestEntity request = chatMapper.selectRequest(requestId);
        if (request == null) {
            throw new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "신청을 찾을 수 없어요.");
        }
        return request;
    }

    private User getUserOrThrow(String userId) {
        User user = userMapper.findById(userId);
        if (user == null) {
            throw new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다.");
        }
        return user;
    }

    private ChatRequestDto toRequestDto(ChatRequestEntity r) {
        return new ChatRequestDto(
                r.getId(), r.getFromUser(), r.getToUser(), r.getMessage(), r.getStatus(),
                r.getPartnerNickname(), age(r.getPartnerBirthYear()), r.getPartnerCountry(),
                photoUrl(r.getPartnerPhotoKey()), r.getCreatedAt());
    }

    private ChatMessageDto toMessageDto(ChatMessage m) {
        return new ChatMessageDto(m.getId(), m.getRoomId(), m.getSenderId(), m.getBody(),
                m.getCreatedAt(), m.getReadAt() != null);
    }

    private Map<String, Object> toMap(ChatMessageDto dto) {
        Map<String, Object> map = new HashMap<>();
        map.put("messageId", dto.id());
        map.put("roomId", dto.roomId());
        map.put("senderId", dto.senderId());
        map.put("body", dto.body());
        map.put("createdAt", dto.createdAt().toString());
        return map;
    }

    private Integer age(Integer birthYear) {
        return birthYear == null ? null : gateService.nowKst().getYear() - birthYear;
    }

    private String photoUrl(String photoKey) {
        return photoKey == null ? null : fileStorageService.issueDownloadUrl(photoKey);
    }
}
