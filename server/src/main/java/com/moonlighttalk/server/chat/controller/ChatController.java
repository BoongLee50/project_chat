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


    /**
     * 음성 파일 업로드 자리 발급. 실제 바이트는 여기가 아니라 uploadUrl로 PUT한다.
     *
     * <p>올린 뒤 소켓 {@code CHAT_SEND}에 {@code type=VOICE}와 {@code audioKey}를 실어 보내면
     * 그때 메시지가 만들어진다. 업로드만 하고 보내지 않으면 파일만 남고 메시지는 안 생긴다.
     */
    @PostMapping("/chat/rooms/{roomId}/voice:upload-url")
    public UploadUrlResponse issueVoiceUploadUrl(
            @CurrentUserId String userId,
            @PathVariable String roomId,
            @RequestParam(defaultValue = "audio/mp4") String contentType) {
        return chatService.issueVoiceUploadUrl(userId, roomId, contentType);
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
