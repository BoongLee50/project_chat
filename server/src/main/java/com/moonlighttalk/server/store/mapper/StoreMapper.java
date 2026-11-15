package com.moonlighttalk.server.store.mapper;

import com.moonlighttalk.server.store.entity.BoostActivation;
import com.moonlighttalk.server.store.entity.BoostStock;
import com.moonlighttalk.server.store.entity.Entitlement;
import com.moonlighttalk.server.store.entity.Subscription;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;
import java.util.List;

@Mapper
public interface StoreMapper {

    // ── 구독 ──
    void insertSubscription(Subscription subscription);

    /** 지금 유효한 구독(ACTIVE 또는 자동갱신만 해지한 CANCELLED 중 미만료). */
    Subscription selectCurrentSubscription(@Param("userId") String userId,
                                            @Param("now") LocalDateTime now);

    void cancelAutoRenew(@Param("id") String id);

    void resumeAutoRenew(@Param("id") String id);

    /** 프라임 부스트를 줄 때가 된(마지막으로 준 지 30일) 살아 있는 구독. */
    List<Subscription> selectSubscriptionsDueForBoost(@Param("now") LocalDateTime now);

    void updateBoostGrantedAt(@Param("id") String id, @Param("at") LocalDateTime at);

    /** 만료된 구독을 EXPIRED로 내리고 부분 유니크 키를 비운다. */
    int expireSubscriptions(@Param("now") LocalDateTime now);

    // ── 엔티틀먼트 ──

    /** 같은 kind가 있으면 만료 시각을 뒤로 늘린다(이미 만료됐다면 지금부터 다시 시작). */
    void upsertEntitlement(@Param("userId") String userId,
                            @Param("kind") String kind,
                            @Param("source") String source,
                            @Param("now") LocalDateTime now,
                            @Param("days") int days);

    List<Entitlement> selectActiveEntitlements(@Param("userId") String userId,
                                                @Param("now") LocalDateTime now);

    boolean existsActiveEntitlement(@Param("userId") String userId,
                                     @Param("kind") String kind,
                                     @Param("now") LocalDateTime now);

    int deleteExpiredEntitlements(@Param("now") LocalDateTime now);

    /** 끝나지 않은 권리 전부 — 아직 시작 안 한 상점 구매분 포함(관리 화면). */
    List<Entitlement> selectHeldEntitlements(@Param("userId") String userId,
                                              @Param("now") LocalDateTime now);

    /** 상점 구매분 한 행(시작·끝을 호출부가 정한다 — 프라임 중이면 프라임이 끝난 때부터). */
    void putStoreEntitlement(@Param("userId") String userId,
                              @Param("kind") String kind,
                              @Param("startedAt") LocalDateTime startedAt,
                              @Param("expiresAt") LocalDateTime expiresAt);

    /** 흐르던 상점 구매분을 [resumeAt]까지 멈춘다(남은 시간은 그대로). */
    int pauseStoreEntitlements(@Param("userId") String userId,
                                @Param("now") LocalDateTime now,
                                @Param("resumeAt") LocalDateTime resumeAt);

    /**
     * 이 권리를 지금 가진 사람들. 한 명씩 묻지 않으려고 한 번에 읽는다 —
     * 피드 한 페이지가 열 장이면 질의도 열 번 나가던 자리다(부스트와 같은 방식).
     */
    List<String> selectUserIdsWithEntitlement(@Param("kind") String kind,
                                               @Param("now") LocalDateTime now);

    // ── 부스트 ──
    void addBoostStock(@Param("userId") String userId, @Param("kind") String kind,
                        @Param("source") String source, @Param("quantity") int quantity);

    /** 재고 차감. 남은 수량이 모자라면 0행이 갱신되므로 호출부가 실패로 처리한다. */
    int consumeBoostStock(@Param("userId") String userId, @Param("kind") String kind,
                           @Param("source") String source);

    /** 구독이 끝난 사람의 프라임 구독분 부스트를 치운다. */
    int deleteOrphanPrimeBoostStock(@Param("now") LocalDateTime now);

    List<BoostStock> selectBoostStocks(@Param("userId") String userId);

    void insertBoostActivation(BoostActivation activation);

    List<BoostActivation> selectActiveBoosts(@Param("userId") String userId,
                                              @Param("now") LocalDateTime now);

    /** 지금 부스트가 켜져 있는 사용자들(피드 Pick Point 판정용). */
    List<String> selectBoostedUserIds(@Param("now") LocalDateTime now);

    /**
     * 부스트를 막 사용해 아직 최우선권이 남은 사용자들.
     *
     * @param viewerLimit 우선권이 유지되는 <b>본 사람 수</b>(노출 횟수가 아니다)
     */
    List<String> selectBoostPriorityUserIds(@Param("now") LocalDateTime now,
                                            @Param("viewerLimit") int viewerLimit);

    int deleteExpiredBoostActivations(@Param("now") LocalDateTime now);

    // ── 인앱결제 영수증(멱등) ──

    /** 이미 처리한 영수증이면 유니크 위반이 나므로 지급이 두 번 되지 않는다. */
    void insertPurchase(@Param("id") String id,
                         @Param("userId") String userId,
                         @Param("platform") String platform,
                         @Param("productId") String productId,
                         @Param("purchaseToken") String purchaseToken,
                         @Param("tokenHash") String tokenHash);

    boolean existsPurchase(@Param("platform") String platform, @Param("tokenHash") String tokenHash);
}
