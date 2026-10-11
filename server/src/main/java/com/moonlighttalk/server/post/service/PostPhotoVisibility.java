package com.moonlighttalk.server.post.service;

import com.moonlighttalk.server.post.entity.Post;
import com.moonlighttalk.server.post.entity.PostPhoto;
import com.moonlighttalk.server.post.mapper.PostMapper;
import com.moonlighttalk.server.store.service.EntitlementService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 포스트 사진 중 <b>무엇이 남에게 보이고 무엇이 잠기는가</b>(기획서 261011 3-1).
 *
 * <p>유료(앨범패스·프라임)로 9장까지 올렸다가 무료로 돌아오면 — 사진은 지우지 않고,
 * <b>메인(TOP) 1장 + 바로 다음 슬롯 1장</b>만 공개, 나머지는 잠근다. 유료를 다시 쓰면 풀린다.
 *
 * <p>🚨 <b>잠금은 저장하지 않고 매번 계산한다</b> — "지금 유료인가 + 메인이 어느 슬롯인가"만으로
 * 정해지므로, 구독이 끝나거나 다시 시작되는 순간 별도 작업 없이 따라온다.
 *
 * <p>🚨 남에게 사진을 내주는 곳(달빛가든 카드 · [포스트 정보] · 친구 포스트)은
 * <b>반드시 {@link #publicKeys}를 거친다.</b> 잠긴 사진의 URL은 응답에 아예 담기지 않아야 한다(함정 #18).
 * 보는 사람 쪽 열람 제한("무료는 상대 메인 1장만")은 그 위에 얹힌다.
 */
@Component
public class PostPhotoVisibility {

    private final PostMapper postMapper;
    private final EntitlementService entitlementService;
    private final int maxPhotosFree;

    public PostPhotoVisibility(PostMapper postMapper,
                               EntitlementService entitlementService,
                               @Value("${app.post.max-photos-free:2}") int maxPhotosFree) {
        this.postMapper = postMapper;
        this.entitlementService = entitlementService;
        this.maxPhotosFree = maxPhotosFree;
    }

    /** 남에게 보여 줄 사진의 storage key — <b>메인이 첫 장</b>, 그다음은 표시 순서(최신순). */
    public List<String> publicKeys(String postId) {
        Post post = postMapper.selectPostById(postId);
        if (post == null) {
            return List.of();
        }
        List<PostPhoto> photos = postMapper.selectPhotos(postId);
        boolean unlimited = entitlementService.hasAlbumPass(post.getUserId());
        return publicPhotos(post, photos, unlimited).stream()
                .map(PostPhoto::getStorageKey)
                .toList();
    }

    /** 잠긴 사진 id. 유료이거나 무료 한도 안이면 빈 집합. */
    public Set<String> lockedIds(Post post, List<PostPhoto> photos, boolean unlimited) {
        Set<String> open = publicPhotos(post, photos, unlimited).stream()
                .map(PostPhoto::getId)
                .collect(Collectors.toSet());
        return photos.stream()
                .map(PostPhoto::getId)
                .filter(id -> !open.contains(id))
                .collect(Collectors.toSet());
    }

    /**
     * 공개 사진(메인 → 나머지). 무료인데 한도를 넘었으면 <b>메인부터 표시 순서로 한도만큼</b>이고,
     * 메인이 끝 쪽이라 뒤가 모자라면 <b>앞쪽에서</b> 채운다 — 메인 삭제 승계({@code successorOf})와 같은 방향.
     *
     * @param photos 표시 순서(최신순) 목록
     */
    List<PostPhoto> publicPhotos(Post post, List<PostPhoto> photos, boolean unlimited) {
        if (photos.isEmpty()) {
            return List.of();
        }
        int mainIdx = indexOf(photos, mainPhotoId(post, photos));

        List<PostPhoto> result = new ArrayList<>();
        result.add(photos.get(mainIdx));
        if (unlimited || photos.size() <= maxPhotosFree) {
            for (int i = 0; i < photos.size(); i++) {
                if (i != mainIdx) {
                    result.add(photos.get(i));
                }
            }
            return result;
        }

        for (int i = mainIdx + 1; i < photos.size() && result.size() < maxPhotosFree; i++) {
            result.add(photos.get(i));
        }
        for (int i = mainIdx - 1; i >= 0 && result.size() < maxPhotosFree; i--) {
            result.add(photos.get(i));
        }
        return result;
    }

    /**
     * 메인 사진 id. 저장값이 떠 있으면(FK 없음 — V11) <b>첫 슬롯(최신)</b>으로 대신한다.
     * 사진이 없으면 null.
     */
    String mainPhotoId(Post post, List<PostPhoto> photos) {
        if (photos.isEmpty()) {
            return null;
        }
        String stored = post.getMainPhotoId();
        boolean valid = stored != null && photos.stream().anyMatch(p -> p.getId().equals(stored));
        return valid ? stored : photos.get(0).getId();
    }

    private static int indexOf(List<PostPhoto> photos, String id) {
        for (int i = 0; i < photos.size(); i++) {
            if (photos.get(i).getId().equals(id)) {
                return i;
            }
        }
        return 0;
    }
}
