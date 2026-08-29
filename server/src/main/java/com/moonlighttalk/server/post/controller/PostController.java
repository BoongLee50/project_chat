package com.moonlighttalk.server.post.controller;

import com.moonlighttalk.server.common.security.CurrentUserId;
import com.moonlighttalk.server.post.dto.MyPostResponse;
import com.moonlighttalk.server.post.dto.RegisterPhotoRequest;
import com.moonlighttalk.server.post.dto.UploadUrlResponse;
import com.moonlighttalk.server.post.service.PostService;
import jakarta.validation.Valid;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

/** 01 문서 §1.3 오늘의 포스트 */
@RestController
public class PostController {

    private final PostService postService;

    public PostController(PostService postService) {
        this.postService = postService;
    }

    @GetMapping("/posts/me")
    public MyPostResponse myPost(@CurrentUserId String userId) {
        return postService.getMyPost(userId);
    }

    @PostMapping("/posts/photos:upload-url")
    public UploadUrlResponse issueUploadUrl(
            @CurrentUserId String userId,
            @RequestParam(defaultValue = MediaType.IMAGE_JPEG_VALUE) String contentType) {
        return postService.issuePhotoUploadUrl(userId, contentType);
    }

    @PostMapping("/posts/photos")
    public void registerPhoto(@CurrentUserId String userId, @Valid @RequestBody RegisterPhotoRequest request) {
        postService.registerPhoto(userId, request.storageKey());
    }

    @DeleteMapping("/posts/photos/{photoId}")
    public void deletePhoto(@CurrentUserId String userId, @PathVariable String photoId) {
        postService.deletePhoto(userId, photoId);
    }

    /** 대표 사진 지정([메인] 버튼). 달빛가든에 이 사진이 노출된다. */
    @PostMapping("/posts/photos/{photoId}:main")
    public void setMainPhoto(@CurrentUserId String userId, @PathVariable String photoId) {
        postService.setMainPhoto(userId, photoId);
    }


    @PostMapping("/posts:publish")
    public void publish(@CurrentUserId String userId) {
        postService.publish(userId);
    }
}
