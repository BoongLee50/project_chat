package com.moonlighttalk.server.postinfo.controller;

import com.moonlighttalk.server.common.security.CurrentUserId;
import com.moonlighttalk.server.postinfo.dto.PostInfoDto;
import com.moonlighttalk.server.postinfo.service.PostInfoService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

/** [포스트 정보] 공통 화면(기획 6-1 · 7-1). 부르는 곳이 셋이라 응답도 하나로 둔다. */
@RestController
public class PostInfoController {

    private final PostInfoService postInfoService;

    public PostInfoController(PostInfoService postInfoService) {
        this.postInfoService = postInfoService;
    }

    @GetMapping("/users/{targetUserId}/post-info")
    public PostInfoDto postInfo(@CurrentUserId String userId,
                                 @PathVariable String targetUserId) {
        return postInfoService.get(userId, targetUserId);
    }
}
