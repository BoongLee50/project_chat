package com.moonlighttalk.server.profile.service;

import com.moonlighttalk.server.auth.entity.User;
import com.moonlighttalk.server.auth.mapper.UserMapper;
import com.moonlighttalk.server.common.exception.ApiException;
import com.moonlighttalk.server.common.response.ErrorCode;
import com.moonlighttalk.server.common.storage.FileStorageService;
import com.moonlighttalk.server.common.text.RequestMessages;
import com.moonlighttalk.server.profile.dto.*;
import com.moonlighttalk.server.profile.entity.UserProfile;
import com.moonlighttalk.server.profile.mapper.ProfileMapper;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Year;
import java.util.List;
import java.util.UUID;

@Service
public class ProfileService {

    private static final int MIN_AGE = 18;

    private final UserMapper userMapper;
    private final ProfileMapper profileMapper;
    private final NicknameValidator nicknameValidator;
    private final FileStorageService fileStorageService;

    public ProfileService(UserMapper userMapper,
                           ProfileMapper profileMapper,
                           NicknameValidator nicknameValidator,
                           FileStorageService fileStorageService) {
        this.userMapper = userMapper;
        this.profileMapper = profileMapper;
        this.nicknameValidator = nicknameValidator;
        this.fileStorageService = fileStorageService;
    }

    public NicknameCheckResponse checkNickname(String nickname) {
        return new NicknameCheckResponse(nicknameValidator.isAvailable(nickname));
    }

    @Transactional
    public void createProfile(String userId, CreateProfileRequest request) {
        int age = Year.now().getValue() - request.birthYear();
        if (age < MIN_AGE) {
            throw new ApiException(ErrorCode.AGE_RESTRICTED, HttpStatus.BAD_REQUEST,
                    "만 18세 이상만 가입할 수 있습니다.", "birthYear");
        }

        User user = getUserOrThrow(userId);
        if (!request.nickname().equals(user.getNickname())) {
            nicknameValidator.validateAvailableOrThrow(request.nickname());
        }

        userMapper.updateProfile(userId, request.nickname(), request.birthYear(), request.gender(), request.country());

        if (profileMapper.selectByUserId(userId) == null) {
            profileMapper.insertProfile(userId);
        }
    }

    public MeResponse getMe(String userId) {
        User user = getUserOrThrow(userId);
        UserProfile profile = profileMapper.selectByUserId(userId);
        List<String> interests = profileMapper.selectInterests(userId);
        List<String> regions = profileMapper.selectRegions(userId);

        String photoUrl = resolvePhotoUrl(profile);
        String mainPhotoUrl = resolveMainPhotoUrl(profile);
        String intro = profile != null ? profile.getIntro() : null;

        return new MeResponse(
                user.getId(), user.getNickname(), user.getBirthYear(), user.getGender(), user.getCountry(),
                Boolean.TRUE.equals(user.getPremium()), photoUrl, mainPhotoUrl, intro, interests, regions
        );
    }

    public PublicProfileResponse getPublicProfile(String targetUserId) {
        User user = userMapper.findById(targetUserId);
        if (user == null) {
            throw new ApiException(ErrorCode.USER_NOT_FOUND, HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다.");
        }
        UserProfile profile = profileMapper.selectByUserId(targetUserId);
        List<String> interests = profileMapper.selectInterests(targetUserId);
        List<String> regions = profileMapper.selectRegions(targetUserId);

        return new PublicProfileResponse(
                user.getId(), user.getNickname(), user.getGender(), user.getCountry(),
                Boolean.TRUE.equals(user.getPremium()), resolvePhotoUrl(profile), resolveMainPhotoUrl(profile),
                profile != null ? profile.getIntro() : null, interests, regions
        );
    }

    public UploadUrlResponse issueProfilePhotoUploadUrl(String userId, String contentType) {
        String storageKey = "profile/" + userId + "/" + UUID.randomUUID() + extensionOf(contentType);
        String uploadUrl = fileStorageService.issueUploadUrl(storageKey, contentType);
        return new UploadUrlResponse(uploadUrl, storageKey);
    }

    /** 얼굴 사진(첫째 칸) — 목록·셀이 쓰는 사진. {@code null}이면 제거. */
    @Transactional
    public void registerProfilePhoto(String userId, String storageKey) {
        checkOwnKey(userId, storageKey);
        ensureProfileRow(userId);
        String previousKey = profileMapper.selectByUserId(userId).getPhotoKey();

        profileMapper.updatePhotoKey(userId, storageKey);
        deleteReplaced(previousKey, storageKey);
    }

    /** 자유 사진(둘째 칸) — [미리 보기]의 큰 메인 사진(V28). {@code null}이면 제거. */
    @Transactional
    public void registerProfileMainPhoto(String userId, String storageKey) {
        checkOwnKey(userId, storageKey);
        ensureProfileRow(userId);
        String previousKey = profileMapper.selectByUserId(userId).getMainPhotoKey();

        profileMapper.updateMainPhotoKey(userId, storageKey);
        deleteReplaced(previousKey, storageKey);
    }

    /**
     * 내가 발급받은 경로({@code profile/<내 id>/})의 key만 받는다.
     *
     * <p>안 막으면 남의 사진 key를 내 칸에 등록할 수 있고, 다음 교체 때 그 파일을
     * <b>내가 지우게 된다</b>(교체 시 이전 key를 스토리지에서 지우므로).
     */
    private void checkOwnKey(String userId, String storageKey) {
        if (storageKey != null && !storageKey.startsWith("profile/" + userId + "/")) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.BAD_REQUEST,
                    "업로드한 사진이 아닙니다.", "storageKey");
        }
    }

    private void deleteReplaced(String previousKey, String newKey) {
        if (previousKey != null && !previousKey.equals(newKey)) {
            fileStorageService.delete(previousKey);
        }
    }

    /** 자기소개 최대 길이(코드포인트). 🚨 클라 {@code ProfileCatalog.maxIntro}와 같은 숫자 — 함께 바꿀 것. */
    static final int MAX_INTRO = 300;

    @Transactional
    public void updateIntro(String userId, String intro) {
        if (RequestMessages.length(intro) > MAX_INTRO) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.BAD_REQUEST,
                    "자기소개는 최대 " + MAX_INTRO + "자까지 입력할 수 있습니다.", "intro");
        }
        ensureProfileRow(userId);
        profileMapper.updateIntro(userId, intro);
    }

    @Transactional
    public void updateInterests(String userId, List<String> codes) {
        profileMapper.deleteInterests(userId);
        if (!codes.isEmpty()) {
            profileMapper.insertInterests(userId, codes);
        }
        // 관심사는 별도 테이블이라 프로필 갱신 시각이 자동으로 안 찍힌다(V8).
        profileMapper.touchUpdatedAt(userId);
    }

    @Transactional
    public void updateRegions(String userId, List<String> codes) {
        profileMapper.deleteRegions(userId);
        if (!codes.isEmpty()) {
            profileMapper.insertRegions(userId, codes);
        }
        profileMapper.touchUpdatedAt(userId);
    }

    private void ensureProfileRow(String userId) {
        if (profileMapper.selectByUserId(userId) == null) {
            profileMapper.insertProfile(userId);
        }
    }

    private String resolvePhotoUrl(UserProfile profile) {
        if (profile == null || profile.getPhotoKey() == null) {
            return null;
        }
        return fileStorageService.issueDownloadUrl(profile.getPhotoKey());
    }

    private String resolveMainPhotoUrl(UserProfile profile) {
        if (profile == null || profile.getMainPhotoKey() == null) {
            return null;
        }
        return fileStorageService.issueDownloadUrl(profile.getMainPhotoKey());
    }

    private User getUserOrThrow(String userId) {
        User user = userMapper.findById(userId);
        if (user == null) {
            throw new ApiException(ErrorCode.USER_NOT_FOUND, HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다.");
        }
        return user;
    }

    private String extensionOf(String contentType) {
        if (contentType == null) {
            return "";
        }
        return switch (contentType) {
            case "image/png" -> ".png";
            case "image/webp" -> ".webp";
            default -> ".jpg";
        };
    }
}
