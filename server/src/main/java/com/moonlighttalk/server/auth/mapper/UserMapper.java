package com.moonlighttalk.server.auth.mapper;

import com.moonlighttalk.server.auth.entity.User;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface UserMapper {

    User findByProvider(@Param("provider") String provider, @Param("providerUid") String providerUid);

    User findById(@Param("id") String id);

    void insert(User user);

    void updateProfile(@Param("id") String id,
                        @Param("nickname") String nickname,
                        @Param("birthYear") Integer birthYear,
                        @Param("gender") String gender,
                        @Param("country") String country);

    int countByNickname(@Param("nickname") String nickname);

    /** 마지막 접속 시각(V16). 하트비트마다가 아니라 눌러서 쓴다 — {@code LastSeenService}. */
    void touchLastSeen(@Param("id") String id, @Param("at") java.time.LocalDateTime at);
}
