package com.moonlighttalk.server.profile.dto;

/** storageKey가 없으면(null) 프로필 사진 제거 */
public record RegisterProfilePhotoRequest(String storageKey) {
}
