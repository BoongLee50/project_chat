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
import com.moonlighttalk.server.store.service.EntitlementService;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Value;
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
 * 하루 무료 2회 후 건당 루나 5 차감. 무제한 대화신청 권리(UNLIMITED_CHAT_REQ)가 있으면 무차감.
 */
@Service
public class ChatService {

    /** 한 번에 내려주는 메시지 수. 기획 수치가 아니라 통신 파라미터라 설정으로 빼지 않는다. */
    private static final int MESSAGE_PAGE_SIZE = 30;
    private static final String USAGE_CHAT_REQUEST = "CHAT_REQUEST";

    private final ChatMapper chatMapper;
    private final UserMapper userMapper;
    private final GardenMapper gardenMapper;
    private final LunaService lunaService;
    private final GateService gateService;
    private final SocketRegistry socketRegistry;
    private final FileStorageService fileStorageService;
    private final EntitlementService entitlementService;

    /** 무료 횟수를 다 쓴 뒤 대화 신청 1건당 차감할 루나. */
    private final int lunaCost;

    /** 하루에 공짜로 보낼 수 있는 대화 신청 수. */
    private final int freeRequestsPerDay;

    public ChatService(ChatMapper chatMapper,
                        UserMapper userMapper,
                        GardenMapper gardenMapper,
                        LunaService lunaService,
                        GateService gateService,
                        SocketRegistry socketRegistry,
                        FileStorageService fileStorageService,
                        EntitlementService entitlementService,
                        @Value("${app.chat.request-luna-cost:5}") int lunaCost,
                        @Value("${app.chat.free-requests-per-day:2}") int freeRequestsPerDay) {
        this.chatMapper = chatMapper;
        this.userMapper = userMapper;
        this.gardenMapper = gardenMapper;
        this.lunaService = lunaService;
        this.gateService = gateService;
        this.socketRegistry = socketRegistry;
        this.fileStorageService = fileStorageService;
        this.entitlementService = entitlementService;
        this.lunaCost = lunaCost;
        this.freeRequestsPerDay = freeRequestsPerDay;
    }

    // ── 대화 신청 ───────────────────────────────────────────

    /** 대화 신청 생성 — 무료 2회 소진 후 루나 5 차감. 성공 시 상대에게 소켓 알림. */
    @Transactional
    public void createRequest(String userId, String targetUserId, String message) {
        requireGateOpen();
        if (userId.equals(targetUserId)) {
            throw new ApiException(ErrorCode.CHAT_SELF, HttpStatus.BAD_REQUEST,
                    "자신에게는 대화를 신청할 수 없어요.");
        }
        if (gardenMapper.existsBlockOrReport(userId, targetUserId)) {
            throw new ApiException(ErrorCode.CHAT_TARGET_BLOCKED, HttpStatus.CONFLICT,
                    "현재 이 사용자에게 대화 신청을 보낼 수 없어요.");
        }
        if (chatMapper.existsPendingRequest(userId, targetUserId)) {
            throw new ApiException(ErrorCode.CHAT_REQUEST_PENDING, HttpStatus.CONFLICT,
                    "이미 대화를 신청했어요. 상대의 응답을 기다려 주세요.");
        }

        User me = getUserOrThrow(userId);
        // 무제한 대화신청 권리(프라임 번들 또는 개별 구매) — 02 §1.7
        boolean premium = entitlementService.hasUnlimitedChatRequests(userId);
        int cost = 0;

        if (!premium) {
            int used = lunaService.dailyUsed(userId, gateService.currentSessionDate(), USAGE_CHAT_REQUEST);
            if (used >= freeRequestsPerDay) {
                cost = lunaCost;
            }
        }

        String requestId = UUID.randomUUID().toString();
        if (cost > 0) {
            lunaService.deduct(userId, cost, USAGE_CHAT_REQUEST, requestId,
                    "대화 신청에 필요한 루나가 부족해요.");
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
        // 수락하면 매칭 대화방이 생기므로 운영시간 안에서만 가능하다.
        requireGateOpen();
        ChatRequestEntity request = requireRequest(requestId);
        if (!request.getToUser().equals(userId)) {
            throw new ApiException(ErrorCode.CHAT_ACCEPT_NOT_RECEIVER, HttpStatus.FORBIDDEN,
                    "내가 받은 신청만 수락할 수 있어요.");
        }
        if (!"PENDING".equals(request.getStatus())) {
            throw new ApiException(ErrorCode.CHAT_REQUEST_ALREADY_HANDLED, HttpStatus.CONFLICT,
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
            throw new ApiException(ErrorCode.CHAT_REJECT_NOT_RECEIVER, HttpStatus.FORBIDDEN,
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
        // 친구 상시 대화방은 24시간 예외라 매칭 대화만 운영시간을 따진다(02 §4).
        if (!"FRIEND".equals(room.getType())) {
            requireGateOpen();
        }

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

    /**
     * 운영시간(17~06시) 밖이면 막는다. 클라가 화면을 가리는 것만으로는 규칙이 되지 않으므로
     * 서버에서 판정한다(post/garden 도메인과 같은 패턴).
     *
     * <p>거절·나가기·읽음·목록 조회는 막지 않는다 — 이미 벌어진 일을 정리하는 동작이라
     * 시간대와 무관하게 할 수 있어야 한다. 친구 관련 동작도 24시간 예외다.
     */
    private void requireGateOpen() {
        if (!gateService.isOpenNow()) {
            throw new ApiException(ErrorCode.CHAT_GATE_CLOSED, HttpStatus.CONFLICT,
                    "달빛이 찾아오는 오후 5시부터 다음날 오전 6시까지 대화할 수 있어요.");
        }
    }

    private void notifyRoomState(ChatRoom room, String state) {
        Packet packet = Packet.of(Opcodes.ROOM_STATE, Map.of(
                "roomId", room.getId(), "state", state));
        socketRegistry.sendTo(room.getUserA(), packet);
        socketRegistry.sendTo(room.getUserB(), packet);
    }

    private ChatRoom requireMemberRoom(String userId, String roomId) {
        ChatRoom room = chatMapper.selectRoom(roomId);
        if (room == null) {
            throw new ApiException(ErrorCode.CHAT_ROOM_NOT_FOUND, HttpStatus.NOT_FOUND,
                    "대화방을 찾을 수 없어요.");
        }
        if (!room.hasMember(userId)) {
            throw new ApiException(ErrorCode.CHAT_NOT_MEMBER, HttpStatus.FORBIDDEN,
                    "참여 중인 대화방이 아니에요.");
        }
        if ("ENDED".equals(room.getStatus())) {
            throw new ApiException(ErrorCode.CHAT_ROOM_CLOSED, HttpStatus.CONFLICT, "종료된 대화방이에요.");
        }
        return room;
    }

    private ChatRequestEntity requireRequest(String requestId) {
        ChatRequestEntity request = chatMapper.selectRequest(requestId);
        if (request == null) {
            throw new ApiException(ErrorCode.CHAT_REQUEST_NOT_FOUND, HttpStatus.NOT_FOUND,
                    "신청을 찾을 수 없어요.");
        }
        return request;
    }

    private User getUserOrThrow(String userId) {
        User user = userMapper.findById(userId);
        if (user == null) {
            throw new ApiException(ErrorCode.USER_NOT_FOUND, HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다.");
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
