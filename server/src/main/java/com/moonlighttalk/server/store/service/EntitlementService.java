package com.moonlighttalk.server.store.service;

import com.moonlighttalk.server.store.entity.Subscription;
import com.moonlighttalk.server.store.mapper.StoreMapper;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 혜택 판정의 단일 창구. 다른 도메인(post·garden·chat·friend)은 이 서비스만 보고
 * "이 사용자가 지금 이걸 쓸 수 있나"를 묻는다.
 *
 * <p><b>판정 기준</b>(02 §1.7): {@code users.is_premium}은 캐시/호환용일 뿐이고
 * 실제 권한은 {@code subscriptions}(미만료) + {@code user_entitlements}(kind별 미만료)다.
 * 프라임을 사면 앨범패스·번역패스·대화무제한·광고제거가 {@code source=PRIME}으로 함께 발급되므로,
 * 개별 기능 판정은 <b>구독 여부가 아니라 엔티틀먼트</b>를 보면 된다.
 */
@Service
public class EntitlementService {

    public static final String ALBUM_PASS = "ALBUM_PASS";
    public static final String TRANSLATE_PASS = "TRANSLATE_PASS";
    public static final String UNLIMITED_CHAT_REQ = "UNLIMITED_CHAT_REQ";
    public static final String NO_ADS = "NO_ADS";

    private final StoreMapper storeMapper;

    public EntitlementService(StoreMapper storeMapper) {
        this.storeMapper = storeMapper;
    }

    public boolean has(String userId, String kind) {
        return storeMapper.existsActiveEntitlement(userId, kind, LocalDateTime.now());
    }

    /** 프라임 구독 중인지(자동갱신만 해지한 CANCELLED도 만료 전까지는 유효). */
    public boolean isPrime(String userId) {
        return currentSubscription(userId) != null;
    }

    public Subscription currentSubscription(String userId) {
        return storeMapper.selectCurrentSubscription(userId, LocalDateTime.now());
    }

    /** 사진 8장·시간 무제한·갤러리 업로드(앨범패스 또는 프라임). */
    public boolean hasAlbumPass(String userId) {
        return has(userId, ALBUM_PASS);
    }

    /** 대화 신청 일일 무료 횟수 무제한. */
    public boolean hasUnlimitedChatRequests(String userId) {
        return has(userId, UNLIMITED_CHAT_REQ);
    }

    public boolean hasTranslatePass(String userId) {
        return has(userId, TRANSLATE_PASS);
    }

    /** 지금 부스트를 켜 둔 사용자들 — 피드 Pick Point 판정에 쓴다. */
    public List<String> boostedUserIds() {
        return storeMapper.selectBoostedUserIds(LocalDateTime.now());
    }
}
