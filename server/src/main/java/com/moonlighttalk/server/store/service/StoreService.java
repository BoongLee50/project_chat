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
 * 유료 상점 — 카탈로그 조회, 상점 상품 지급 규칙, 부스트 사용, 구독 해지. (01 §1.8, 02 §1.7)
 *
 * <p>결제(영수증 검증)는 {@link PurchaseService}가 맡고, <b>무엇을 어떻게 넣는지</b>는 여기서 정한다.
 * 기획서 261111부터 루나 상점이 없다 — 부스트·포스트 앨범·자동 번역도 현금으로 하나씩 산다.
 *
 * <p><b>프라임 구독분 / 상점 구매분</b>(V31, 사용자 2026-11-14):
 * <ul>
 *   <li>부스트 — 출처별 매수. 쓸 때 <b>프라임 구독분부터</b>. 프라임 구독분은 30일마다 <b>10개씩 더해진다</b>(안 쓰면 계속 쌓인다,
 *       사용자 2026-11-15). <b>구독이 끝나도 남아서 계속 쓴다</b> — 부스트는 한 개씩 쓰는 물건이라서다(사용자 2026-11-15).
 *       그래서 구독이 끝난 뒤에도 프라임 구독분부터 쓴다.</li>
 *   <li>패스(앨범·자동 번역)는 시간제라 <b>프라임 기간이 끝나면 프라임 구독분도 끝난다</b>(행의 expires_at = 구독 만료).</li>
 *   <li>패스 — 출처별 한 행. 상점 구매분은 <b>프라임이 끝난 뒤부터</b> 흐른다(구독 중엔 멈춰 있다).</li>
 *   <li>상점에서 다시 사기 — 상점 구매분이 남아 있으면 안 된다(기획서 "미 사용량이 모두 소진될 경우 구매 가능").</li>
 * </ul>
 */
@Service
public class StoreService {

    /** 부스트 1회 사용 시 유지 시간(기획 8-3). */
    private static final int BOOST_HOURS = 1;

    /** 부스트는 포스트 부스트 하나뿐이다(Plan_3에서 스포트라이트 폐지). */
    private static final String BOOST_KIND = "POST_BOOST";

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
        List<ShopProductDto> shopProducts = new ArrayList<>();
        properties.getShopProducts().forEach((id, p) -> shopProducts.add(new ShopProductDto(
                id, p.getType(), p.getKind(), p.getPrice(), p.getQuantity(), p.getDurationDays(),
                p.getDiscount())));

        List<LunaPackDto> packs = new ArrayList<>();
        properties.getLunaPacks().forEach((id, p) ->
                packs.add(new LunaPackDto(id, p.getLuna(), p.getBonus(), p.total(),
                        p.getPrice(), p.getBadge())));

        List<PrimePlanDto> plans = new ArrayList<>();
        properties.getPrimePlans().forEach((id, p) -> plans.add(new PrimePlanDto(
                id, p.getProduct(), p.getDurationDays(), p.getLuna(),
                p.getEntitlements(), p.getBoosts(), p.getPrice())));

        return new ProductCatalogDto(shopProducts, packs, plans, maxPhotosFree, maxPhotosPass);
    }

    /** 화면이 필요로 하는 상태를 한 번에. */
    public WalletDto wallet(String userId) {
        LocalDateTime now = LocalDateTime.now();
        Subscription subscription = storeMapper.selectCurrentSubscription(userId, now);

        // 지금 흐르는 권리(출처가 둘이면 늦게 끝나는 쪽) — 기능 판정·PASS 표시용.
        Map<String, LocalDateTime> entitlements = new LinkedHashMap<>();
        Map<String, LocalDateTime> entitlementStartedAt = new LinkedHashMap<>();
        for (Entitlement e : storeMapper.selectActiveEntitlements(userId, now)) {
            LocalDateTime prev = entitlements.get(e.getKind());
            if (prev == null || e.getExpiresAt().isAfter(prev)) {
                entitlements.put(e.getKind(), e.getExpiresAt());
                entitlementStartedAt.put(e.getKind(), e.getStartedAt());
            }
        }

        // 관리 화면 — 패스는 출처별 기간(아직 시작 안 한 상점 구매분 포함).
        Map<String, LocalDateTime[]> held = new LinkedHashMap<>();
        for (Entitlement e : storeMapper.selectHeldEntitlements(userId, now)) {
            LocalDateTime[] slot = held.computeIfAbsent(e.getKind(), k -> new LocalDateTime[4]);
            int at = "PRIME".equals(e.getSource()) ? 0 : 2;
            slot[at] = e.getStartedAt();
            slot[at + 1] = e.getExpiresAt();
        }
        Map<String, PassHoldingDto> passes = new LinkedHashMap<>();
        for (String kind : List.of(EntitlementService.ALBUM_PASS, EntitlementService.TRANSLATE_PASS)) {
            LocalDateTime[] slot = held.get(kind);
            if (slot != null) {
                passes.put(kind, new PassHoldingDto(slot[0], slot[1], slot[2], slot[3]));
            }
        }

        // 부스트 — 출처별 매수 + 지금 켜진 것.
        Map<String, Integer> inventory = new LinkedHashMap<>();
        Map<String, int[]> stocks = new LinkedHashMap<>();
        for (BoostStock stock : storeMapper.selectBoostStocks(userId)) {
            inventory.merge(stock.getKind(), stock.getQuantity(), Integer::sum);
            stocks.computeIfAbsent(stock.getKind(), k -> new int[2])
                    ["PRIME".equals(stock.getSource()) ? 0 : 1] += stock.getQuantity();
        }
        List<BoostActivation> active = storeMapper.selectActiveBoosts(userId, now);
        List<ActiveBoostDto> activeBoosts = active.stream()
                .map(b -> new ActiveBoostDto(b.getKind(), b.getSource(), b.getStartedAt(), b.getExpiresAt()))
                .toList();
        Map<String, BoostHoldingDto> boosts = new LinkedHashMap<>();
        for (String kind : List.of(BOOST_KIND)) {
            int[] n = stocks.getOrDefault(kind, new int[2]);
            BoostActivation on = active.stream().filter(b -> kind.equals(b.getKind()))
                    .max((a, b) -> a.getStartedAt().compareTo(b.getStartedAt())).orElse(null);
            boosts.put(kind, new BoostHoldingDto(n[0], n[1],
                    on == null ? null : on.getSource(),
                    on == null ? null : on.getStartedAt(),
                    on == null ? null : on.getExpiresAt()));
        }

        return new WalletDto(
                lunaService.balance(userId),
                subscription != null,
                subscription == null ? null : subscription.getProduct(),
                subscription == null ? null : subscription.getStartedAt(),
                subscription == null ? null : subscription.getExpiresAt(),
                subscription != null && Boolean.TRUE.equals(subscription.getAutoRenew()),
                entitlements,
                entitlementStartedAt,
                inventory,
                boosts,
                passes,
                activeBoosts);
    }

    /** 상점 상품(인앱결제) — 없으면 404. */
    public StoreProperties.ShopProduct shopProduct(String productId) {
        return properties.getShopProducts().get(productId);
    }

    /**
     * 다시 사도 되는지 — <b>상점 구매분이 남아 있으면 안 된다</b>(기획서 261111 10-2~10-4
     * "중복 구매는 안되고, 미 사용량이 모두 소진될 경우 구매 가능"). 프라임 구독분은 따지지 않는다.
     * 결제가 기록되기 <b>전에</b> 부른다(지급만 막히고 결제가 남는 일이 없게).
     */
    public void assertCanBuy(String userId, StoreProperties.ShopProduct product) {
        LocalDateTime now = LocalDateTime.now();
        boolean holding = switch (product.getType()) {
            case "BOOST" -> storeMapper.selectBoostStocks(userId).stream()
                    .anyMatch(b -> b.getKind().equals(product.getKind())
                            && "STORE".equals(b.getSource()) && b.getQuantity() > 0);
            case "ENTITLEMENT" -> storeMapper.selectHeldEntitlements(userId, now).stream()
                    .anyMatch(e -> e.getKind().equals(product.getKind()) && "STORE".equals(e.getSource()));
            default -> throw new ApiException(ErrorCode.STORE_PRODUCT_INVALID,
                    HttpStatus.INTERNAL_SERVER_ERROR, "상품 구성이 잘못됐어요.");
        };
        if (holding) {
            throw new ApiException(ErrorCode.STORE_ALREADY_OWNED, HttpStatus.CONFLICT,
                    "이미 보유 중인 상품이에요.");
        }
    }

    /**
     * 상점 상품 지급(결제 검증 뒤). 부스트는 상점 구매분 매수에 더하고, 패스는
     * <b>프라임 중이면 프라임이 끝나는 때부터</b> 기간을 센다(사용자 2026-11-14).
     */
    @Transactional
    public void grantShopProduct(String userId, StoreProperties.ShopProduct product) {
        LocalDateTime now = LocalDateTime.now();
        switch (product.getType()) {
            case "BOOST" -> storeMapper.addBoostStock(userId, product.getKind(), "STORE",
                    product.getQuantity());
            case "ENTITLEMENT" -> {
                Subscription prime = storeMapper.selectCurrentSubscription(userId, now);
                LocalDateTime start = prime == null ? now : prime.getExpiresAt();
                storeMapper.putStoreEntitlement(userId, product.getKind(), start,
                        start.plusDays(product.getDurationDays()));
            }
            default -> throw new ApiException(ErrorCode.STORE_PRODUCT_INVALID,
                    HttpStatus.INTERNAL_SERVER_ERROR, "상품 구성이 잘못됐어요.");
        }
    }

    /**
     * 프라임 부스트 지급(배치, 10분마다) — 살아 있는 구독에만 준다. 이미 받은 것은 구독이 끝나도 남는다.
     * 30일마다 <b>10개씩 더한다</b> — 안 쓰면 계속 쌓인다(사용자 2026-11-15, 11-14의 "10개로 맞춤"을 바꿈).
     */
    @Transactional
    public int refreshPrimeBoosts() {
        LocalDateTime now = LocalDateTime.now();
        int refilled = 0;
        for (Subscription sub : storeMapper.selectSubscriptionsDueForBoost(now)) {
            StoreProperties.PrimePlan plan = properties.getPrimePlans().values().stream()
                    .filter(p -> p.getProduct().equals(sub.getProduct())).findFirst().orElse(null);
            if (plan == null) continue;
            // 배치가 멈춰 있던 동안 지난 달도 빠짐없이 — 지난 30일 묶음 수만큼 더한다.
            LocalDateTime next = sub.getBoostGrantedAt();
            int months = 0;
            while (!next.plusDays(30).isAfter(now)) {
                next = next.plusDays(30);
                months++;
            }
            final int times = months;
            plan.getBoosts().forEach((kind, quantity) ->
                    storeMapper.addBoostStock(sub.getUserId(), kind, "PRIME", quantity * times));
            storeMapper.updateBoostGrantedAt(sub.getId(), next);
            refilled++;
        }
        return refilled;
    }

    /** 보유 부스트 1매 사용 → 1시간 활성. **프라임 구독분부터** 쓴다. 활성 중이면 중복 사용을 막는다. */
    @Transactional
    public WalletDto useBoost(String userId, String kind) {
        LocalDateTime now = LocalDateTime.now();
        boolean alreadyOn = storeMapper.selectActiveBoosts(userId, now).stream()
                .anyMatch(b -> b.getKind().equals(kind));
        if (alreadyOn) {
            throw new ApiException(ErrorCode.STORE_BOOST_ALREADY_ACTIVE, HttpStatus.CONFLICT,
                    "이미 사용 중인 부스트예요.");
        }
        String source = storeMapper.consumeBoostStock(userId, kind, "PRIME") > 0 ? "PRIME"
                : storeMapper.consumeBoostStock(userId, kind, "STORE") > 0 ? "STORE" : null;
        if (source == null) {
            throw new ApiException(ErrorCode.STORE_BOOST_NONE, HttpStatus.CONFLICT,
                    "보유한 부스트가 없어요.");
        }

        BoostActivation activation = new BoostActivation();
        activation.setId(UUID.randomUUID().toString());
        activation.setUserId(userId);
        activation.setKind(kind);
        activation.setSource(source);
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

    /**
     * [해지 신청 취소] — 해지한 구독의 자동갱신을 다시 켠다(시안 `SubEndCancel`).
     * 기간이 끝나기 전에만 된다. 끝난 구독은 새로 결제해야 한다.
     */
    @Transactional
    public WalletDto resumeSubscription(String userId) {
        Subscription subscription = entitlementService.currentSubscription(userId);
        if (subscription == null) {
            throw new ApiException(ErrorCode.STORE_NOT_SUBSCRIBED, HttpStatus.NOT_FOUND,
                    "구독 중이 아니에요.");
        }
        if (Boolean.TRUE.equals(subscription.getAutoRenew())) {
            throw new ApiException(ErrorCode.STORE_NOT_CANCELED, HttpStatus.CONFLICT,
                    "해지 신청한 구독이 아니에요.");
        }
        storeMapper.resumeAutoRenew(subscription.getId());
        return wallet(userId);
    }
}
