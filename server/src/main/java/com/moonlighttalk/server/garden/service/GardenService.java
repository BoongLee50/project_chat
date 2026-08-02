package com.moonlighttalk.server.garden.service;

import com.moonlighttalk.server.auth.service.GateService;
import com.moonlighttalk.server.common.exception.ApiException;
import com.moonlighttalk.server.common.response.ErrorCode;
import com.moonlighttalk.server.common.storage.FileStorageService;
import com.moonlighttalk.server.garden.dto.*;
import com.moonlighttalk.server.garden.entity.FeedCandidate;
import com.moonlighttalk.server.garden.entity.PostComment;
import com.moonlighttalk.server.garden.mapper.GardenMapper;
import com.moonlighttalk.server.garden.translate.TranslationProvider;
import com.moonlighttalk.server.presence.PresenceService;
import com.moonlighttalk.server.store.service.EntitlementService;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

/**
 * 달빛가든(기획서 4장, 01 문서 §1.4).
 *
 * <p><b>Post Score</b> = Pick + Online + Recency + Engage
 * <ul>
 *   <li>Pick(부스팅) 50 — <b>부스트를 켜 둔 사용자</b>(boost_activations 미만료, 02 §1.7)</li>
 *   <li>Online 접속 중 10 / 미접속 0</li>
 *   <li>Recency 등록 1시간 이내 20 / 1~3시간 10 / 3시간 초과 0</li>
 *   <li>Engage 전환율 = (좋아요+대화신청)/노출×100×2 → 20%↑ 20, 15~19.9% 15, 10~14.9% 10, 5~9.9% 5, 그 외 0</li>
 * </ul>
 * 동점이면 랜덤. 정렬을 앱에서 하는 이유는 접속 상태가 DB가 아니라 프레즌스(인메모리/Redis)에 있기 때문.
 *
 * <p>게이트(17~06시) 밖에서는 달빛가든만 잠긴다(기획서 1장).
 */
@Service
public class GardenService {

    private static final int PAGE_SIZE = 10;
    private static final int SCORE_PICK = 50;
    private static final int SCORE_ONLINE = 10;

    private final GardenMapper gardenMapper;
    private final GateService gateService;
    private final PresenceService presenceService;
    private final FileStorageService fileStorageService;
    private final TranslationProvider translationProvider;
    private final EntitlementService entitlementService;

    public GardenService(GardenMapper gardenMapper,
                          GateService gateService,
                          PresenceService presenceService,
                          FileStorageService fileStorageService,
                          TranslationProvider translationProvider,
                          EntitlementService entitlementService) {
        this.gardenMapper = gardenMapper;
        this.gateService = gateService;
        this.presenceService = presenceService;
        this.fileStorageService = fileStorageService;
        this.translationProvider = translationProvider;
        this.entitlementService = entitlementService;
    }

    /**
     * 피드 조회. 반환된 카드의 노출 수를 증가시킨다(전환율 분모).
     *
     * @param age 연령대 앞자리(10/20/30/40), null이면 전체
     * @param spotlight 스포트라이트 — 부스팅 사용자만
     */
    @Transactional
    public FeedPageDto feed(String userId, String gender, Integer age, String country,
                             String cursor, boolean spotlight) {
        requireGateOpen();

        LocalDate sessionDate = gateService.currentSessionDate();
        Integer ageMin = age == null ? null : age;
        Integer ageMax = age == null ? null : age + 9;

        List<FeedCandidate> candidates = gardenMapper.selectFeedCandidates(
                userId, sessionDate, emptyToNull(gender), emptyToNull(country), ageMin, ageMax, spotlight);

        // Pick Point는 "지금 부스트를 켠 사람"에게 준다(02 §1.7). 한 번만 조회해 재사용.
        Set<String> boosted = new HashSet<>(entitlementService.boostedUserIds());

        // 스코어 계산 후 내림차순 정렬(동점은 랜덤).
        Map<String, Integer> scores = new HashMap<>();
        for (FeedCandidate c : candidates) {
            scores.put(c.getUserId(), score(c, boosted.contains(c.getUserId())));
        }
        Collections.shuffle(candidates);
        candidates.sort(Comparator.comparingInt(
                (FeedCandidate c) -> scores.get(c.getUserId())).reversed());

        int offset = parseCursor(cursor);
        List<FeedCandidate> page = candidates.stream().skip(offset).limit(PAGE_SIZE).toList();

        List<FeedItemDto> items = new ArrayList<>();
        for (FeedCandidate c : page) {
            gardenMapper.incrementStat(c.getUserId(), sessionDate, "exposures", 1);
            items.add(toItem(c, scores.get(c.getUserId()), boosted.contains(c.getUserId())));
        }

        boolean hasMore = offset + page.size() < candidates.size();
        return new FeedPageDto(items, hasMore ? String.valueOf(offset + page.size()) : null);
    }

    /** 좋아요 +1(전환율 분자). */
    @Transactional
    public void like(String userId, String targetUserId) {
        requireGateOpen();
        gardenMapper.incrementStat(targetUserId, gateService.currentSessionDate(), "likes", 1);
    }

    /** 스킵 — 당일 재노출 대상에서 제외. */
    @Transactional
    public void skip(String userId, String targetUserId) {
        requireGateOpen();
        gardenMapper.insertSkip(userId, targetUserId, gateService.currentSessionDate());
    }

    public List<CommentDto> comments(String targetUserId) {
        String postId = requireTodayPostId(targetUserId);
        return gardenMapper.selectComments(postId).stream()
                .map(c -> new CommentDto(c.getId(), c.getAuthorId(), c.getAuthorNickname(),
                        c.getBody(), c.getCreatedAt()))
                .toList();
    }

    @Transactional
    public void addComment(String userId, String targetUserId, String body) {
        requireGateOpen();
        if (gardenMapper.existsBlockOrReport(userId, targetUserId)) {
            throw new ApiException(ErrorCode.TARGET_BLOCKED_OR_REPORTED, HttpStatus.CONFLICT,
                    "현재 이 사용자에게 댓글을 남길 수 없어요.");
        }

        String postId = requireTodayPostId(targetUserId);
        PostComment comment = new PostComment();
        comment.setId(UUID.randomUUID().toString());
        comment.setPostId(postId);
        comment.setAuthorId(userId);
        comment.setBody(body);
        gardenMapper.insertComment(comment);
    }

    /** 번역 — 키 미설정 시 원문을 그대로 반환(패스스루). */
    public TranslateResponse translate(String text, String targetLang) {
        return new TranslateResponse(
                translationProvider.translate(text, targetLang),
                translationProvider.name());
    }

    // ── 내부 ────────────────────────────────────────────────

    private FeedItemDto toItem(FeedCandidate c, int score, boolean boosted) {
        List<String> photoUrls = gardenMapper.selectPhotoKeys(c.getPostId()).stream()
                .map(fileStorageService::issueDownloadUrl)
                .toList();

        return new FeedItemDto(
                c.getUserId(),
                c.getNickname(),
                c.getBirthYear() == null ? null : gateService.nowKst().getYear() - c.getBirthYear(),
                c.getCountry(),
                boosted, // PICK 마크 = 부스트 활성 여부
                presenceService.isOnline(c.getUserId()),
                c.getOneLiner(),
                photoUrls,
                gardenMapper.selectInterests(c.getUserId()),
                c.getLikes(),
                gardenMapper.countComments(c.getPostId()),
                score
        );
    }

    private int score(FeedCandidate c, boolean boosted) {
        int pick = boosted ? SCORE_PICK : 0;
        int online = presenceService.isOnline(c.getUserId()) ? SCORE_ONLINE : 0;
        return pick + online + recencyScore(c.getPublishedAt()) + engageScore(c);
    }

    private int recencyScore(LocalDateTime publishedAt) {
        if (publishedAt == null) return 0;
        long hours = Duration.between(publishedAt, gateService.nowKst().toLocalDateTime()).toHours();
        if (hours < 1) return 20;
        if (hours <= 3) return 10;
        return 0;
    }

    /** 전환율 = {(좋아요 + 대화신청) / 노출 × 100} × 2 (기획서 4-1). */
    private int engageScore(FeedCandidate c) {
        if (c.getExposures() <= 0) return 0;
        double rate = ((double) (c.getLikes() + c.getRequests()) / c.getExposures()) * 100 * 2;
        if (rate >= 20) return 20;
        if (rate >= 15) return 15;
        if (rate >= 10) return 10;
        if (rate >= 5) return 5;
        return 0;
    }

    private String requireTodayPostId(String targetUserId) {
        String postId = gardenMapper.selectTodayPostId(targetUserId, gateService.currentSessionDate());
        if (postId == null) {
            throw new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "오늘 등록된 포스트가 없어요.");
        }
        return postId;
    }

    private void requireGateOpen() {
        if (!gateService.isOpenNow()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.CONFLICT,
                    "달빛가든은 아직 문을 열지 않았어요. 달빛이 찾아오는 오후 5시부터 다음날 오전 6시까지 이용할 수 있습니다.");
        }
    }

    private static String emptyToNull(String value) {
        return (value == null || value.isBlank()) ? null : value;
    }

    private static int parseCursor(String cursor) {
        if (cursor == null || cursor.isBlank()) return 0;
        try {
            return Math.max(0, Integer.parseInt(cursor));
        } catch (NumberFormatException e) {
            return 0;
        }
    }
}
