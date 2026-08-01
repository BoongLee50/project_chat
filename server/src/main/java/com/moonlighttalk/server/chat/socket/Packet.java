package com.moonlighttalk.server.chat.socket;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.Map;

/**
 * 소켓 공통 봉투 {@code { op, seq, ts, data }} (01 문서 §2.1).
 * 클라이언트의 packet.dart / opcodes.dart와 1:1 대응된다.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record Packet(String op, Long seq, Long ts, Map<String, Object> data) {

    public static Packet of(String op, Map<String, Object> data) {
        return new Packet(op, null, System.currentTimeMillis(), data);
    }

    public static Packet of(String op, Long seq, Map<String, Object> data) {
        return new Packet(op, seq, System.currentTimeMillis(), data);
    }
}
