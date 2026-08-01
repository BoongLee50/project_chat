package com.moonlighttalk.server.chat.socket;

/** 소켓 opcode (01 문서 §2.2). */
public final class Opcodes {

    private Opcodes() {
    }

    // C → S
    public static final String AUTH = "AUTH";
    public static final String PING = "PING";
    public static final String ROOM_SUBSCRIBE = "ROOM_SUBSCRIBE";
    public static final String CHAT_SEND = "CHAT_SEND";
    public static final String CHAT_READ = "CHAT_READ";

    // S → C
    public static final String AUTH_OK = "AUTH_OK";
    public static final String AUTH_FAIL = "AUTH_FAIL";
    public static final String PONG = "PONG";
    public static final String CHAT_SENT_ACK = "CHAT_SENT_ACK";
    public static final String CHAT_RECV = "CHAT_RECV";
    public static final String CHAT_READ_RECEIPT = "CHAT_READ_RECEIPT";
    public static final String CHAT_REQ_INCOMING = "CHAT_REQ_INCOMING";
    public static final String ROOM_STATE = "ROOM_STATE";
    public static final String PRESENCE_UPDATE = "PRESENCE_UPDATE";
    public static final String UNREAD_COUNT = "UNREAD_COUNT";
    public static final String SYSTEM_CLOSE = "SYSTEM_CLOSE";
    public static final String ERROR = "ERROR";
}
