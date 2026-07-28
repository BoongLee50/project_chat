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
}
