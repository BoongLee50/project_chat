package com.moonlighttalk.server.chat.dto;

/** 음성 파일 업로드 자리. post·profile과 같은 모양이지만 도메인별로 따로 둔다. */
public record UploadUrlResponse(String uploadUrl, String storageKey) {
}
