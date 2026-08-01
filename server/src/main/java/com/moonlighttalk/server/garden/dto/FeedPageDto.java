package com.moonlighttalk.server.garden.dto;

import java.util.List;

/** @param nextCursor 다음 페이지 커서(없으면 null = 끝) */
public record FeedPageDto(List<FeedItemDto> items, String nextCursor) {
}
