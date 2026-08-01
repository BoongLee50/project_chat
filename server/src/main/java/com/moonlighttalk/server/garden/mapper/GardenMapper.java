package com.moonlighttalk.server.garden.mapper;

import com.moonlighttalk.server.garden.entity.FeedCandidate;
import com.moonlighttalk.server.garden.entity.PostComment;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDate;
import java.util.List;

@Mapper
public interface GardenMapper {

    /**
     * 피드 후보 조회 — 오늘 포스트를 공유했고, 차단/신고/스킵 대상이 아니며 필터에 맞는 사용자.
     * 스코어 계산과 정렬은 서비스에서 수행한다(접속 상태가 앱 메모리/Redis에 있으므로).
     */
    List<FeedCandidate> selectFeedCandidates(
            @Param("userId") String userId,
            @Param("sessionDate") LocalDate sessionDate,
            @Param("gender") String gender,
            @Param("country") String country,
            @Param("ageMin") Integer ageMin,
            @Param("ageMax") Integer ageMax,
            @Param("premiumOnly") boolean premiumOnly);

    /** 사진 URL 계산용 storage key 목록(노출 순서대로). */
    List<String> selectPhotoKeys(@Param("postId") String postId);

    /** 관심사(탭으로 추가 사진 검색 시 하루 한마디 대신 노출). */
    List<String> selectInterests(@Param("userId") String userId);

    /** 노출/좋아요/대화신청 카운터 원자적 증가(02 문서 §1.4). */
    void incrementStat(@Param("userId") String userId,
                        @Param("sessionDate") LocalDate sessionDate,
                        @Param("column") String column,
                        @Param("delta") int delta);

    /** 스킵 등록(중복이어도 에러 없이 무시). */
    void insertSkip(@Param("userId") String userId,
                     @Param("targetUserId") String targetUserId,
                     @Param("sessionDate") LocalDate sessionDate);

    /** 특정 사용자의 오늘 포스트 id(없으면 null). */
    String selectTodayPostId(@Param("userId") String userId, @Param("sessionDate") LocalDate sessionDate);

    List<PostComment> selectComments(@Param("postId") String postId);

    void insertComment(PostComment comment);

    int countComments(@Param("postId") String postId);

    /** 차단/신고로 상호작용이 막힌 상대인지. */
    boolean existsBlockOrReport(@Param("userId") String userId, @Param("targetUserId") String targetUserId);
}
