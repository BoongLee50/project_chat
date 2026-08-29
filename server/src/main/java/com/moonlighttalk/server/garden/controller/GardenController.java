package com.moonlighttalk.server.garden.controller;

import com.moonlighttalk.server.common.security.CurrentUserId;
import com.moonlighttalk.server.garden.dto.*;
import com.moonlighttalk.server.garden.service.GardenService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** 01 문서 §1.4 달빛가든(피드/댓글/번역) */
@RestController
public class GardenController {

    private final GardenService gardenService;

    public GardenController(GardenService gardenService) {
        this.gardenService = gardenService;
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
        gardenService.addComment(userId, targetUserId, request.body());
    }

    @PostMapping("/translate")
    public TranslateResponse translate(@CurrentUserId String userId,
                                        @Valid @RequestBody TranslateRequest request) {
        return gardenService.translate(userId, request);
    }
}
