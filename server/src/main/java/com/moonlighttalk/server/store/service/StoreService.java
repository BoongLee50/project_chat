package com.moonlighttalk.server.store.service;

import com.moonlighttalk.server.auth.service.SessionTimeService;
import com.moonlighttalk.server.common.exception.ApiException;
import com.moonlighttalk.server.common.response.ErrorCode;
import com.moonlighttalk.server.luna.service.LunaService;
import com.moonlighttalk.server.store.config.StoreProperties;
import com.moonlighttalk.server.store.dto.*;
import com.moonlighttalk.server.store.entity.BoostActivation;
import com.moonlighttalk.server.store.entity.BoostStock;
import com.moonlighttalk.server.store.entity.Entitlement;
import com.moonlighttalk.server.store.entity.Subscription;
import com.moonlighttalk.server.store.mapper.StoreMapper;
import org.springframework.http.HttpStatus;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * 유료 상점 — 카탈로그 조회, 루나 개별구매, 부스트 사용, 구독 해지. (01 §1.8, 02 §1.7)
 *
 * <p>인앱결제(현금)는 {@link PurchaseService}가 맡는다. 여기서 다루는 건
 * <b>이미 가진 루나로 사는 것</b>이라 스토어와 무관하다.
 */
@Service
public class StoreService {

    /** 부스트 1회 사용 시 유지 시간(기획 8-3). */
    private static final int BOOST_HOURS = 1;

    private final StoreProperties properties;
    private final StoreMapper storeMapper;
    private final LunaService lunaService;
    private final EntitlementService entitlementService;
    private final SessionTimeService sessionTime;

    /** BM 화면의 혜택 문구가 말하는 사진 장수(기획 화면 26·29). 포스트 규칙과 같은 설정을 본다. */
    private final int maxPhotosFree;
    private final int maxPhotosPass;

    public StoreService(StoreProperties properties,
                         StoreMapper storeMapper,
                         LunaService lunaService,
                         EntitlementService entitlementService,
                         SessionTimeService sessionTime,
                         @Value("${app.post.max-photos-free:2}") int maxPhotosFree,
                         @Value("${app.post.max-photos-pass:9}") int maxPhotosPass) {
        this.properties = properties;
        this.storeMapper = storeMapper;
        this.lunaService = lunaService;
        this.entitlementService = entitlementService;
        this.sessionTime = sessionTime;
        this.maxPhotosFree = maxPhotosFree;
        this.maxPhotosPass = maxPhotosPass;
    }

    /** 카탈로그. 가격·구성은 설정에서 온다(코드 하드코딩 금지 — 01 §1.8). */
    public ProductCatalogDto catalog() {
        List<LunaProductDto> lunaProducts = new ArrayList<>();
        properties.getLunaProducts().forEach((id, p) -> lunaProducts.add(new LunaProductDto(
                id, p.getType(), p.getKind(), p.getPrice(), p.getQuantity(), p.getDurationDays())));

        List<LunaPackDto> packs = new ArrayList<>();
        properties.getLunaPacks().forEach((id, p) ->
                packs.add(new LunaPackDto(id, p.getLuna(), p.getBonus(), p.total())));

        List<PrimePlanDto> plans = new ArrayList<>();
        properties.getPrimePlans().forEach((id, p) -> plans.add(new PrimePlanDto(
                id, p.getProduct(), p.getDurationDays(), p.getLuna(),
                p.getEntitlements(), p.getBoosts())));

        return new ProductCatalogDto(lunaProducts, packs, plans, maxPhotosFree, maxPhotosPass);
    }

    /** 화면이 필요로 하는 상태를 한 번에. */
    public WalletDto wallet(String userId) {
        LocalDateTime now = LocalDateTime.now();
        Subscription subscription = storeMapper.selectCurrentSubscription(userId, now);

        Map<String, LocalDateTime> entitlements = new LinkedHashMap<>();
        for (Entitlement e : storeMapper.selectActiveEntitlements(userId, now)) {
            entitlements.put(e.getKind(), e.getExpiresAt());
        }

        Map<String, Integer> inventory = new LinkedHashMap<>();
        for (BoostStock stock : storeMapper.selectBoostStocks(userId)) {
            inventory.put(stock.getKind(), stock.getQuantity());
        }

        List<ActiveBoostDto> activeBoosts = storeMapper.selectActiveBoosts(userId, now).stream()
                .map(b -> new ActiveBoostDto(b.getKind(), b.getExpiresAt()))
                .toList();

        return new WalletDto(
                lunaService.balance(userId),
                subscription != null,
                subscription == null ? null : subscription.getProduct(),
                subscription == null ? null : subscription.getExpiresAt(),
                subscription != null && Boolean.TRUE.equals(subscription.getAutoRenew()),
                entitlements,
                inventory,
                activeBoosts);
    }

    /**
     * 루나로 개별 상품 구매(부스트 매수 / 패스). 차감과 지급이 한 트랜잭션이라
     * 루나만 빠지고 물건이 안 들어오는 일이 없다.
     */
    @Transactional
    public WalletDto purchaseWithLuna(String userId, String productId) {
        StoreProperties.LunaProduct product = properties.getLunaProducts().get(productId);
        if (product == null) {
            throw new ApiException(ErrorCode.STORE_PRODUCT_NOT_FOUND, HttpStatus.NOT_FOUND,
                    "존재하지 않는 상품이에요.");
        }

        lunaService.deduct(userId, product.getPrice(), product.getReason(), productId,
                "루나가 부족해요.");

        switch (product.getType()) {
            case "BOOST" -> storeMapper.addBoostStock(userId, product.getKind(), product.getQuantity());
            case "ENTITLEMENT" -> storeMapper.upsertEntitlement(
                    userId, product.getKind(), "LUNA_PURCHASE",
                    LocalDateTime.now(), product.getDurationDays());
            default -> throw new ApiException(ErrorCode.STORE_PRODUCT_INVALID,
                    HttpStatus.INTERNAL_SERVER_ERROR, "상품 구성이 잘못됐어요.");
        }
        return wallet(userId);
    }

    /** 보유 부스트 1매 사용 → 1시간 활성. 활성 중이면 중복 사용을 막는다. */
    @Transactional
    public WalletDto useBoost(String userId, String kind) {
        LocalDateTime now = LocalDateTime.now();
        boolean alreadyOn = storeMapper.selectActiveBoosts(userId, now).stream()
                .anyMatch(b -> b.getKind().equals(kind));
        if (alreadyOn) {
            throw new ApiException(ErrorCode.STORE_BOOST_ALREADY_ACTIVE, HttpStatus.CONFLICT,
                    "이미 사용 중인 부스트예요.");
        }
        if (storeMapper.consumeBoostStock(userId, kind) == 0) {
            throw new ApiException(ErrorCode.STORE_BOOST_NONE, HttpStatus.CONFLICT,
                    "보유한 부스트가 없어요.");
        }

        BoostActivation activation = new BoostActivation();
        activation.setId(UUID.randomUUID().toString());
        activation.setUserId(userId);
        activation.setKind(kind);
        activation.setSessionDate(sessionTime.currentSessionDate());
        activation.setStartedAt(now);
        activation.setExpiresAt(now.plusHours(BOOST_HOURS));
        storeMapper.insertBoostActivation(activation);

        return wallet(userId);
    }

    /** 자동갱신 해지 — 만료까지는 혜택이 유지된다(02 §1.7). */
    @Transactional
    public WalletDto cancelSubscription(String userId) {
        Subscription subscription = entitlementService.currentSubscription(userId);
        if (subscription == null) {
            throw new ApiException(ErrorCode.STORE_NOT_SUBSCRIBED, HttpStatus.NOT_FOUND,
                    "구독 중이 아니에요.");
        }
        if (!Boolean.TRUE.equals(subscription.getAutoRenew())) {
            throw new ApiException(ErrorCode.STORE_ALREADY_CANCELED, HttpStatus.CONFLICT,
                    "이미 자동갱신을 해지했어요.");
        }
        storeMapper.cancelAutoRenew(subscription.getId());
        return wallet(userId);
    }
}
