package com.moonlighttalk.server.friend.dto;

/** 친구 수락 결과 — 함께 만들어진(또는 승격된) 상시 대화방 id. */
public record AcceptFriendResponse(String friendshipId, String roomId) {
}
