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

    /**
     * 이 권리를 지금 가진 사람들. 한 명씩 묻지 않으려고 한 번에 읽는다 —
     * 피드 한 페이지가 열 장이면 질의도 열 번 나가던 자리다(부스트와 같은 방식).
     */
    List<String> selectUserIdsWithEntitlement(@Param("kind") String kind,
                                               @Param("now") LocalDateTime now);

    // ── 부스트 ──
    void addBoostStock(@Param("userId") String userId, @Param("kind") String kind,
                        @Param("quantity") int quantity);

    /** 재고 차감. 남은 수량이 모자라면 0행이 갱신되므로 호출부가 실패로 처리한다. */
    int consumeBoostStock(@Param("userId") String userId, @Param("kind") String kind);

    List<BoostStock> selectBoostStocks(@Param("userId") String userId);

    void insertBoostActivation(BoostActivation activation);

    List<BoostActivation> selectActiveBoosts(@Param("userId") String userId,
                                              @Param("now") LocalDateTime now);

    /** 지금 부스트가 켜져 있는 사용자들(피드 Pick Point 판정용). */
    List<String> selectBoostedUserIds(@Param("now") LocalDateTime now);

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
