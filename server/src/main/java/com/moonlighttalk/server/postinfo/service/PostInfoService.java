package com.moonlighttalk.server.postinfo.service;

import com.moonlighttalk.server.auth.entity.User;
import com.moonlighttalk.server.auth.mapper.UserMapper;
import com.moonlighttalk.server.auth.service.SessionTimeService;
import com.moonlighttalk.server.chat.entity.ChatRequestEntity;
import com.moonlighttalk.server.chat.entity.ChatRoom;
import com.moonlighttalk.server.chat.mapper.ChatMapper;
import com.moonlighttalk.server.common.exception.ApiException;
import com.moonlighttalk.server.common.response.ErrorCode;
import com.moonlighttalk.server.common.storage.FileStorageService;
import com.moonlighttalk.server.friend.entity.Friendship;
import com.moonlighttalk.server.friend.mapper.FriendMapper;
import com.moonlighttalk.server.friend.service.FriendRelations;
import com.moonlighttalk.server.garden.mapper.GardenMapper;
import com.moonlighttalk.server.garden.service.GardenService;
import com.moonlighttalk.server.postinfo.dto.PostInfoDto;
import com.moonlighttalk.server.presence.PresenceService;
import com.moonlighttalk.server.profile.entity.UserProfile;
import com.moonlighttalk.server.profile.mapper.ProfileMapper;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

/**
 * [포스트 정보] — 상대 한 사람을 보여 주는 <b>공통</b> 화면의 데이터(기획 6-1 · 7-1).
 *
 * <p>대화방의 받은 신청 카드, 친구 목록 카드, 달빛가든이 모두 이 하나를 부른다.
 * 화면은 같고 <b>하단 버튼만</b> 부르는 곳에 따라 달라진다 — 그 판단에 필요한 재료
 * (받은 대화 신청 · 친구 관계)를 여기서 함께 실어 보낸다.
 *
 * <p><b>열람 제한은 여기서도 서버가 건다.</b> 가든에서 막아 놓고 이 화면에서 뚫리면
 * 막지 않은 것과 같다 — 판정은 {@link GardenService#canViewAllPhotos(String)} 하나를
 * 그대로 쓴다(규칙이 두 벌이 되면 한쪽만 늙는다, 함정 #18).
 *
 * <p>오늘 포스트가 없는 사람도 이 화면에 들어온다(친구 목록·받은 신청은 포스트와 무관하다).
 * 그때는 <b>프로필 사진 한 장</b>으로 대신한다 — 빈 화면을 보여 주는 것보다 낫고,
 * {@code hasTodayPost}로 화면이 그 차이를 알 수 있게 한다.
 */
@Service
public class PostInfoService {

    private final UserMapper userMapper;
    private final ProfileMapper profileMapper;
    private final GardenMapper gardenMapper;
    private final GardenService gardenService;
    private final ChatMapper chatMapper;
    private final FriendMapper friendMapper;
    private final PresenceService presenceService;
    private final FileStorageService fileStorageService;
    private final SessionTimeService sessionTime;

    public PostInfoService(UserMapper userMapper,
                            ProfileMapper profileMapper,
                            GardenMapper gardenMapper,
                            GardenService gardenService,
                            ChatMapper chatMapper,
                            FriendMapper friendMapper,
                            PresenceService presenceService,
                            FileStorageService fileStorageService,
                            SessionTimeService sessionTime) {
        this.userMapper = userMapper;
        this.profileMapper = profileMapper;
        this.gardenMapper = gardenMapper;
        this.gardenService = gardenService;
        this.chatMapper = chatMapper;
        this.friendMapper = friendMapper;
        this.presenceService = presenceService;
        this.fileStorageService = fileStorageService;
        this.sessionTime = sessionTime;
    }

    public PostInfoDto get(String userId, String targetUserId) {
        User target = userMapper.findById(targetUserId);
        if (target == null) {
            throw new ApiException(ErrorCode.USER_NOT_FOUND, HttpStatus.NOT_FOUND,
                    "사용자를 찾을 수 없습니다.");
        }
        UserProfile profile = profileMapper.selectByUserId(targetUserId);
        LocalDate sessionDate = sessionTime.currentSessionDate();

        Photos photos = resolvePhotos(userId, targetUserId, profile, sessionDate);
        ChatRequestEntity request = chatMapper.selectPendingRequestBetween(targetUserId, userId);
        String pairKey = FriendRelations.pairKey(userId, targetUserId);
        Friendship friendship = friendMapper.selectByPairKey(pairKey);
        ChatRoom room = chatMapper.selectActiveRoomByPairKey(pairKey);

        return new PostInfoDto(
                target.getId(),
                target.getNickname(),
                target.getBirthYear() == null ? null
                        : sessionTime.nowKst().getYear() - target.getBirthYear(),
                target.getCountry(),
                target.getGender(),
                presenceService.isOnline(targetUserId),
                Boolean.TRUE.equals(target.getPremium()),
                photos.urls(),
                photos.locked(),
                photos.total(),
                photos.fromPost(),
                profile == null || profile.getPhotoKey() == null
                        ? null : fileStorageService.issueDownloadUrl(profile.getPhotoKey()),
                profile == null ? null : profile.getIntro(),
                profileMapper.selectInterests(targetUserId),
                profileMapper.selectRegions(targetUserId),
                request == null ? null : request.getId(),
                request == null ? null : request.getMessage(),
                FriendRelations.of(friendship, userId),
                friendship == null ? null : friendship.getId(),
                // 내가 받은 신청일 때만 보여 준다 — 내가 쓴 말을 내 화면에 되돌려 줄 이유가 없다.
                friendship != null && userId.equals(friendship.getAddresseeId())
                        ? friendship.getMessage() : null,
                room == null ? null : room.getId()
        );
    }

    /**
     * 오늘 포스트가 있으면 그 사진들(제한을 적용해), 없으면 프로필 사진 한 장.
     *
     * @param fromPost 사진의 출처가 포스트인가 — 화면이 `1/9` 인디케이터를 띄울지 정한다
     */
    private Photos resolvePhotos(String userId, String targetUserId,
                                  UserProfile profile, LocalDate sessionDate) {
        String postId = gardenMapper.selectTodayPostId(targetUserId, sessionDate);
        if (postId == null) {
            String key = profile == null ? null : profile.getPhotoKey();
            List<String> urls = key == null
                    ? List.of()
                    : List.of(fileStorageService.issueDownloadUrl(key));
            return new Photos(urls, false, urls.size(), false);
        }

        List<String> keys = gardenMapper.selectPhotoKeys(postId);
        boolean locked = !gardenService.canViewAllPhotos(userId) && keys.size() > 1;
        // 메인이 첫 장이므로(②단계) 앞에서 1장만 자르면 그게 곧 "메인 사진 1장"이다.
        List<String> visible = locked ? keys.subList(0, 1) : keys;
        return new Photos(
                visible.stream().map(fileStorageService::issueDownloadUrl).toList(),
                locked, keys.size(), true);
    }

    private record Photos(List<String> urls, boolean locked, int total, boolean fromPost) {
    }
}
