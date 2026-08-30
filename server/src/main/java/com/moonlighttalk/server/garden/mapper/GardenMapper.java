package com.moonlighttalk.server.garden.mapper;

import com.moonlighttalk.server.garden.entity.FeedCandidate;
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
            /// true면 내가 스킵한 상대도 후보에 넣는다(볼 게 다 떨어졌을 때).
            @Param("includeSkipped") boolean includeSkipped,
            /// 이 시각 이후에 이미 보여준 상대는 뺀다(15분 노출 제외). null이면 제외하지 않는다.
            @Param("exposedAfter") java.time.LocalDateTime exposedAfter);

    /**
     * 정해진 순서의 <b>한 페이지분</b>만 다시 읽는다.
     *
     * <p>순서는 진입할 때 한 번 산정해 두므로(FeedSessionStore) 페이지를 넘길 때마다
     * 후보 전체를 다시 훑을 이유가 없다. 반환 순서는 보장되지 않으니 호출부가 id로 정렬한다.
     */
    List<FeedCandidate> selectCandidatesByIds(
            @Param("sessionDate") LocalDate sessionDate,
            @Param("viewerId") String viewerId,
            @Param("ids") List<String> ids);

    /** 사진 URL 계산용 storage key 목록(노출 순서대로). */
    List<String> selectPhotoKeys(@Param("postId") String postId);

    /** 관심사(탭으로 추가 사진 검색 시 하루 한마디 대신 노출). */
    List<String> selectInterests(@Param("userId") String userId);

    /** 노출/좋아요/대화신청 카운터 원자적 증가(02 문서 §1.4). */
    void incrementStat(@Param("userId") String userId,
                        @Param("sessionDate") LocalDate sessionDate,
                        @Param("column") String column,
                        @Param("delta") int delta);

    /**
     * 노출 기록 — <b>마지막으로 보여준 시각을 덮어쓴다</b>(15분 제외 판정용, V12).
     * 이력이 아니라 최신값만 필요하므로 행이 늘지 않는다.
     */
    void touchExposure(@Param("userId") String userId,
                        @Param("targetUserId") String targetUserId);

    /**
     * 오늘 <b>공유까지 마친</b> 내 포스트에 사진이 한 장이라도 있는가.
     *
     * <p>달빛가든 열람 조건이다 — 올리기만 하고 [공유하기]를 안 했으면 열리지 않는다
     * (docs/12 §6 B1). 그래서 {@code published_at IS NOT NULL}을 함께 본다.
     */
    boolean existsPublishedPhotoToday(@Param("userId") String userId,
                                       @Param("sessionDate") LocalDate sessionDate);

    /**
     * 좋아요 기록. <b>이미 눌렀으면 0</b>을 돌려준다 — 그때는 카운터를 올리지 않는다.
     * (post_id가 영업일마다 새로 생기므로 이 PK가 곧 "하루 한 번"이다)
     *
     * @return 처음 눌렀으면 1, 이미 눌렀으면 0
     */
    int insertPostLike(@Param("postId") String postId, @Param("userId") String userId);

    /** 스킵 등록(중복이어도 에러 없이 무시). */
    void insertSkip(@Param("userId") String userId,
                     @Param("targetUserId") String targetUserId,
                     @Param("sessionDate") LocalDate sessionDate);

    /** 특정 사용자의 오늘 포스트 id(없으면 null). */
    String selectTodayPostId(@Param("userId") String userId, @Param("sessionDate") LocalDate sessionDate);


    /** 차단/신고로 상호작용이 막힌 상대인지. */
    boolean existsBlockOrReport(@Param("userId") String userId, @Param("targetUserId") String targetUserId);

    // ── 번역 무료 쿼터: 채팅 "하루 2명" (V7) ──────────────────────

    /** 오늘 번역을 연 상대 수. 행 하나가 사람 한 명이다. */
    int countTranslateTargets(
            @Param("userId") String userId, @Param("sessionDate") LocalDate sessionDate);

    /** 이 상대와는 오늘 이미 열었는지(열었으면 계속 무료). */
    boolean existsTranslateTarget(
            @Param("userId") String userId,
            @Param("sessionDate") LocalDate sessionDate,
            @Param("targetId") String targetId);

    /**
     * 상대를 기록한다. 이미 있으면 무시(동시 요청이 겹쳐도 사람 수가 늘지 않도록).
     *
     * @return 실제로 새로 기록됐으면 1, 이미 있었으면 0
     */
    int insertTranslateTarget(
            @Param("userId") String userId,
            @Param("sessionDate") LocalDate sessionDate,
            @Param("targetId") String targetId);
}
