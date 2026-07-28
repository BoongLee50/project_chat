package com.moonlighttalk.server.profile.service;

import com.moonlighttalk.server.auth.entity.User;
import com.moonlighttalk.server.auth.mapper.UserMapper;
import com.moonlighttalk.server.common.exception.ApiException;
import com.moonlighttalk.server.common.response.ErrorCode;
import com.moonlighttalk.server.common.storage.FileStorageService;
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
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.BAD_REQUEST,
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
        String intro = profile != null ? profile.getIntro() : null;

        return new MeResponse(
                user.getId(), user.getNickname(), user.getBirthYear(), user.getGender(), user.getCountry(),
                Boolean.TRUE.equals(user.getPremium()), photoUrl, intro, interests, regions
        );
    }

    public PublicProfileResponse getPublicProfile(String targetUserId) {
        User user = userMapper.findById(targetUserId);
        if (user == null) {
            throw new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다.");
        }
        UserProfile profile = profileMapper.selectByUserId(targetUserId);
        List<String> interests = profileMapper.selectInterests(targetUserId);
        List<String> regions = profileMapper.selectRegions(targetUserId);

        return new PublicProfileResponse(
                user.getId(), user.getNickname(), user.getGender(), user.getCountry(),
                Boolean.TRUE.equals(user.getPremium()), resolvePhotoUrl(profile),
                profile != null ? profile.getIntro() : null, interests, regions
        );
    }

    public UploadUrlResponse issueProfilePhotoUploadUrl(String userId, String contentType) {
        String storageKey = "profile/" + userId + "/" + UUID.randomUUID() + extensionOf(contentType);
        String uploadUrl = fileStorageService.issueUploadUrl(storageKey, contentType);
        return new UploadUrlResponse(uploadUrl, storageKey);
    }

    @Transactional
    public void registerProfilePhoto(String userId, String storageKey) {
        if (profileMapper.selectByUserId(userId) == null) {
            profileMapper.insertProfile(userId);
        }
        UserProfile existing = profileMapper.selectByUserId(userId);
        String previousKey = existing != null ? existing.getPhotoKey() : null;

        profileMapper.updatePhotoKey(userId, storageKey);

        if (previousKey != null && !previousKey.equals(storageKey)) {
            fileStorageService.delete(previousKey);
        }
    }

    @Transactional
    public void updateIntro(String userId, String intro) {
        ensureProfileRow(userId);
        profileMapper.updateIntro(userId, intro);
    }

    @Transactional
    public void updateInterests(String userId, List<String> codes) {
        profileMapper.deleteInterests(userId);
        if (!codes.isEmpty()) {
            profileMapper.insertInterests(userId, codes);
        }
    }

    @Transactional
    public void updateRegions(String userId, List<String> codes) {
        profileMapper.deleteRegions(userId);
        if (!codes.isEmpty()) {
            profileMapper.insertRegions(userId, codes);
        }
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

    private User getUserOrThrow(String userId) {
        User user = userMapper.findById(userId);
        if (user == null) {
            throw new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다.");
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
