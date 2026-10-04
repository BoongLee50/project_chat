package com.moonlighttalk.server.profile.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserProfile {
    private String userId;
    /** 얼굴 사진 — 친구·대화 목록 같은 간략한 목록이 쓴다(기획서 261002 8-1 첫째 칸). */
    private String photoKey;
    /** 자유 사진 — [미리 보기]·[프로필 보기]의 큰 메인 사진(8-1 둘째 칸, V28). */
    private String mainPhotoKey;
    private String intro;
    private LocalDateTime updatedAt;
}
