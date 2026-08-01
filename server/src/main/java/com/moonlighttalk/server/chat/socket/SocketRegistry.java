package com.moonlighttalk.server.chat.socket;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

import java.io.IOException;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 접속 중인 소켓 세션 보관소(userId → 세션들). 한 사용자가 여러 기기로 붙을 수 있어 Set으로 관리.
 *
 * <p>단일 인스턴스 기준 인메모리. 서버를 여러 대로 늘리면 Redis Pub/Sub으로
 * 노드 간 브로드캐스트가 필요하다(05 문서 §4).
 */
@Component
public class SocketRegistry {

    private static final Logger log = LoggerFactory.getLogger(SocketRegistry.class);

    private final Map<String, Set<WebSocketSession>> sessionsByUser = new ConcurrentHashMap<>();
    private final ObjectMapper objectMapper;

    public SocketRegistry(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    public void register(String userId, WebSocketSession session) {
        sessionsByUser.computeIfAbsent(userId, k -> ConcurrentHashMap.newKeySet()).add(session);
    }

    public void unregister(String userId, WebSocketSession session) {
        if (userId == null) return;
        Set<WebSocketSession> sessions = sessionsByUser.get(userId);
        if (sessions == null) return;
        sessions.remove(session);
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
        if (sessions == null || sessions.isEmpty()) return;

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

    public void send(WebSocketSession session, Packet packet) {
        try {
            send(session, objectMapper.writeValueAsString(packet));
        } catch (IOException e) {
            log.warn("패킷 직렬화 실패: {}", packet.op(), e);
        }
    }

    private void send(WebSocketSession session, String payload) {
        if (!session.isOpen()) return;
        try {
            // WebSocketSession은 스레드 세이프하지 않아 세션 단위로 동기화한다.
            synchronized (session) {
                session.sendMessage(new TextMessage(payload));
            }
        } catch (IOException e) {
            log.debug("소켓 전송 실패(끊긴 세션): {}", session.getId());
        }
    }
}
