package com.moonlighttalk.server.chat.socket;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.ConcurrentWebSocketSessionDecorator;

import java.io.IOException;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 접속 중인 소켓 세션 보관소(userId → 세션들). 한 사용자가 여러 기기로 붙을 수 있어 Set으로 관리.
 *
 * <p>WebSocketSession은 동시 전송에 안전하지 않다. 실제로 자기 메시지의 ACK와 상대의 읽음
 * 영수증이 서로 다른 스레드에서 같은 세션에 동시에 쓰이면 세션이 깨진다. 그래서 등록 시
 * {@link ConcurrentWebSocketSessionDecorator}로 감싸 세션별 전송을 직렬화한다.
 *
 * <p>단일 인스턴스 기준 인메모리. 서버를 여러 대로 늘리면 Redis Pub/Sub으로
 * 노드 간 브로드캐스트가 필요하다(05 문서 §4).
 */
@Component
public class SocketRegistry {

    private static final Logger log = LoggerFactory.getLogger(SocketRegistry.class);

    /** 전송 대기 한도 — 넘으면 세션을 닫는다(느린 클라이언트가 서버 메모리를 먹지 않도록). */
    private static final int SEND_TIME_LIMIT_MS = 5_000;
    private static final int BUFFER_SIZE_LIMIT_BYTES = 128 * 1024;

    private final Map<String, Set<WebSocketSession>> sessionsByUser = new ConcurrentHashMap<>();
    /** 원본 세션 id → 직렬화 래퍼. 핸들러가 넘겨주는 원본 세션으로도 안전하게 보내기 위함. */
    private final Map<String, WebSocketSession> wrappers = new ConcurrentHashMap<>();
    private final ObjectMapper objectMapper;

    public SocketRegistry(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    public void register(String userId, WebSocketSession session) {
        WebSocketSession wrapper = new ConcurrentWebSocketSessionDecorator(
                session, SEND_TIME_LIMIT_MS, BUFFER_SIZE_LIMIT_BYTES);
        wrappers.put(session.getId(), wrapper);
        sessionsByUser.computeIfAbsent(userId, k -> ConcurrentHashMap.newKeySet()).add(wrapper);
    }

    public void unregister(String userId, WebSocketSession session) {
        WebSocketSession wrapper = wrappers.remove(session.getId());
        if (userId == null) return;
        Set<WebSocketSession> sessions = sessionsByUser.get(userId);
        if (sessions == null) return;
        sessions.remove(wrapper == null ? session : wrapper);
        if (sessions.isEmpty()) {
            sessionsByUser.remove(userId);
        }
    }

    public boolean isOnline(String userId) {
        Set<WebSocketSession> sessions = sessionsByUser.get(userId);
        return sessions != null && !sessions.isEmpty();
    }

    /** 특정 사용자의 모든 세션으로 패킷 전송(끊긴 세션은 조용히 무시). */
    public void sendTo(String userId, Packet packet) {
        Set<WebSocketSession> sessions = sessionsByUser.get(userId);
        if (sessions == null || sessions.isEmpty()) {
            log.debug("푸시 대상 없음 op={} userId={} (접속 중 아님)", packet.op(), userId);
            return;
        }
        log.debug("푸시 op={} userId={} 세션수={}", packet.op(), userId, sessions.size());

        String payload;
        try {
            payload = objectMapper.writeValueAsString(packet);
        } catch (IOException e) {
            log.warn("패킷 직렬화 실패: {}", packet.op(), e);
            return;
        }

        for (WebSocketSession session : sessions) {
            send(session, payload);
        }
    }

    /** 핸들러가 받은 원본 세션으로도 보낼 수 있게 래퍼를 찾아 사용한다. */
    public void send(WebSocketSession session, Packet packet) {
        try {
            send(wrappers.getOrDefault(session.getId(), session),
                    objectMapper.writeValueAsString(packet));
        } catch (IOException e) {
            log.warn("패킷 직렬화 실패: {}", packet.op(), e);
        }
    }

    private void send(WebSocketSession session, String payload) {
        if (!session.isOpen()) return;
        try {
            session.sendMessage(new TextMessage(payload));
        } catch (IOException | IllegalStateException e) {
            log.debug("소켓 전송 실패(끊긴 세션): {} / {}", session.getId(), e.toString());
        }
    }
}
