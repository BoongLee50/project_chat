package com.moonlighttalk.server.post.service;

import com.moonlighttalk.server.auth.entity.User;
import com.moonlighttalk.server.auth.mapper.UserMapper;
import com.moonlighttalk.server.auth.service.GateService;
import com.moonlighttalk.server.common.exception.ApiException;
import com.moonlighttalk.server.common.response.ErrorCode;
import com.moonlighttalk.server.common.storage.FileStorageService;
import com.moonlighttalk.server.post.dto.MyPostResponse;
import com.moonlighttalk.server.post.dto.PostPhotoDto;
import com.moonlighttalk.server.post.dto.UploadUrlResponse;
import com.moonlighttalk.server.post.entity.Post;
import com.moonlighttalk.server.post.entity.PostPhoto;
import com.moonlighttalk.server.post.mapper.PostMapper;
import com.moonlighttalk.server.store.service.EntitlementService;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * 오늘의 포스트(기획서 3장, 01 문서 §1.3).
 *
 * <p>Plan_2 규칙
 * <ul>
 *   <li>등록/공유는 게이트(17~06시) 안에서만 가능</li>
 *   <li>일반 사용자: 첫 진입 후 <b>1시간</b> 동안만 등록, 사진 최대 <b>2장</b>, 교체 <b>2회</b></li>
 *   <li>프라임/앨범패스: 시간 제한 없음("PASS"), 사진 <b>8장</b>, 교체 <b>20회</b></li>
 *   <li>하루 한 마디는 1건만 유지(갱신), 최대 25자 — 06시 초기화 때도 유지</li>
 * </ul>
 *
 * <p>혜택 판정은 앨범패스 엔티틀먼트 기준(EntitlementService). 프라임 구독 시 함께 발급된다.
 * <p>(과거 메모) 개별 엔티틀먼트는
 * BM 테이블(02 문서 §1.7) 도입 후 반영한다.
 */
@Service
public class PostService {


    private final PostMapper postMapper;
    private final UserMapper userMapper;
    private final GateService gateService;
    private final FileStorageService fileStorageService;
    private final EntitlementService entitlementService;

    // 기획이 바꿀 수 있는 수치는 전부 설정으로 뺀다 — 값이 바뀌어도 코드 수정·배포가 없다.
    private final int maxPhotosFree;
    private final int maxPhotosPass;
    private final int replaceLimitFree;
    private final int replaceLimitPass;
    private final Duration uploadWindowFree;

    public PostService(PostMapper postMapper,
                        UserMapper userMapper,
                        GateService gateService,
                        FileStorageService fileStorageService,
                        EntitlementService entitlementService,
                        @Value("${app.post.max-photos-free:2}") int maxPhotosFree,
                        @Value("${app.post.max-photos-pass:8}") int maxPhotosPass,
                        @Value("${app.post.replace-limit-free:2}") int replaceLimitFree,
                        @Value("${app.post.replace-limit-pass:20}") int replaceLimitPass,
                        @Value("${app.post.upload-window-minutes:60}") int uploadWindowMinutes) {
        this.postMapper = postMapper;
        this.userMapper = userMapper;
        this.gateService = gateService;
        this.fileStorageService = fileStorageService;
        this.entitlementService = entitlementService;
        this.maxPhotosFree = maxPhotosFree;
        this.maxPhotosPass = maxPhotosPass;
        this.replaceLimitFree = replaceLimitFree;
        this.replaceLimitPass = replaceLimitPass;
        this.uploadWindowFree = Duration.ofMinutes(uploadWindowMinutes);
    }

    /** 오늘의 포스트 상태 조회. 첫 조회 시 등록 가능 창(1시간)이 시작된다. */
    @Transactional
    public MyPostResponse getMyPost(String userId) {
        Post post = getOrCreateTodayPost(userId);
        boolean unlimited = isUnlimited(userId);

        // 게이트가 열려 있고 아직 창이 시작되지 않았다면 지금부터 카운트.
        if (!unlimited && post.getWindowStartedAt() == null && gateService.isOpenNow()) {
            LocalDateTime now = gateService.nowKst().toLocalDateTime();
            postMapper.updateWindowStartedAt(post.getId(), now);
            post.setWindowStartedAt(now);
        }

        List<PostPhotoDto> photos = postMapper.selectPhotos(post.getId()).stream()
                .map(p -> new PostPhotoDto(p.getId(), fileStorageService.issueDownloadUrl(p.getStorageKey()), p.getOrderIdx()))
                .toList();

        return new MyPostResponse(
                post.getSessionDate(),
                gateService.isOpenNow(),
                photos,
                post.getOneLiner(),
                post.getPublishedAt() != null,
                unlimited ? null : remainingUploadSeconds(post),
                unlimited,
                unlimited ? maxPhotosPass : maxPhotosFree,
                Math.max(0, (unlimited ? replaceLimitPass : replaceLimitFree) - post.getReplaceCount())
        );
    }

    /** 사진 업로드 URL 발급(클라가 이 URL로 직접 업로드 후 등록 API 호출). */
    public UploadUrlResponse issuePhotoUploadUrl(String userId, String contentType) {
        requireGateOpen();
        LocalDate sessionDate = gateService.currentSessionDate();
        String storageKey = "posts/" + userId + "/" + sessionDate + "/" + UUID.randomUUID() + extensionOf(contentType);
        return new UploadUrlResponse(fileStorageService.issueUploadUrl(storageKey, contentType), storageKey);
    }

    /** 업로드 완료된 사진을 오늘의 포스트에 등록. */
    @Transactional
    public void registerPhoto(String userId, String storageKey) {
        requireGateOpen();
        Post post = getOrCreateTodayPost(userId);
        boolean unlimited = isUnlimited(userId);

        if (!unlimited && isUploadWindowExpired(post)) {
            throw new ApiException(ErrorCode.POST_UPLOAD_WINDOW_CLOSED, HttpStatus.CONFLICT,
                    "포스트 등록 가능 시간이 종료되었어요.");
        }

        int max = unlimited ? maxPhotosPass : maxPhotosFree;
        if (postMapper.countPhotos(post.getId()) >= max) {
            throw new ApiException(ErrorCode.POST_PHOTO_LIMIT, HttpStatus.CONFLICT,
                    "등록 가능한 포스트 사진 수를 초과했습니다. 기존 사진을 먼저 삭제 후 등록해 주세요.");
        }

        Integer maxOrder = postMapper.selectMaxOrderIdx(post.getId());
        PostPhoto photo = new PostPhoto();
        photo.setId(UUID.randomUUID().toString());
        photo.setPostId(post.getId());
        photo.setUserId(userId);
        photo.setStorageKey(storageKey);
        photo.setOrderIdx(maxOrder == null ? 0 : maxOrder + 1);
        postMapper.insertPhoto(photo);
        // 갱신 시각을 찍어야 나를 스킵했던 사람의 피드에 다시 뜬다(기획 4-1).
        postMapper.touchContentUpdatedAt(post.getId());
    }

    /** 사진 삭제(= 교체). 교체 횟수를 소모한다. */
    @Transactional
    public void deletePhoto(String userId, String photoId) {
        PostPhoto photo = postMapper.selectPhotoById(photoId);
        if (photo == null) {
            throw new ApiException(ErrorCode.POST_PHOTO_NOT_FOUND, HttpStatus.NOT_FOUND,
                    "사진을 찾을 수 없습니다.");
        }
        if (!photo.getUserId().equals(userId)) {
            throw new ApiException(ErrorCode.POST_PHOTO_NOT_MINE, HttpStatus.FORBIDDEN,
                    "내 사진만 삭제할 수 있습니다.");
        }

        Post post = getOrCreateTodayPost(userId);
        boolean unlimited = isUnlimited(userId);
        int limit = unlimited ? replaceLimitPass : replaceLimitFree;
        if (post.getReplaceCount() >= limit) {
            // 패스 보유자는 "오늘 한도 소진", 무료 사용자는 "패스를 사면 늘어난다"는
            // 서로 다른 안내다 — 코드도 나눠야 클라가 각각 번역할 수 있다.
            throw unlimited
                    ? new ApiException(ErrorCode.POST_REPLACE_LIMIT, HttpStatus.CONFLICT,
                            "오늘의 사진 교체 횟수를 모두 사용하였습니다. 내일 다시 이용해 주세요.")
                    : new ApiException(ErrorCode.POST_REPLACE_FREE_LIMIT, HttpStatus.CONFLICT,
                            "무료로 하루에 2장까지 교체할 수 있습니다. 포스트 앨범 패스를 이용하면 시간 제한 없이 하루 최대 20장까지 자유롭게 사진을 교체할 수 있습니다.");
        }

        postMapper.deletePhoto(photoId);
        postMapper.incrementReplaceCount(post.getId());
        postMapper.touchContentUpdatedAt(post.getId());
        fileStorageService.delete(photo.getStorageKey());
    }

    /** 하루 한 마디 등록/갱신(1건만 유지). */
    @Transactional
    public void updateOneLiner(String userId, String oneLiner) {
        Post post = getOrCreateTodayPost(userId);
        postMapper.updateOneLiner(post.getId(), oneLiner);
        postMapper.touchContentUpdatedAt(post.getId());
    }

    /** 포스트 공유하기 — 사진과 하루 한 마디가 모두 있어야 한다. */
    @Transactional
    public void publish(String userId) {
        requireGateOpen();
        Post post = getOrCreateTodayPost(userId);

        if (postMapper.countPhotos(post.getId()) == 0) {
            throw new ApiException(ErrorCode.POST_PHOTO_REQUIRED, HttpStatus.CONFLICT,
                    "새로운 포스트 사진을 등록해 주세요.");
        }
        if (post.getOneLiner() == null || post.getOneLiner().isBlank()) {
            throw new ApiException(ErrorCode.POST_ONELINER_REQUIRED, HttpStatus.CONFLICT,
                    "하루 한 마디를 입력해 주세요.");
        }

        postMapper.updatePublishedAt(post.getId(), gateService.nowKst().toLocalDateTime());
    }

    // ── 내부 ────────────────────────────────────────────────

    /**
     * 오늘 영업일의 포스트 row를 가져오되 없으면 만든다.
     * 하루 한 마디는 06시 초기화 후에도 유지되므로 직전 영업일 값을 이어받는다(기획서 3-1).
     */
    private Post getOrCreateTodayPost(String userId) {
        LocalDate sessionDate = gateService.currentSessionDate();
        Post post = postMapper.selectByUserAndDate(userId, sessionDate);
        if (post != null) {
            return post;
        }

        Post previous = postMapper.selectByUserAndDate(userId, sessionDate.minusDays(1));

        Post created = new Post();
        created.setId(UUID.randomUUID().toString());
        created.setUserId(userId);
        created.setSessionDate(sessionDate);
        created.setOneLiner(previous != null ? previous.getOneLiner() : null);
        created.setReplaceCount(0);
        postMapper.insertPost(created);
        return created;
    }

    /**
     * 사진 8장·시간 무제한·갤러리 업로드 대상인지. 판정 기준은 <b>앨범패스 엔티틀먼트</b>다
     * (프라임 구독 시 source=PRIME으로 함께 발급되므로 구독 여부를 따로 볼 필요가 없다 — 02 §1.7).
     * {@code users.is_premium}은 캐시/호환용이라 여기서 보지 않는다.
     */
    private boolean isUnlimited(String userId) {
        return entitlementService.hasAlbumPass(userId);
    }

    private boolean isUploadWindowExpired(Post post) {
        return remainingUploadSeconds(post) <= 0;
    }

    /** 남은 등록 가능 시간(초). 창이 아직 시작 전이면 전체 시간으로 본다. */
    private long remainingUploadSeconds(Post post) {
        if (post.getWindowStartedAt() == null) {
            return uploadWindowFree.toSeconds();
        }
        LocalDateTime expiresAt = post.getWindowStartedAt().plus(uploadWindowFree);
        long seconds = Duration.between(gateService.nowKst().toLocalDateTime(), expiresAt).toSeconds();
        return Math.max(0, seconds);
    }

    private void requireGateOpen() {
        if (!gateService.isOpenNow()) {
            throw new ApiException(ErrorCode.POST_GATE_CLOSED, HttpStatus.CONFLICT,
                    "지금은 포스트를 등록할 수 있는 시간이 아니에요.");
        }
    }

    private String extensionOf(String contentType) {
        if (contentType == null) {
            return "";
        }
        return switch (contentType) {
            case "image/png" -> ".png";
            case "image/webp" -> ".webp";
            default -> ".jpg";
        };
    }
}
