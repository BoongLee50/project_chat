package com.moonlighttalk.server.chat.socket;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.moonlighttalk.server.chat.dto.ChatMessageDto;
import com.moonlighttalk.server.chat.service.ChatService;
import com.moonlighttalk.server.common.exception.ApiException;
import com.moonlighttalk.server.common.security.JwtProvider;
import com.moonlighttalk.server.presence.LastSeenService;
import com.moonlighttalk.server.presence.PresenceService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.util.HashMap;
import java.util.Map;

/**
 * 채팅 WebSocket 핸들러 — 봉투 {@code {op, seq, ts, data}} 기반 커스텀 프로토콜(01 문서 §2).
 *
 * <p>핸드셰이크는 인증 없이 통과시키고(WebMvcConfig에서 {@code /ws/**} 제외),
 * 연결 직후 클라이언트가 보내는 {@code AUTH} 패킷으로 JWT를 검증한다.
 * 인증 전에는 AUTH/PING 외의 opcode를 처리하지 않는다.
 */
@Component
public class ChatWebSocketHandler extends TextWebSocketHandler {

    private static final Logger log = LoggerFactory.getLogger(ChatWebSocketHandler.class);
    private static final String ATTR_USER_ID = "userId";

    private final ObjectMapper objectMapper;
    private final JwtProvider jwtProvider;
    private final SocketRegistry registry;
    private final ChatService chatService;
    private final PresenceService presenceService;
    private final LastSeenService lastSeenService;

    public ChatWebSocketHandler(ObjectMapper objectMapper,
                                 JwtProvider jwtProvider,
                                 SocketRegistry registry,
                                 ChatService chatService,
                                 PresenceService presenceService,
                                 LastSeenService lastSeenService) {
        this.objectMapper = objectMapper;
        this.jwtProvider = jwtProvider;
        this.registry = registry;
        this.chatService = chatService;
        this.presenceService = presenceService;
        this.lastSeenService = lastSeenService;
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        JsonNode root;
        try {
            root = objectMapper.readTree(message.getPayload());
        } catch (Exception e) {
            sendError(session, null, "BAD_PACKET", "패킷을 해석할 수 없어요.");
            return;
        }

        String op = root.path("op").asText(null);
        Long seq = root.hasNonNull("seq") ? root.get("seq").asLong() : null;
        JsonNode data = root.path("data");
        String userId = userIdOf(session);

        if (op == null) {
            sendError(session, seq, "BAD_PACKET", "op이 없습니다.");
            return;
        }

        try {
            switch (op) {
                case Opcodes.AUTH -> handleAuth(session, seq, data);
                case Opcodes.PING -> {
                    if (userId != null) {
                        presenceService.heartbeat(userId);
                        // 60초 TTL의 프레즌스와 달리 이건 남는다 — 친구 목록의 "N시간 전 접속".
                        lastSeenService.touch(userId);
                    }
                    registry.send(session, Packet.of(Opcodes.PONG, seq, Map.of()));
                }
                case Opcodes.ROOM_SUBSCRIBE -> {
                    requireAuth(userId);
                    // 현재 보고 있는 방을 세션에 기록(향후 방별 최적화에 사용)
                    session.getAttributes().put("roomId", data.path("roomId").asText(null));
                    chatService.markRead(userId, data.path("roomId").asText());
                }
                case Opcodes.CHAT_SEND -> {
                    requireAuth(userId);
                    String roomId = data.path("roomId").asText();
                    // type이 없으면 TEXT다 — 구버전 클라가 보내던 봉투를 그대로 받기 위해서.
                    ChatMessageDto sent = "VOICE".equals(data.path("type").asText("TEXT"))
                            ? chatService.sendVoiceMessage(userId, roomId,
                                    data.path("audioKey").asText(null),
                                    data.path("audioDurationMs").asInt(0))
                            : chatService.sendMessage(userId, roomId, data.path("body").asText());
                    Map<String, Object> ack = new HashMap<>();
                    ack.put("messageId", sent.id());
                    ack.put("roomId", sent.roomId());
                    ack.put("type", sent.type());
                    ack.put("audioUrl", sent.audioUrl());
                    ack.put("audioDurationMs", sent.audioDurationMs());
                    ack.put("createdAt", sent.createdAt().toString());
                    registry.send(session, Packet.of(Opcodes.CHAT_SENT_ACK, seq, ack));
                }
                case Opcodes.CHAT_READ -> {
                    requireAuth(userId);
                    chatService.markRead(userId, data.path("roomId").asText());
                }
                default -> sendError(session, seq, "UNKNOWN_OP", "알 수 없는 op: " + op);
            }
        } catch (ApiException e) {
            sendError(session, seq, e.getCode().name(), e.getMessage());
        } catch (IllegalStateException e) {
            sendError(session, seq, "UNAUTHORIZED", e.getMessage());
        } catch (Exception e) {
            log.warn("소켓 처리 중 오류 op={}", op, e);
            sendError(session, seq, "INTERNAL_ERROR", "처리 중 문제가 발생했어요.");
        }
    }

    private void handleAuth(WebSocketSession session, Long seq, JsonNode data) {
        String token = data.path("accessToken").asText(null);
        try {
            String userId = jwtProvider.parseUserId(token);
            session.getAttributes().put(ATTR_USER_ID, userId);
            registry.register(userId, session);
            presenceService.heartbeat(userId);
            lastSeenService.touch(userId);
            log.info("소켓 인증 성공 userId={} session={}", userId, session.getId());
            registry.send(session, Packet.of(Opcodes.AUTH_OK, seq, Map.of("userId", userId)));
        } catch (RuntimeException e) {
            log.warn("소켓 인증 실패 session={} 사유={}", session.getId(), e.toString());
            registry.send(session, Packet.of(Opcodes.AUTH_FAIL, seq,
                    Map.of("code", "UNAUTHORIZED")));
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        log.info("소켓 종료 userId={} session={} status={}", userIdOf(session), session.getId(), status);
        registry.unregister(userIdOf(session), session);
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) {
        log.warn("소켓 전송 계층 오류 session={} : {}", session.getId(), exception.toString());
    }

    private void requireAuth(String userId) {
        if (userId == null) {
            throw new IllegalStateException("AUTH 패킷으로 먼저 인증해 주세요.");
        }
    }

    private String userIdOf(WebSocketSession session) {
        Object value = session.getAttributes().get(ATTR_USER_ID);
        return value == null ? null : value.toString();
    }

    private void sendError(WebSocketSession session, Long seq, String code, String message) {
        Map<String, Object> data = new HashMap<>();
        data.put("code", code);
        data.put("message", message);
        registry.send(session, Packet.of(Opcodes.ERROR, seq, data));
    }
}
