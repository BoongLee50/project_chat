package com.moonlighttalk.server.profile.controller;

import com.moonlighttalk.server.common.security.CurrentUserId;
import com.moonlighttalk.server.profile.dto.*;
import com.moonlighttalk.server.profile.service.ProfileService;
import jakarta.validation.Valid;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

/** 01 문서 §1.2 온보딩 / 프로필 */
@RestController
public class ProfileController {

    private final ProfileService profileService;

    public ProfileController(ProfileService profileService) {
        this.profileService = profileService;
    }

    @GetMapping("/profile/nickname:check")
    public NicknameCheckResponse checkNickname(@RequestParam String value) {
        return profileService.checkNickname(value);
    }

    @PostMapping("/profile")
    public void createProfile(@CurrentUserId String userId, @Valid @RequestBody CreateProfileRequest request) {
        profileService.createProfile(userId, request);
    }

    @GetMapping("/me")
    public MeResponse me(@CurrentUserId String userId) {
        return profileService.getMe(userId);
    }

    @PostMapping("/me/profile-photo:upload-url")
    public UploadUrlResponse issueProfilePhotoUploadUrl(
            @CurrentUserId String userId,
            @RequestParam(defaultValue = MediaType.IMAGE_JPEG_VALUE) String contentType) {
        return profileService.issueProfilePhotoUploadUrl(userId, contentType);
    }

    @PutMapping("/me/profile-photo")
    public void registerProfilePhoto(@CurrentUserId String userId, @RequestBody RegisterProfilePhotoRequest request) {
        profileService.registerProfilePhoto(userId, request.storageKey());
    }

    @PutMapping("/me/interests")
    public void updateInterests(@CurrentUserId String userId, @Valid @RequestBody InterestsRequest request) {
        profileService.updateInterests(userId, request.codes());
    }

    @PutMapping("/me/intro")
    public void updateIntro(@CurrentUserId String userId, @Valid @RequestBody IntroRequest request) {
        profileService.updateIntro(userId, request.intro());
    }

    @PutMapping("/me/regions")
    public void updateRegions(@CurrentUserId String userId, @Valid @RequestBody RegionsRequest request) {
        profileService.updateRegions(userId, request.codes());
    }

    @GetMapping("/users/{id}/profile")
    public PublicProfileResponse userProfile(@PathVariable String id) {
        return profileService.getPublicProfile(id);
    }
}
