package com.moonlighttalk.server.garden.service;

import com.moonlighttalk.server.auth.service.SessionTimeService;
import com.moonlighttalk.server.common.exception.ApiException;
import com.moonlighttalk.server.common.response.ErrorCode;
import com.moonlighttalk.server.common.storage.FileStorageService;
import com.moonlighttalk.server.garden.config.GardenProperties;
import com.moonlighttalk.server.comment.dto.CommentDto;
import com.moonlighttalk.server.comment.dto.CommentTarget;
import com.moonlighttalk.server.comment.service.CommentService;
import com.moonlighttalk.server.garden.dto.*;
import com.moonlighttalk.server.garden.entity.FeedCandidate;
import com.moonlighttalk.server.garden.mapper.GardenMapper;
import com.moonlighttalk.server.post.dto.UploadUrlResponse;
import com.moonlighttalk.server.garden.translate.TranslationProvider;
import com.moonlighttalk.server.presence.PresenceService;
import com.moonlighttalk.server.store.service.EntitlementService;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

/**
 * 달빛가든(기획서 4장, 01 문서 §1.4).
 *
 * <p><b>Post Score</b> = Online + Recency + Engage (Plan_3 4-1). 수치는 전부
 * {@link GardenProperties}에 있다.
 * <ul>
 *   <li>Online — 접속 중 10 / 미접속 0</li>
 *   <li>Recency — 1시간 이내 30 / 1~3h 20 / 3~5h 10 / 5h 초과 0.
 *       기준 시각은 <b>공유 시각과 사진 갱신 시각 중 나중</b>이다("사진 갱신 시에도 적용")</li>
 *   <li>Engage — {(좋아요×1)+(댓글×2)+(대화신청×4)} / 노출 × 100 →
 *       30%↑ 30 / 20%↑ 20 / 15%↑ 15 / 10%↑ 10 / 5%↑ 5 / 그 외 0.
 *       <b>노출 20회 미만이면 0</b>(표본이 적으면 전환율이 요동친다)</li>
 * </ul>
 *
 * <p>🚨 <b>Plan_3에서 Pick Point(부스트 가점 50)가 사라졌다.</b> 부스트의 혜택은 점수가 아니라
 * <b>풀을 나누는 것</b>이다 — 일반 풀과 부스트 풀을 각각 정렬해 <b>6:4로 섞어</b> 내보낸다.
 * 부스트 풀이 훨씬 작으므로 그 안의 포스트 하나하나가 훨씬 자주 노출된다.
 * (광고 문구의 "10배"는 이론상 최대 배수일 뿐 계산식이 아니다 — docs/12 §6 B3)
 *
 * <p>순서는 <b>가든에 들어올 때 한 번</b> 정하고 그 세션 동안 유지한다({@link FeedSessionStore}).
 * 정렬을 SQL이 아니라 앱에서 하는 이유는 접속 상태가 DB가 아니라 프레즌스에 있기 때문이다.
 *
 * <p><b>열람 제한</b>(Plan_3 4-1) — 오늘 자기 포스트를 <b>공유까지</b> 하지 않은 무료 사용자는
 * 상대의 <b>메인 사진 1장만</b> 본다. 잘라내는 일은 반드시 <b>여기(서버)</b>에서 한다.
 * 화면에서만 가리면 API를 직접 부르는 것으로 뚫린다(함정 #18).
 */
@Service
public class GardenService {

    private static final int PAGE_SIZE = 10;

    private final GardenMapper gardenMapper;
    private final SessionTimeService sessionTime;
    private final PresenceService presenceService;
    private final FileStorageService fileStorageService;
    private final TranslationProvider translationProvider;
    private final EntitlementService entitlementService;
    private final CommentService commentService;

    /** 무료 번역 자리 판정 — 단위가 자리마다 달라 따로 산다(⑦단계). */
    private final TranslateAccessService translateAccess;


    /** 피드 스코어·믹싱 수치 — 운영하며 튜닝할 값이라 재배포 없이 바꿀 수 있어야 한다. */
    private final GardenProperties garden;
    private final FeedSessionStore feedSessions;

    public GardenService(GardenMapper gardenMapper,
                          SessionTimeService sessionTime,
                          PresenceService presenceService,
                          FileStorageService fileStorageService,
                          TranslationProvider translationProvider,
                          EntitlementService entitlementService,
                          CommentService commentService,
                          GardenProperties garden,
                          FeedSessionStore feedSessions,
                          TranslateAccessService translateAccess) {
        this.gardenMapper = gardenMapper;
        this.sessionTime = sessionTime;
        this.presenceService = presenceService;
        this.fileStorageService = fileStorageService;
        this.translationProvider = translationProvider;
        this.entitlementService = entitlementService;
        this.garden = garden;
        this.feedSessions = feedSessions;
        this.translateAccess = translateAccess;
        this.commentService = commentService;
    }

    /**
     * 피드 조회. 반환된 카드의 노출을 기록한다(전환율 분모 + 15분 제외).
     *
     * <p><b>순서는 진입할 때 한 번만 정한다.</b> 커서가 없으면 새로 산정하고, 있으면 그때의
     * 순서를 이어서 자른다. 매 요청 다시 섞던 때에는 페이지가 어긋나 본 카드가 또 나왔다
     * (07 §5-2 부채).
     *
     * @param age 연령대 앞자리(10/20/30/40), null이면 전체
     */
    @Transactional
    public FeedPageDto feed(String userId, String gender, Integer age, String country,
                             String cursor) {

        LocalDate sessionDate = sessionTime.currentSessionDate();
        String filterKey = filterKey(gender, age, country);
        int offset = parseCursor(cursor);

        // 커서가 없으면 "가든에 새로 들어온 것"이다 → 다시 산정한다.
        FeedSessionStore.Snapshot snapshot =
                offset == 0 ? null : feedSessions.get(userId, filterKey);
        if (snapshot == null) {
            snapshot = buildOrder(userId, sessionDate, gender, age, country, filterKey);
            offset = 0;
        }

        // 풀을 다 봤으면 처음부터 다시(기획 4-1). 옛 순서를 그대로 주면 방금 본 순서를 또 본다.
        if (offset >= snapshot.userIds().size() && !snapshot.userIds().isEmpty()) {
            feedSessions.clear(userId);
            snapshot = buildOrder(userId, sessionDate, gender, age, country, filterKey);
            offset = 0;
        }

        List<String> order = snapshot.userIds();
        List<String> pageIds = order.stream().skip(offset).limit(PAGE_SIZE).toList();
        if (pageIds.isEmpty()) {
            return new FeedPageDto(List.of(), null);
        }

        // 한 페이지분만 다시 읽는다 — 순서는 이미 정해져 있으니 후보 전체를 훑을 이유가 없다.
        Map<String, FeedCandidate> rows = new HashMap<>();
        for (FeedCandidate c : gardenMapper.selectCandidatesByIds(sessionDate, userId, pageIds)) {
            rows.put(c.getUserId(), c);
        }

        Set<String> boosted = new HashSet<>(entitlementService.boostedUserIds());
        // 꾸미기 외곽선은 **올린 사람**이 산 혜택이다(기획 화면 26·29).
        Set<String> decorated = new HashSet<>(
                entitlementService.userIdsWith(EntitlementService.ALBUM_PASS));
        boolean canViewAllPhotos = canViewAllPhotos(userId, sessionDate);

        List<FeedItemDto> items = new ArrayList<>();
        for (String targetId : pageIds) {
            FeedCandidate c = rows.get(targetId);
            if (c == null) {
                continue; // 순서를 정한 뒤 포스트가 내려갔다 — 조용히 건너뛴다
            }
            // 노출 집계와 15분 제외는 **보여준 순간** 찍는다. 스킵·좋아요에서 또 세면
            // 같은 한 번의 노출이 두 번 잡혀 전환율 분모가 부풀어 오른다.
            gardenMapper.incrementStat(targetId, sessionDate, "exposures", 1);
            gardenMapper.touchExposure(userId, targetId);
            items.add(toItem(c, score(c), boosted.contains(targetId),
                    decorated.contains(targetId), canViewAllPhotos));
        }

        int next = offset + pageIds.size();
        return new FeedPageDto(items, next < order.size() ? String.valueOf(next) : null);
    }

    /**
     * 노출 순서를 산정한다 — <b>일반 풀과 부스트 풀을 각각 정렬한 뒤 6:4로 섞는다</b>(기획 4-1).
     *
     * <p>부스트는 점수를 더 받는 게 아니라 <b>작은 풀에 들어간다.</b> 같은 비율로 섞이면
     * 풀이 작을수록 개별 포스트가 자주 뽑히고, 그것이 부스트가 파는 혜택의 실체다.
     */
    private FeedSessionStore.Snapshot buildOrder(String userId, LocalDate sessionDate,
                                                  String gender, Integer age, String country,
                                                  String filterKey) {
        Integer ageMin = age == null ? null : age;
        Integer ageMax = age == null ? null : age + 9;
        LocalDateTime cooldown = sessionTime.nowKst().toLocalDateTime()
                .minusMinutes(garden.getExposureCooldownMinutes());

        List<FeedCandidate> candidates = gardenMapper.selectFeedCandidates(
                userId, sessionDate, emptyToNull(gender), emptyToNull(country), ageMin, ageMax,
                false, cooldown);

        // 스킵은 "안 보여준다"가 아니라 **우선순위에서 뒤로 미룬다**는 뜻이다(기획 4-1).
        // 볼 게 다 떨어지면 스킵한 사람도, 방금 본 사람도 다시 넣는다 —
        // 그러지 않으면 사람이 적은 초기 서비스에서 피드가 금세 비어 버린다.
        if (candidates.isEmpty()) {
            candidates = gardenMapper.selectFeedCandidates(
                    userId, sessionDate, emptyToNull(gender), emptyToNull(country), ageMin, ageMax,
                    true, null);
        }

        Set<String> boosted = new HashSet<>(entitlementService.boostedUserIds());
        List<FeedCandidate> boostPool = new ArrayList<>();
        List<FeedCandidate> normalPool = new ArrayList<>();
        for (FeedCandidate c : candidates) {
            (boosted.contains(c.getUserId()) ? boostPool : normalPool).add(c);
        }

        List<String> ordered = mix(sortByScore(normalPool), sortByScore(boostPool));
        return feedSessions.put(userId, filterKey, ordered);
    }

    /** 스코어 내림차순. 동점은 랜덤 — 순서를 한 번만 정하므로 여기서 섞으면 그대로 고정된다. */
    private List<String> sortByScore(List<FeedCandidate> pool) {
        Map<String, Integer> scores = new HashMap<>();
        for (FeedCandidate c : pool) {
            scores.put(c.getUserId(), score(c));
        }
        List<FeedCandidate> copy = new ArrayList<>(pool);
        Collections.shuffle(copy);
        copy.sort(Comparator.comparingInt(
                (FeedCandidate c) -> scores.get(c.getUserId())).reversed());
        return copy.stream().map(FeedCandidate::getUserId).toList();
    }

    /**
     * 두 풀을 정해진 비율로 번갈아 담는다(기본 일반 6 : 부스트 4).
     *
     * <p><b>부스트 풀이 일반 풀보다 크거나 같으면 비율을 뒤집는다</b>(기획 4-1) —
     * 소수인 쪽이 항상 더 자주 나오게 하려는 규칙이다. 한쪽이 먼저 떨어지면 남은 쪽을 이어 붙인다.
     */
    private List<String> mix(List<String> normal, List<String> boost) {
        if (boost.isEmpty()) return normal;
        if (normal.isEmpty()) return boost;

        boolean boostIsBigger = boost.size() >= normal.size();
        int takeNormal = boostIsBigger ? garden.getMix().getBoost() : garden.getMix().getNormal();
        int takeBoost = boostIsBigger ? garden.getMix().getNormal() : garden.getMix().getBoost();

        List<String> mixed = new ArrayList<>(normal.size() + boost.size());
        int i = 0;
        int j = 0;
        while (i < normal.size() || j < boost.size()) {
            for (int k = 0; k < takeNormal && i < normal.size(); k++) mixed.add(normal.get(i++));
            for (int k = 0; k < takeBoost && j < boost.size(); k++) mixed.add(boost.get(j++));
        }
        return mixed;
    }

    /**
     * 상대의 사진을 전부 볼 수 있는가(Plan_3 4-1).
     *
     * <p>앨범패스·프라임은 무제한이고, 무료 사용자는 <b>오늘 자기 사진을 올리고
     * [공유하기]까지</b> 해야 열린다. 올리기만 한 상태는 열리지 않는다(docs/12 §6 B1).
     * 프라임은 구독 시 앨범패스 엔티틀먼트를 함께 받으므로 따로 볼 필요가 없다.
     *
     * <p>[포스트 정보] 화면도 <b>이 판정을 그대로</b> 부른다. 같은 규칙을 두 벌 만들면
     * 한쪽만 고쳐지고 다른 쪽이 뚫린 채 남는다.
     */
    public boolean canViewAllPhotos(String userId) {
        return canViewAllPhotos(userId, sessionTime.currentSessionDate());
    }

    private boolean canViewAllPhotos(String userId, LocalDate sessionDate) {
        if (entitlementService.hasAlbumPass(userId)) {
            return true;
        }
        return gardenMapper.existsPublishedPhotoToday(userId, sessionDate);
    }

    /** 같은 필터일 때만 순서를 이어 쓴다 — 필터가 바뀌면 보는 대상 자체가 달라진다. */
    private static String filterKey(String gender, Integer age, String country) {
        return emptyToNull(gender) + "|" + age + "|" + emptyToNull(country);
    }

    /**
     * 좋아요 — <b>한 사람이 한 포스트에 하루 한 번</b>(기획 4-1).
     *
     * <p>카운터만 올리던 때에는 같은 사람이 몇 번이고 누를 수 있었다. 누가 눌렀는지를
     * {@code post_likes}에 남겨 막는다(V15) — 달빛 한마디의 좋아요와 같은 방식이다.
     * 두 번째부터는 <b>조용히 아무 일도 하지 않는다</b> — 이미 누른 걸 다시 누른 것은
     * 실수가 아니라 그냥 같은 뜻이라 오류로 돌려줄 이유가 없다.
     */
    @Transactional
    public void like(String userId, String targetUserId) {
        LocalDate sessionDate = sessionTime.currentSessionDate();
        String postId = gardenMapper.selectTodayPostId(targetUserId, sessionDate);
        if (postId == null) {
            throw new ApiException(ErrorCode.POST_NOT_PUBLISHED_TODAY, HttpStatus.NOT_FOUND,
                    "오늘 등록된 포스트가 없어요.");
        }
        // 처음 누른 경우에만 전환율 분자를 올린다.
        if (gardenMapper.insertPostLike(postId, userId) > 0) {
            gardenMapper.incrementStat(targetUserId, sessionDate, "likes", 1);
        }
    }

    /** 스킵 — 당일 재노출 대상에서 제외. */
    @Transactional
    public void skip(String userId, String targetUserId) {
        gardenMapper.insertSkip(userId, targetUserId, sessionTime.currentSessionDate());
    }

    /** 포스트 댓글 목록(트리 순서). 규칙은 {@link CommentService}가 안다. */
    public List<CommentDto> comments(String targetUserId) {
        return commentService.list(CommentTarget.POST, requireTodayPostId(targetUserId));
    }

    /** 댓글 첨부 이미지 업로드 URL(1장). */
    public UploadUrlResponse issueCommentImageUploadUrl(String userId, String contentType) {
        return commentService.issueImageUploadUrl(userId, contentType);
    }

    /**
     * 포스트에 댓글/답글을 단다.
     *
     * <p>여기서 판단하는 것은 <b>포스트에 고유한 것</b> 둘뿐이다 —
     * 차단·신고 상대인지, 그리고 Engage 집계를 올리는 것.
     * 3단계·50자·이미지 규칙은 달빛 한마디와 공유하므로 {@link CommentService}가 가진다.
     */
    @Transactional
    public void addComment(String userId, String targetUserId, String body,
                            String parentId, String imageKey) {
        if (gardenMapper.existsBlockOrReport(userId, targetUserId)) {
            throw new ApiException(ErrorCode.GARDEN_TARGET_BLOCKED, HttpStatus.CONFLICT,
                    "현재 이 사용자에게 댓글을 남길 수 없어요.");
        }

        String postId = requireTodayPostId(targetUserId);
        // 글쓴이는 포스트 주인이다 — 답글은 그와 스레드 시작자가 번갈아 단다.
        commentService.add(CommentTarget.POST, postId, targetUserId, userId, body, parentId, imageKey);

        // Engage 전환율의 분자(댓글×2). **답글도 댓글로 센다** — 기획서가 나누지 않았고,
        // 대화가 이어지는 것도 반응이다.
        gardenMapper.incrementStat(targetUserId, sessionTime.currentSessionDate(), "comments", 1);
    }

    /**
     * 번역 — 자리(댓글창·대화방)는 <b>미리 잡혀 있다</b>(⑦단계, {@link TranslateAccessService}).
     *
     * <p>🚨 여기서는 더 이상 쿼터를 세지 않는다. 기획서의 무료 단위가
     * "번역 건수"가 아니라 <b>창 호출 / 방 수</b>이기 때문이다 —
     * 창 하나를 열면 그 안의 댓글은 몇 개든 번역된다. 요청마다 세면
     * 댓글이 열 개인 창 하나가 무료 다섯 자리를 다 먹는다.
     *
     * <p>자리를 잡지 않고 부르면 거절한다. 화면이 창을 열 때
     * {@code POST /translate/comment-sheet}(또는 {@code /translate/room})를 먼저 부른다.
     */
    @Transactional
    public TranslateResponse translate(String userId, TranslateRequest request) {
        String provider = translationProvider.name();

        // 프로필 보기는 쿼터 밖이다(기획 4-2).
        if (request.scope() == TranslateScope.PROFILE) {
            return TranslateResponse.unlimited(translated(request), provider);
        }

        TranslateAccessDto access = request.scope() == TranslateScope.CHAT
                ? translateAccess.openChatRoom(userId, requireTargetId(request))
                : translateAccess.peekCommentSheet(userId);

        if (!access.granted()) {
            throw quotaExceeded();
        }
        return access.unlimited()
                ? TranslateResponse.unlimited(translated(request), provider)
                : TranslateResponse.free(translated(request), provider, access.remaining());
    }

    private String requireTargetId(TranslateRequest request) {
        String targetId = request.targetId();
        if (targetId == null || targetId.isBlank()) {
            throw new ApiException(ErrorCode.TRANSLATE_TARGET_REQUIRED, HttpStatus.BAD_REQUEST,
                    "번역할 대화방을 지정해 주세요.", "targetId");
        }
        return targetId;
    }

    private ApiException quotaExceeded() {
        return new ApiException(ErrorCode.TRANSLATE_QUOTA_EXCEEDED, HttpStatus.CONFLICT,
                "오늘의 무료 번역을 모두 사용했어요. 자동 번역 패스를 이용해 보세요.");
    }

    private String translated(TranslateRequest request) {
        return translationProvider.translate(request.text(), request.targetLang());
    }

    // ── 내부 ────────────────────────────────────────────────

    /**
     * 카드 1건. <b>열람 제한은 여기서 실제로 잘라 낸다</b> — 잠긴 사진의 URL은 응답에 담기지 않는다.
     * 화면에서만 가리면 API를 직접 부르는 것으로 뚫린다(함정 #18).
     *
     * <p>{@code selectPhotoKeys}가 <b>메인을 첫 장</b>으로 주므로(②단계) 앞에서 1장만 자르면
     * 그게 곧 "메인 사진 1장"이다.
     */
    private FeedItemDto toItem(FeedCandidate c, int score, boolean boosted,
                                boolean decorated, boolean canViewAll) {
        List<String> keys = gardenMapper.selectPhotoKeys(c.getPostId());
        boolean locked = !canViewAll && keys.size() > 1;
        List<String> visible = locked ? keys.subList(0, 1) : keys;

        List<String> photoUrls = visible.stream()
                .map(fileStorageService::issueDownloadUrl)
                .toList();

        return new FeedItemDto(
                c.getUserId(),
                c.getNickname(),
                c.getBirthYear() == null ? null : sessionTime.nowKst().getYear() - c.getBirthYear(),
                c.getCountry(),
                boosted, // PICK 마크 = 부스트 활성 여부(점수 가점은 아니다)
                presenceService.isOnline(c.getUserId()),
                c.getIntro(),
                photoUrls,
                locked,
                keys.size(),
                gardenMapper.selectInterests(c.getUserId()),
                c.getLikes(),
                commentService.count(CommentTarget.POST, c.getPostId()),
                c.isLikedByMe(),
                c.getRegion(),
                decorated,
                score
        );
    }

    /** Post Score = Online + Recency + Engage (Plan_3 4-1). 부스트 가점은 없다. */
    private int score(FeedCandidate c) {
        int online = presenceService.isOnline(c.getUserId()) ? garden.getScoreOnline() : 0;
        return online + recencyScore(c) + engageScore(c);
    }

    /**
     * 얼마나 최근인가. 기준은 <b>공유 시각과 사진 갱신 시각 중 나중</b>이다 —
     * 기획서가 "사진 갱신 시에도 적용"이라고 못박았다. 공유만 하고 둔 포스트보다
     * 사진을 새로 올린 포스트가 위로 와야 한다.
     */
    private int recencyScore(FeedCandidate c) {
        LocalDateTime latest = c.getPublishedAt();
        if (latest == null || (c.getContentUpdatedAt() != null
                && c.getContentUpdatedAt().isAfter(latest))) {
            latest = c.getContentUpdatedAt();
        }
        if (latest == null) return 0;

        long hours = Duration.between(latest, sessionTime.nowKst().toLocalDateTime()).toHours();
        GardenProperties.Recency r = garden.getRecency();
        if (hours < 1) return r.getWithin1h();
        if (hours < 3) return r.getWithin3h();
        if (hours < 5) return r.getWithin5h();
        return 0;
    }

    /**
     * 전환율 = {(좋아요×1) + (댓글×2) + (대화신청×4)} / 총 노출 × 100 (기획서 4-1).
     *
     * <p><b>노출이 20회도 안 되면 0</b>이다. 표본이 적을 때 전환율은 한 번의 좋아요로
     * 100%가 되기도 해서, 갓 올린 포스트가 그것만으로 최상단에 올라가 버린다.
     */
    private int engageScore(FeedCandidate c) {
        GardenProperties.Engage e = garden.getEngage();
        if (c.getExposures() < e.getMinExposures()) return 0;

        double weighted = (double) c.getLikes() * e.getLikeWeight()
                + (double) c.getComments() * e.getCommentWeight()
                + (double) c.getRequests() * e.getRequestWeight();
        double rate = weighted / c.getExposures() * 100;

        if (rate >= 30) return e.getRate30();
        if (rate >= 20) return e.getRate20();
        if (rate >= 15) return e.getRate15();
        if (rate >= 10) return e.getRate10();
        if (rate >= 5) return e.getRate5();
        return 0;
    }

    private String requireTodayPostId(String targetUserId) {
        String postId = gardenMapper.selectTodayPostId(targetUserId, sessionTime.currentSessionDate());
        if (postId == null) {
            throw new ApiException(ErrorCode.POST_NOT_PUBLISHED_TODAY, HttpStatus.NOT_FOUND,
                    "오늘 등록된 포스트가 없어요.");
        }
        return postId;
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
