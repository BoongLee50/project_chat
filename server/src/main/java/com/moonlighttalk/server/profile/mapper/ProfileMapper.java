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

    /**
     * 프로필 갱신 시각을 찍는다(V8).
     *
     * <p>사진·소개는 user_profiles를 직접 고치니 {@code ON UPDATE}가 알아서 찍지만,
     * <b>관심사·지역은 별도 테이블</b>이라 그것만으로는 안 잡힌다. 그래서 명시적으로 부른다.
     * 이 값이 나를 스킵한 사람의 피드에 다시 뜨는 기준이 된다(기획 4-1).
     */
    void touchUpdatedAt(@Param("userId") String userId);

    void deleteInterests(@Param("userId") String userId);

    void insertInterests(@Param("userId") String userId, @Param("codes") List<String> codes);

    List<String> selectRegions(@Param("userId") String userId);

    void deleteRegions(@Param("userId") String userId);

    void insertRegions(@Param("userId") String userId, @Param("codes") List<String> codes);
}
