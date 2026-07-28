package com.moonlighttalk.server.profile.mapper;

import com.moonlighttalk.server.profile.entity.UserProfile;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface ProfileMapper {

    void insertProfile(@Param("userId") String userId);

    UserProfile selectByUserId(@Param("userId") String userId);

    void updatePhotoKey(@Param("userId") String userId, @Param("photoKey") String photoKey);

    void updateIntro(@Param("userId") String userId, @Param("intro") String intro);

    List<String> selectInterests(@Param("userId") String userId);

    void deleteInterests(@Param("userId") String userId);

    void insertInterests(@Param("userId") String userId, @Param("codes") List<String> codes);

    List<String> selectRegions(@Param("userId") String userId);

    void deleteRegions(@Param("userId") String userId);

    void insertRegions(@Param("userId") String userId, @Param("codes") List<String> codes);
}
