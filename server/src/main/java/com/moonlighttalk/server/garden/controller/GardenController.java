package com.moonlighttalk.server.garden.controller;

import com.moonlighttalk.server.common.security.CurrentUserId;
import com.moonlighttalk.server.comment.dto.CommentDto;
import com.moonlighttalk.server.comment.dto.CreateCommentRequest;
import com.moonlighttalk.server.garden.dto.*;
import com.moonlighttalk.server.garden.service.GardenService;
import com.moonlighttalk.server.garden.service.TranslateAccessService;
import com.moonlighttalk.server.post.dto.UploadUrlResponse;
import jakarta.validation.Valid;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** 01 문서 §1.4 달빛가든(피드/댓글/번역) */
@RestController
public class GardenController {

    private final GardenService gardenService;
    private final TranslateAccessService translateAccess;

    public GardenController(GardenService gardenService,
                             TranslateAccessService translateAccess) {
        this.gardenService = gardenService;
        this.translateAccess = translateAccess;
    }

    @GetMapping("/feed")
    public FeedPageDto feed(
            @CurrentUserId String userId,
            @RequestParam(required = false) String gender,
            @RequestParam(required = false) Integer age,
            @RequestParam(required = false) String country,
            @RequestParam(required = false) String cursor) {
        return gardenService.feed(userId, gender, age, country, cursor);
    }

    @PostMapping("/feed/{targetUserId}/like")
    public void like(@CurrentUserId String userId, @PathVariable String targetUserId) {
        gardenService.like(userId, targetUserId);
    }

    @PostMapping("/feed/{targetUserId}/skip")
    public void skip(@CurrentUserId String userId, @PathVariable String targetUserId) {
        gardenService.skip(userId, targetUserId);
    }

    @GetMapping("/posts/{targetUserId}/comments")
    public List<CommentDto> comments(@PathVariable String targetUserId) {
        return gardenService.comments(targetUserId);
    }

    @PostMapping("/posts/{targetUserId}/comments")
    public void addComment(@CurrentUserId String userId,
                            @PathVariable String targetUserId,
                            @Valid @RequestBody CreateCommentRequest request) {
        gardenService.addComment(userId, targetUserId, request.body(),
                request.parentId(), request.imageKey());
    }

    /** 댓글 첨부 이미지 업로드 URL 발급(1장). 포스트 사진과 같은 흐름이다. */
    @PostMapping("/posts/comments/image:upload-url")
    public UploadUrlResponse issueCommentImageUploadUrl(
            @CurrentUserId String userId,
            @RequestParam(defaultValue = MediaType.IMAGE_JPEG_VALUE) String contentType) {
        return gardenService.issueCommentImageUploadUrl(userId, contentType);
    }

    /**
     * 댓글창을 열며 무료 자리를 하나 쓴다(기획 4-2 · 8-3 — "댓글창 5회 호출까지 무료").
     *
     * <p>포스트 댓글과 달빛 한마디가 같은 통을 쓴다 — 기획서의 두 문장이 글자까지 같다.
     */
    @PostMapping("/translate/comment-sheet")
    public TranslateAccessDto openCommentSheet(@CurrentUserId String userId) {
        return translateAccess.openCommentSheet(userId);
    }

    /** 자리를 쓰지 않고 상태만 본다 — `[번역 | …]` 버튼 문구를 그릴 때. */
    @GetMapping("/translate/comment-sheet")
    public TranslateAccessDto peekCommentSheet(@CurrentUserId String userId) {
        return translateAccess.peekCommentSheet(userId);
    }

    /**
     * 대화방에 들어가며 자리를 잡는다(기획 5장 — "대화방 5개까지, 삭제 전까지 계속").
     *
     * <p>이미 연 방이면 자리를 더 쓰지 않는다.
     */
    @PostMapping("/translate/rooms/{roomId}")
    public TranslateAccessDto openChatRoom(@CurrentUserId String userId,
                                            @PathVariable String roomId) {
        return translateAccess.openChatRoom(userId, roomId);
    }

    @PostMapping("/translate")
    public TranslateResponse translate(@CurrentUserId String userId,
                                        @Valid @RequestBody TranslateRequest request) {
        return gardenService.translate(userId, request);
    }
}
