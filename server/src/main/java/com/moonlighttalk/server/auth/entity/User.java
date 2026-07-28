package com.moonlighttalk.server.auth.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class User {
    private String id;
    private String provider;
    private String providerUid;
    private String nickname;      // 온보딩 전 NULL
    private Integer birthYear;
    private String gender;
    private String country;
    private String status;        // ACTIVE | SUSPENDED | BANNED
    private Boolean premium;
    private LocalDateTime premiumUntil;
    private LocalDateTime createdAt;

    public boolean isBanned() {
        return "BANNED".equals(status);
    }

    public boolean isProfileComplete() {
        return nickname != null;
    }
}
