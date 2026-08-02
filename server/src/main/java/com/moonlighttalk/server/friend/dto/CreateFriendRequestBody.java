package com.moonlighttalk.server.friend.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateFriendRequestBody(@NotBlank String targetUserId) {
}
