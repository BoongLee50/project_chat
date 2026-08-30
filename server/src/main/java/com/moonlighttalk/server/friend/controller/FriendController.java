package com.moonlighttalk.server.friend.controller;

import com.moonlighttalk.server.common.security.CurrentUserId;
import com.moonlighttalk.server.friend.dto.AcceptFriendResponse;
import com.moonlighttalk.server.friend.dto.CreateFriendRequestBody;
import com.moonlighttalk.server.friend.dto.FriendDto;
import com.moonlighttalk.server.friend.dto.FriendPostDto;
import com.moonlighttalk.server.friend.dto.FriendRequestDto;
import com.moonlighttalk.server.friend.service.FriendService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** 01 문서 §1.7(친구). 친구는 양방향 — 요청 후 상대 수락으로 성립한다. */
@RestController
public class FriendController {

    private final FriendService friendService;

    public FriendController(FriendService friendService) {
        this.friendService = friendService;
    }

    /** 친구 목록(ACCEPTED). 필터는 모두 선택. */
    @GetMapping("/friends")
    public List<FriendDto> friends(@CurrentUserId String userId,
                                    @RequestParam(required = false) String gender,
                                    @RequestParam(required = false) Integer ageMin,
                                    @RequestParam(required = false) Integer ageMax,
                                    @RequestParam(required = false) String country) {
        return friendService.myFriends(userId, gender, ageMin, ageMax, country);
    }

    /** 내가 받은 친구 요청(PENDING). */
    @GetMapping("/friends/requests")
    public List<FriendRequestDto> received(@CurrentUserId String userId) {
        return friendService.receivedRequests(userId);
    }


    @PostMapping("/friends/requests")
    public AcceptFriendResponse request(@CurrentUserId String userId,
                                         @Valid @RequestBody CreateFriendRequestBody body) {
        return new AcceptFriendResponse(
                friendService.request(userId, body.targetUserId(), body.message()), null);
    }

    @PostMapping("/friends/requests/{friendshipId}:accept")
    public AcceptFriendResponse accept(@CurrentUserId String userId,
                                        @PathVariable String friendshipId) {
        return friendService.accept(userId, friendshipId);
    }

    @PostMapping("/friends/requests/{friendshipId}:reject")
    public void reject(@CurrentUserId String userId, @PathVariable String friendshipId) {
        friendService.reject(userId, friendshipId);
    }

    @PostMapping("/friends/requests/{friendshipId}:cancel")
    public void cancel(@CurrentUserId String userId, @PathVariable String friendshipId) {
        friendService.cancel(userId, friendshipId);
    }

    /** 친구 오늘의 포스트 팝업. 친구 관계 당사자만 볼 수 있다. */
    @GetMapping("/friends/{friendshipId}/today-post")
    public FriendPostDto todayPost(@CurrentUserId String userId,
                                    @PathVariable String friendshipId) {
        return friendService.todayPost(userId, friendshipId);
    }

    @DeleteMapping("/friends/{friendshipId}")
    public void remove(@CurrentUserId String userId, @PathVariable String friendshipId) {
        friendService.remove(userId, friendshipId);
    }
}
