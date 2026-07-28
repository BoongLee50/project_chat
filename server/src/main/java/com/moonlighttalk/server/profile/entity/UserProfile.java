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
    private String photoKey;
    private String intro;
    private LocalDateTime updatedAt;
}
