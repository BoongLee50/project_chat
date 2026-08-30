package com.moonlighttalk.server.post.service;

import com.moonlighttalk.server.auth.entity.User;
import com.moonlighttalk.server.auth.mapper.UserMapper;
import com.moonlighttalk.server.auth.service.SessionTimeService;
import com.moonlighttalk.server.common.exception.ApiException;
import com.moonlighttalk.server.common.response.ErrorCode;
import com.moonlighttalk.server.common.storage.FileStorageService;
import com.moonlighttalk.server.post.dto.MyPostResponse;
import com.moonlighttalk.server.post.dto.PostPhotoDto;
import com.moonlighttalk.server.post.dto.UploadUrlResponse;
import com.moonlighttalk.server.post.entity.Post;
import com.moonlighttalk.server.post.entity.PostPhoto;
import com.moonlighttalk.server.comment.dto.CommentTarget;
import com.moonlighttalk.server.comment.service.CommentService;
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
 * <p>Plan_3 규칙
 * <ul>
 *   <li>영업일(KST 18시 경계) 안이면 <b>언제든</b> 등록·공유할 수 있다(운영시간 폐지)</li>
 *   <li>사진: 무료 <b>2장</b> / 앨범패스 <b>9장</b>, 교체는 양쪽 다 <b>3회</b></li>
 *   <li><b>메인 사진</b> 한 장을 골라 달빛가든에 노출한다 — 최초 사진은 자동 메인,
 *       메인을 지우면 이웃 슬롯이 승계된다</li>
 *   <li>표시 순서는 <b>최신이 1번 슬롯</b>이다</li>
 * </ul>
 *
 * <p>혜택 판정은 앨범패스 엔티틀먼트 기준(EntitlementService). 프라임 구독 시 함께 발급된다.
 */
@Service
public class PostService {


    private final PostMapper postMapper;
    private final UserMapper userMapper;
    private final SessionTimeService sessionTime;
    private final FileStorageService fileStorageService;
    private final EntitlementService entitlementService;
    private final CommentService commentService;

    // 기획이 바꿀 수 있는 수치는 전부 설정으로 뺀다 — 값이 바뀌어도 코드 수정·배포가 없다.
    // 등록 창(1시간)은 Plan_3에서 폐지됐다. 이제 영업일 안이면 언제든 올릴 수 있다.
    private final int maxPhotosFree;
    private final int maxPhotosPass;
    private final int replaceLimitFree;
    private final int replaceLimitPass;

    public PostService(PostMapper postMapper,
                        UserMapper userMapper,
                        SessionTimeService sessionTime,
                        FileStorageService fileStorageService,
                        EntitlementService entitlementService,
                        CommentService commentService,
                        @Value("${app.post.max-photos-free:2}") int maxPhotosFree,
                        @Value("${app.post.max-photos-pass:9}") int maxPhotosPass,
                        @Value("${app.post.replace-limit-free:3}") int replaceLimitFree,
                        @Value("${app.post.replace-limit-pass:3}") int replaceLimitPass) {
        this.postMapper = postMapper;
        this.userMapper = userMapper;
        this.sessionTime = sessionTime;
        this.fileStorageService = fileStorageService;
        this.entitlementService = entitlementService;
        this.commentService = commentService;
        this.maxPhotosFree = maxPhotosFree;
        this.maxPhotosPass = maxPhotosPass;
        this.replaceLimitFree = replaceLimitFree;
        this.replaceLimitPass = replaceLimitPass;
    }

    /** 오늘의 포스트 상태 조회. */
    @Transactional
    public MyPostResponse getMyPost(String userId) {
        Post post = getOrCreateTodayPost(userId);
        boolean unlimited = isUnlimited(userId);

        List<PostPhoto> rows = postMapper.selectPhotos(post.getId());
        List<PostPhotoDto> photos = rows.stream()
                .map(p -> new PostPhotoDto(p.getId(), fileStorageService.issueDownloadUrl(p.getStorageKey()), p.getOrderIdx()))
                .toList();

        return new MyPostResponse(
                post.getSessionDate(),
                photos,
                resolveMainPhotoId(post, rows),
                post.getPublishedAt() != null,
                // 화면(3-1)에 "달빛가든에서 받은 좋아요·댓글"을 보여준다.
                postMapper.selectLikes(userId, post.getSessionDate()),
                commentService.count(CommentTarget.POST, post.getId()),
                unlimited ? maxPhotosPass : maxPhotosFree,
                Math.max(0, (unlimited ? replaceLimitPass : replaceLimitFree) - post.getReplaceCount())
        );
    }

    /** 사진 업로드 URL 발급(클라가 이 URL로 직접 업로드 후 등록 API 호출). */
    public UploadUrlResponse issuePhotoUploadUrl(String userId, String contentType) {
        LocalDate sessionDate = sessionTime.currentSessionDate();
        String storageKey = "posts/" + userId + "/" + sessionDate + "/" + UUID.randomUUID() + extensionOf(contentType);
        return new UploadUrlResponse(fileStorageService.issueUploadUrl(storageKey, contentType), storageKey);
    }

    /** 업로드 완료된 사진을 오늘의 포스트에 등록. */
    @Transactional
    public void registerPhoto(String userId, String storageKey) {
        Post post = getOrCreateTodayPost(userId);
        boolean unlimited = isUnlimited(userId);

        int max = unlimited ? maxPhotosPass : maxPhotosFree;
        if (postMapper.countPhotos(post.getId()) >= max) {
            // 숫자는 설정값이라 언제든 바뀐다 — 문구에 굳히지 않고 field로 실어 보낸다.
            throw new ApiException(ErrorCode.POST_PHOTO_LIMIT, HttpStatus.CONFLICT,
                    "등록 가능한 포스트 사진 수를 초과했습니다. 기존 사진을 먼저 삭제 후 등록해 주세요.",
                    String.valueOf(max));
        }

        Integer maxOrder = postMapper.selectMaxOrderIdx(post.getId());
        PostPhoto photo = new PostPhoto();
        photo.setId(UUID.randomUUID().toString());
        photo.setPostId(post.getId());
        photo.setUserId(userId);
        photo.setStorageKey(storageKey);
        photo.setOrderIdx(maxOrder == null ? 0 : maxOrder + 1);
        postMapper.insertPhoto(photo);

        // "최초 사진은 자동 메인"(Plan_3 §3-1).
        // 저장된 id가 떠 있는 경우도 "메인이 없다"로 보고 새 사진을 세운다.
        if (storedMainIfValid(post, postMapper.selectPhotos(post.getId())) == null) {
            postMapper.updateMainPhotoId(post.getId(), photo.getId());
        }

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
            // Plan_3에서 무료·유료가 같은 3회가 됐지만 **코드는 계속 나눠 둔다** —
            // 다시 갈릴 수 있고(docs/12 §6 B4), 그때 문구만 갈라지면 되기 때문이다.
            throw new ApiException(
                    unlimited ? ErrorCode.POST_REPLACE_LIMIT : ErrorCode.POST_REPLACE_FREE_LIMIT,
                    HttpStatus.CONFLICT,
                    "오늘의 사진 교체 횟수를 모두 사용하였습니다. 내일 다시 이용해 주세요.",
                    String.valueOf(limit));
        }

        // 메인을 지우면 이웃 슬롯이 승계한다 — 사진이 남아 있는 한 메인이 비지 않는다.
        // 지우기 **전에** 목록을 떠 둬야 "어느 슬롯 옆이었는지"를 알 수 있다.
        List<PostPhoto> before = postMapper.selectPhotos(post.getId());

        postMapper.deletePhoto(photoId);
        postMapper.incrementReplaceCount(post.getId());

        if (photoId.equals(resolveMainPhotoId(post, before))) {
            postMapper.updateMainPhotoId(post.getId(), successorOf(before, photoId));
        }

        postMapper.touchContentUpdatedAt(post.getId());
        fileStorageService.delete(photo.getStorageKey());
    }

    /**
     * 대표 사진 지정([메인] 버튼). 달빛가든에 이 사진이 노출된다(Plan_3 §3-1).
     *
     * <p>③단계의 열람 제한("무료 사용자는 상대의 메인 사진 1장만")이 이 값 위에 얹히므로
     * <b>남의 사진이나 지난 영업일 사진을 세울 수 없어야 한다</b> — 둘 다 확인한다.
     */
    @Transactional
    public void setMainPhoto(String userId, String photoId) {
        PostPhoto photo = postMapper.selectPhotoById(photoId);
        if (photo == null) {
            throw new ApiException(ErrorCode.POST_PHOTO_NOT_FOUND, HttpStatus.NOT_FOUND,
                    "사진을 찾을 수 없습니다.");
        }
        if (!photo.getUserId().equals(userId)) {
            throw new ApiException(ErrorCode.POST_PHOTO_NOT_MINE, HttpStatus.FORBIDDEN,
                    "내 사진만 메인으로 지정할 수 있습니다.");
        }

        Post post = getOrCreateTodayPost(userId);
        if (!photo.getPostId().equals(post.getId())) {
            // 어제 포스트의 사진을 오늘의 대표로 세우면 영업일 경계가 무너진다.
            throw new ApiException(ErrorCode.POST_PHOTO_NOT_MINE, HttpStatus.FORBIDDEN,
                    "오늘의 포스트 사진만 메인으로 지정할 수 있습니다.");
        }

        postMapper.updateMainPhotoId(post.getId(), photoId);
        postMapper.touchContentUpdatedAt(post.getId());
    }

    /** 포스트 공유하기 — 사진이 있어야 한다(Plan_3에서 하루 한 마디가 폐지됐다). */
    @Transactional
    public void publish(String userId) {
        Post post = getOrCreateTodayPost(userId);

        if (postMapper.countPhotos(post.getId()) == 0) {
            throw new ApiException(ErrorCode.POST_PHOTO_REQUIRED, HttpStatus.CONFLICT,
                    "새로운 포스트 사진을 등록해 주세요.");
        }
        postMapper.updatePublishedAt(post.getId(), sessionTime.nowKst().toLocalDateTime());
    }

    // ── 내부 ────────────────────────────────────────────────

    /** 오늘 영업일의 포스트 row를 가져오되 없으면 만든다. */
    private Post getOrCreateTodayPost(String userId) {
        LocalDate sessionDate = sessionTime.currentSessionDate();
        Post post = postMapper.selectByUserAndDate(userId, sessionDate);
        if (post != null) {
            return post;
        }

        Post created = new Post();
        created.setId(UUID.randomUUID().toString());
        created.setUserId(userId);
        created.setSessionDate(sessionDate);
        created.setReplaceCount(0);
        postMapper.insertPost(created);
        return created;
    }

    /**
     * 저장된 대표 사진 id가 <b>실제로 존재하면</b> 그 값, 아니면 null.
     *
     * <p>{@code posts.main_photo_id}에는 FK가 없다(V11 — 순환 캐스케이드 회피).
     * 그래서 값이 떠 있을 수 있고, 읽을 때마다 실재를 확인한다.
     */
    private String storedMainIfValid(Post post, List<PostPhoto> photos) {
        String current = post.getMainPhotoId();
        if (current == null) {
            return null;
        }
        return photos.stream().anyMatch(p -> p.getId().equals(current)) ? current : null;
    }

    /**
     * 화면에 보여 줄 대표 사진 id. 저장값이 떠 있으면 <b>첫 슬롯(최신)</b>으로 대신한다 —
     * 사진이 있는데 메인이 비어 보이는 일이 없도록.
     */
    private String resolveMainPhotoId(Post post, List<PostPhoto> photos) {
        if (photos.isEmpty()) {
            return null;
        }
        String stored = storedMainIfValid(post, photos);
        return stored != null ? stored : photos.get(0).getId();
    }

    /**
     * 메인을 지웠을 때 승계할 사진. 표시 순서상 <b>바로 다음 슬롯</b>이고,
     * 마지막 슬롯이었다면 <b>직전 슬롯</b>이다. 하나도 안 남으면 null(메인 해제).
     *
     * @param before 삭제 <b>전</b>의 사진 목록(표시 순서 = 최신순)
     */
    private String successorOf(List<PostPhoto> before, String removedId) {
        int i = 0;
        while (i < before.size() && !before.get(i).getId().equals(removedId)) {
            i++;
        }
        if (i == before.size()) {
            return null; // 목록에 없다 — 있을 수 없지만 방어
        }
        if (i + 1 < before.size()) {
            return before.get(i + 1).getId();
        }
        return i > 0 ? before.get(i - 1).getId() : null;
    }

    /**
     * 사진 9장·갤러리 업로드 대상인지. 판정 기준은 <b>앨범패스 엔티틀먼트</b>다
     * (프라임 구독 시 source=PRIME으로 함께 발급되므로 구독 여부를 따로 볼 필요가 없다 — 02 §1.7).
     * {@code users.is_premium}은 캐시/호환용이라 여기서 보지 않는다.
     */
    private boolean isUnlimited(String userId) {
        return entitlementService.hasAlbumPass(userId);
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
