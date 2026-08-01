package com.moonlighttalk.server.chat.controller;

import com.moonlighttalk.server.chat.dto.*;
import com.moonlighttalk.server.chat.service.ChatService;
import com.moonlighttalk.server.common.security.CurrentUserId;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** 01 문서 §1.5(대화 신청) · §1.6(대화방) */
@RestController
public class ChatController {

    private final ChatService chatService;

    public ChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    @PostMapping("/chat-requests")
    public void createRequest(@CurrentUserId String userId,
                               @Valid @RequestBody CreateChatRequestBody request) {
        chatService.createRequest(userId, request.targetUserId(), request.message());
    }

    /** 매칭 대화 목록. */
    @GetMapping("/chat/rooms")
    public List<ChatRoomDto> rooms(@CurrentUserId String userId) {
        return chatService.myRooms(userId);
    }

    /** 내가 받은 신청(대기 중). */
    @GetMapping("/chat/rooms/received")
    public List<ChatRequestDto> received(@CurrentUserId String userId) {
        return chatService.receivedRequests(userId);
    }

    /** 내가 보낸 신청. */
    @GetMapping("/chat/rooms/sent")
    public List<ChatRequestDto> sent(@CurrentUserId String userId) {
        return chatService.sentRequests(userId);
    }

    @GetMapping("/chat/rooms/{roomId}/messages")
    public MessagePageDto messages(@CurrentUserId String userId,
                                    @PathVariable String roomId,
                                    @RequestParam(required = false) String cursor) {
        return chatService.messages(userId, roomId, cursor);
    }

    @PostMapping("/chat/requests/{requestId}:accept")
    public AcceptResponse accept(@CurrentUserId String userId, @PathVariable String requestId) {
        return new AcceptResponse(chatService.acceptRequest(userId, requestId));
    }

    @PostMapping("/chat/requests/{requestId}:reject")
    public void reject(@CurrentUserId String userId, @PathVariable String requestId) {
        chatService.rejectRequest(userId, requestId);
    }

    @PostMapping("/chat/rooms/{roomId}:leave")
    public void leave(@CurrentUserId String userId, @PathVariable String roomId) {
        chatService.leaveRoom(userId, roomId);
    }
}
