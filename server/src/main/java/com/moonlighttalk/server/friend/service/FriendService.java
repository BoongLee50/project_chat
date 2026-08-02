package com.moonlighttalk.server.friend.service;

import com.moonlighttalk.server.auth.entity.User;
import com.moonlighttalk.server.auth.mapper.UserMapper;
import com.moonlighttalk.server.auth.service.GateService;
import com.moonlighttalk.server.chat.entity.ChatRoom;
import com.moonlighttalk.server.chat.mapper.ChatMapper;
import com.moonlighttalk.server.chat.socket.Opcodes;
import com.moonlighttalk.server.chat.socket.Packet;
import com.moonlighttalk.server.chat.socket.SocketRegistry;
import com.moonlighttalk.server.common.exception.ApiException;
import com.moonlighttalk.server.common.response.ErrorCode;
import com.moonlighttalk.server.common.storage.FileStorageService;
import com.moonlighttalk.server.friend.dto.AcceptFriendResponse;
import com.moonlighttalk.server.friend.dto.FriendDto;
import com.moonlighttalk.server.friend.dto.FriendPostDto;
import com.moonlighttalk.server.friend.dto.FriendRequestDto;
import com.moonlighttalk.server.friend.entity.FriendPost;
import com.moonlighttalk.server.friend.entity.FriendSummary;
import com.moonlighttalk.server.friend.entity.Friendship;
import com.moonlighttalk.server.friend.mapper.FriendMapper;
import com.moonlighttalk.server.garden.mapper.GardenMapper;
import com.moonlighttalk.server.presence.PresenceService;
import com.moonlighttalk.server.store.service.EntitlementService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * 친구 — <b>양방향(상호 동의)</b>. 요청 → 상대가 수락해야 성립한다. (기획서 6장, 02 §1.6)
 *
 * <p>수락하면 두 사람 사이에 <b>상시 대화방</b>({@code chat_rooms.type=FRIEND})이 생긴다.
 * FRIEND 방은 야간 게이트(17~06시)와 무관하게 24시간 유지되고, 종료 배치 대상에서도 빠진다.
 *
 * <p>이미 매칭 대화(MATCH)가 살아있는 상대와 친구가 되면 <b>그 방을 FRIEND로 승격</b>한다.
 * {@code chat_rooms.active_pair_key}가 유니크라 같은 페어의 방을 새로 만들 수 없기도 하고,
 * 나누던 대화를 그대로 이어가는 편이 자연스럽다.
 */
@Service
public class FriendService {

    private final FriendMapper friendMapper;
    private final ChatMapper chatMapper;
    private final UserMapper userMapper;
    private final GardenMapper gardenMapper;
    private final GateService gateService;
    private final PresenceService presenceService;
    private final EntitlementService entitlementService;
    private final SocketRegistry socketRegistry;
    private final FileStorageService fileStorageService;

    /**
     * 최대 친구 수. 기획서에 20과 30이 함께 적혀 있어(보완 문서 대기) 설정으로 뺐다.
     * 프리미엄이 더 많이 가질 수 있다는 해석으로 기본값을 잡아 두었다.
     */
    private final int maxFriends;
    private final int maxFriendsPremium;

    public FriendService(FriendMapper friendMapper,
                          ChatMapper chatMapper,
                          UserMapper userMapper,
                          GardenMapper gardenMapper,
                          GateService gateService,
                          PresenceService presenceService,
                          EntitlementService entitlementService,
                          SocketRegistry socketRegistry,
                          FileStorageService fileStorageService,
                          @Value("${app.friend.max-count:20}") int maxFriends,
                          @Value("${app.friend.max-count-premium:30}") int maxFriendsPremium) {
        this.friendMapper = friendMapper;
        this.chatMapper = chatMapper;
        this.userMapper = userMapper;
        this.gardenMapper = gardenMapper;
        this.gateService = gateService;
        this.presenceService = presenceService;
        this.entitlementService = entitlementService;
        this.socketRegistry = socketRegistry;
        this.fileStorageService = fileStorageService;
        this.maxFriends = maxFriends;
        this.maxFriendsPremium = maxFriendsPremium;
    }

    // ── 친구 요청 ───────────────────────────────────────────

    /** 친구 요청. 성공하면 상대에게 소켓으로 도착을 알린다. */
    @Transactional
    public String request(String userId, String targetUserId) {
        if (userId.equals(targetUserId)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.BAD_REQUEST,
                    "자신에게는 친구 요청을 보낼 수 없어요.");
        }
        if (userMapper.findById(targetUserId) == null) {
            throw new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다.");
        }
        if (gardenMapper.existsBlockOrReport(userId, targetUserId)) {
            throw new ApiException(ErrorCode.TARGET_BLOCKED_OR_REPORTED, HttpStatus.CONFLICT,
                    "현재 이 사용자에게 친구 요청을 보낼 수 없어요.");
        }

        String pairKey = pairKey(userId, targetUserId);
        Friendship existing = friendMapper.selectByPairKey(pairKey);
        if (existing != null) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.CONFLICT,
                    "ACCEPTED".equals(existing.getStatus())
                            ? "이미 친구예요."
                            : "이미 친구 요청이 오갔어요. 응답을 기다려 주세요.");
        }
        requireFriendSlot(userId);

        User me = getUserOrThrow(userId);
        Friendship friendship = new Friendship();
        friendship.setId(UUID.randomUUID().toString());
        friendship.setRequesterId(userId);
        friendship.setAddresseeId(targetUserId);
        friendship.setStatus("PENDING");
        friendship.setPairKey(pairKey);
        try {
            friendMapper.insert(friendship);
        } catch (DataIntegrityViolationException e) {
            // 같은 순간 상대도 요청을 보낸 경우(pair_key 유니크 위반)
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.CONFLICT,
                    "이미 친구 요청이 오갔어요. 응답을 기다려 주세요.");
        }

        socketRegistry.sendTo(targetUserId, Packet.of(Opcodes.FRIEND_REQ_INCOMING, Map.of(
                "friendshipId", friendship.getId(),
                "fromUserId", userId,
                "fromNickname", me.getNickname() == null ? "" : me.getNickname()
        )));
        return friendship.getId();
    }

    /** 요청 수락 → 상시 대화방 생성(또는 기존 방 승격). 양쪽에 알린다. */
    @Transactional
    public AcceptFriendResponse accept(String userId, String friendshipId) {
        Friendship friendship = requireFriendship(friendshipId);
        if (!friendship.getAddresseeId().equals(userId)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.FORBIDDEN,
                    "내가 받은 요청만 수락할 수 있어요.");
        }
        if ("ACCEPTED".equals(friendship.getStatus())) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.CONFLICT, "이미 친구예요.");
        }
        // 슬롯은 양쪽 모두 확인한다. 요청 시점엔 여유가 있었어도 그 사이에 찼을 수 있다.
        requireFriendSlot(userId);
        requireFriendSlot(friendship.getRequesterId());

        friendMapper.accept(friendshipId, LocalDateTime.now());
        String roomId = ensureFriendRoom(friendship);

        Packet packet = Packet.of(Opcodes.FRIEND_STATE, Map.of(
                "friendshipId", friendshipId, "state", "accepted", "roomId", roomId));
        socketRegistry.sendTo(friendship.getRequesterId(), packet);
        socketRegistry.sendTo(friendship.getAddresseeId(), packet);
        return new AcceptFriendResponse(friendshipId, roomId);
    }

    /** 요청 거절 — status에 REJECTED가 없으므로 행을 지운다(다시 요청 가능). */
    @Transactional
    public void reject(String userId, String friendshipId) {
        Friendship friendship = requireFriendship(friendshipId);
        if (!friendship.getAddresseeId().equals(userId)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.FORBIDDEN,
                    "내가 받은 요청만 거절할 수 있어요.");
        }
        if ("ACCEPTED".equals(friendship.getStatus())) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.CONFLICT,
                    "이미 친구가 된 요청이에요.");
        }
        friendMapper.delete(friendshipId);

        socketRegistry.sendTo(friendship.getRequesterId(), Packet.of(Opcodes.FRIEND_STATE, Map.of(
                "friendshipId", friendshipId, "state", "rejected")));
    }

    /** 보낸 요청 취소. */
    @Transactional
    public void cancel(String userId, String friendshipId) {
        Friendship friendship = requireFriendship(friendshipId);
        if (!friendship.getRequesterId().equals(userId)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.FORBIDDEN,
                    "내가 보낸 요청만 취소할 수 있어요.");
        }
        if ("ACCEPTED".equals(friendship.getStatus())) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.CONFLICT,
                    "이미 친구가 된 요청이에요.");
        }
        friendMapper.delete(friendshipId);

        socketRegistry.sendTo(friendship.getAddresseeId(), Packet.of(Opcodes.FRIEND_STATE, Map.of(
                "friendshipId", friendshipId, "state", "cancelled")));
    }

    // ── 친구 ───────────────────────────────────────────────

    public List<FriendDto> myFriends(String userId, String gender, Integer ageMin,
                                      Integer ageMax, String country) {
        return friendMapper.selectFriends(userId, gender, ageMin, ageMax, country).stream()
                .map(this::toFriendDto)
                .toList();
    }

    public List<FriendRequestDto> receivedRequests(String userId) {
        return friendMapper.selectReceivedRequests(userId).stream().map(this::toRequestDto).toList();
    }

    public List<FriendRequestDto> sentRequests(String userId) {
        return friendMapper.selectSentRequests(userId).stream().map(this::toRequestDto).toList();
    }

    /**
     * 친구의 오늘 포스트. (기획서 화면 19)
     *
     * <p><b>친구만</b> 볼 수 있다 — friendshipId로 조회해 내가 그 관계의 당사자인지 확인하므로
     * 남의 포스트를 임의로 들여다볼 수 없다.
     */
    public FriendPostDto todayPost(String userId, String friendshipId) {
        Friendship friendship = requireFriendship(friendshipId);
        if (!friendship.hasMember(userId)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.FORBIDDEN,
                    "내 친구 관계가 아니에요.");
        }
        if (!"ACCEPTED".equals(friendship.getStatus())) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.CONFLICT,
                    "아직 친구가 아니에요.");
        }

        String friendId = friendship.otherOf(userId);
        FriendPost post = friendMapper.selectTodayPost(friendId, gateService.currentSessionDate());
        if (post == null) {
            throw new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND,
                    "친구가 아직 오늘의 포스트를 공유하지 않았어요.");
        }

        List<String> photoUrls = gardenMapper.selectPhotoKeys(post.getPostId()).stream()
                .map(fileStorageService::issueDownloadUrl)
                .toList();

        return new FriendPostDto(
                post.getUserId(),
                post.getNickname(),
                age(post.getBirthYear()),
                post.getCountry(),
                entitlementService.boostedUserIds().contains(friendId),
                presenceService.isOnline(friendId),
                photoUrls,
                post.getOneLiner(),
                post.getLikes(),
                gardenMapper.countComments(post.getPostId()),
                post.getPublishedAt());
    }

    /** 친구 삭제 — 관계를 지우고 상시 대화방도 닫는다. */
    @Transactional
    public void remove(String userId, String friendshipId) {
        Friendship friendship = requireFriendship(friendshipId);
        if (!friendship.hasMember(userId)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.FORBIDDEN,
                    "내 친구 관계가 아니에요.");
        }
        friendMapper.delete(friendshipId);

        ChatRoom room = chatMapper.selectActiveRoomByPairKeyAndType(friendship.getPairKey(), "FRIEND");
        if (room != null) {
            chatMapper.endRoom(room.getId(), LocalDateTime.now());
            socketRegistry.sendTo(friendship.otherOf(userId), Packet.of(Opcodes.ROOM_STATE, Map.of(
                    "roomId", room.getId(), "state", "ended")));
        }
        socketRegistry.sendTo(friendship.otherOf(userId), Packet.of(Opcodes.FRIEND_STATE, Map.of(
                "friendshipId", friendshipId, "state", "removed")));
    }

    // ── 내부 ────────────────────────────────────────────────

    /** 상시 대화방 확보 — 살아있는 방이 있으면 FRIEND로 승격, 없으면 새로 만든다. */
    private String ensureFriendRoom(Friendship friendship) {
        ChatRoom existing = chatMapper.selectActiveRoomByPairKey(friendship.getPairKey());
        if (existing != null) {
            if (!"FRIEND".equals(existing.getType())) {
                chatMapper.updateRoomType(existing.getId(), "FRIEND");
            }
            return existing.getId();
        }

        ChatRoom room = new ChatRoom();
        room.setId(UUID.randomUUID().toString());
        room.setUserA(friendship.getRequesterId());
        room.setUserB(friendship.getAddresseeId());
        room.setStatus("ACTIVE");
        room.setType("FRIEND");
        chatMapper.insertRoom(room);
        return room.getId();
    }

    private void requireFriendSlot(String userId) {
        User user = getUserOrThrow(userId);
        int limit = Boolean.TRUE.equals(user.getPremium()) ? maxFriendsPremium : maxFriends;
        if (friendMapper.countFriends(userId) >= limit) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.CONFLICT,
                    "친구는 최대 " + limit + "명까지예요.");
        }
    }

    private Friendship requireFriendship(String id) {
        Friendship friendship = friendMapper.selectById(id);
        if (friendship == null) {
            throw new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "친구 요청을 찾을 수 없어요.");
        }
        return friendship;
    }

    private User getUserOrThrow(String userId) {
        User user = userMapper.findById(userId);
        if (user == null) {
            throw new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다.");
        }
        return user;
    }

    /** 방향과 무관하게 같은 값이 나오도록 정렬해 잇는다. */
    private String pairKey(String a, String b) {
        return a.compareTo(b) <= 0 ? a + "_" + b : b + "_" + a;
    }

    private FriendDto toFriendDto(FriendSummary s) {
        return new FriendDto(
                s.getFriendshipId(),
                s.getUserId(),
                s.getNickname(),
                age(s.getBirthYear()),
                s.getGender(),
                s.getCountry(),
                s.getIntro(),
                photoUrl(s.getPhotoKey()),
                s.getRoomId(),
                presenceService.isOnline(s.getUserId()),
                s.getAcceptedAt());
    }

    private FriendRequestDto toRequestDto(Friendship f) {
        return new FriendRequestDto(
                f.getId(), f.getRequesterId(), f.getAddresseeId(), f.getStatus(),
                f.getPartnerNickname(), age(f.getPartnerBirthYear()), f.getPartnerCountry(),
                photoUrl(f.getPartnerPhotoKey()), f.getCreatedAt());
    }

    private Integer age(Integer birthYear) {
        return birthYear == null ? null : gateService.nowKst().getYear() - birthYear;
    }

    private String photoUrl(String photoKey) {
        return photoKey == null ? null : fileStorageService.issueDownloadUrl(photoKey);
    }
}
