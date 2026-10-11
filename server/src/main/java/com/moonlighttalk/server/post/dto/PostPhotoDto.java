package com.moonlighttalk.server.post.dto;

/**
 * @param locked 무료로 돌아와 한도를 넘은 사진(기획서 261011 3-1) — 남에게 안 보이고 메인으로 세울 수 없다.
 *               유료를 다시 쓰면 풀린다.
 */
public record PostPhotoDto(String id, String url, int orderIdx, boolean locked) {
}
