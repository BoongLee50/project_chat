package com.moonlighttalk.server.store.service;

import com.moonlighttalk.server.common.exception.ApiException;
import com.moonlighttalk.server.common.response.ErrorCode;
import com.moonlighttalk.server.luna.service.LunaService;
import com.moonlighttalk.server.store.config.StoreProperties;
import com.moonlighttalk.server.store.dto.WalletDto;
import com.moonlighttalk.server.store.entity.Subscription;
import com.moonlighttalk.server.store.mapper.StoreMapper;
import com.moonlighttalk.server.store.verifier.ReceiptVerifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * 인앱결제 처리 — <b>클라가 "샀다"고 말하는 것을 믿지 않는다</b>(01 §1.8).
 * 영수증을 스토어에 직접 물어 검증한 뒤에만 지급하고, purchaseToken을 저장해 중복 지급을 막는다.
 *
 * <p>IAP 대상은 <b>루나 충전과 프라임 구독뿐</b>이다. 루나로 사는 개별 상품(부스트·패스)은
 * 앱 내부 재화 소비라 스토어를 거치지 않는다({@link StoreService#purchaseWithLuna}).
 */
@Service
public class PurchaseService {

    private static final Logger log = LoggerFactory.getLogger(PurchaseService.class);

    private final StoreProperties properties;
    private final StoreMapper storeMapper;
    private final LunaService lunaService;
    private final StoreService storeService;
    private final Map<String, ReceiptVerifier> verifiers;

    public PurchaseService(StoreProperties properties,
                            StoreMapper storeMapper,
                            LunaService lunaService,
                            StoreService storeService,
                            List<ReceiptVerifier> verifierList) {
        this.properties = properties;
        this.storeMapper = storeMapper;
        this.lunaService = lunaService;
        this.storeService = storeService;
        this.verifiers = verifierList.stream()
                .collect(java.util.stream.Collectors.toMap(ReceiptVerifier::platform, v -> v));
    }

    /**
     * 영수증 검증 → 지급. 같은 purchaseToken이 다시 오면 유니크 제약에 걸려 두 번 지급되지 않는다.
     */
    @Transactional
    public WalletDto verifyAndGrant(String userId, String platform, String productId,
                                     String purchaseToken) {
        ReceiptVerifier verifier = resolveVerifier(platform);
        if (!verifier.verify(productId, purchaseToken)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.BAD_REQUEST,
                    "결제 정보를 확인할 수 없어요.");
        }

        String tokenHash = sha256(purchaseToken);
        if (storeMapper.existsPurchase(platform, tokenHash)) {
            // 이미 처리한 결제 — 재시도/중복 호출이므로 조용히 현재 상태만 돌려준다.
            log.info("이미 처리한 결제 platform={} product={}", platform, productId);
            return storeService.wallet(userId);
        }

        try {
            storeMapper.insertPurchase(UUID.randomUUID().toString(), userId, platform,
                    productId, purchaseToken, tokenHash);
        } catch (DataIntegrityViolationException e) {
            // 같은 순간 두 번 들어온 경우
            log.info("결제 중복 도착 platform={} product={}", platform, productId);
            return storeService.wallet(userId);
        }

        grant(userId, productId, purchaseToken);
        return storeService.wallet(userId);
    }

    /** 상품 종류에 따라 루나를 넣거나 구독을 켠다. */
    private void grant(String userId, String productId, String purchaseToken) {
        StoreProperties.LunaPack pack = properties.getLunaPacks().get(productId);
        if (pack != null) {
            lunaService.grant(userId, pack.total(), "CHARGE", productId);
            return;
        }

        StoreProperties.PrimePlan plan = properties.getPrimePlans().get(productId);
        if (plan != null) {
            activatePrime(userId, plan, purchaseToken);
            return;
        }

        throw new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND,
                "존재하지 않는 상품이에요.");
    }

    /**
     * 프라임 구독 활성화 — 구독 행 + 번들 엔티틀먼트 + 부스트 매수 + 보너스 루나.
     * 개별 기능 판정은 엔티틀먼트로 하므로(02 §1.7) 여기서 함께 발급해 둔다.
     */
    private void activatePrime(String userId, StoreProperties.PrimePlan plan, String purchaseToken) {
        LocalDateTime now = LocalDateTime.now();

        Subscription subscription = new Subscription();
        subscription.setId(UUID.randomUUID().toString());
        subscription.setUserId(userId);
        subscription.setProduct(plan.getProduct());
        subscription.setStatus("ACTIVE");
        subscription.setStartedAt(now);
        subscription.setExpiresAt(now.plusDays(plan.getDurationDays()));
        subscription.setAutoRenew(true);
        subscription.setStoreTxn(purchaseToken);
        try {
            storeMapper.insertSubscription(subscription);
        } catch (DataIntegrityViolationException e) {
            // active_user_id 유니크 위반 = 이미 구독 중
            throw new ApiException(ErrorCode.VALIDATION_FAILED, HttpStatus.CONFLICT,
                    "이미 프라임 구독 중이에요.");
        }

        for (String kind : plan.getEntitlements()) {
            storeMapper.upsertEntitlement(userId, kind, "PRIME", now, plan.getDurationDays());
        }
        plan.getBoosts().forEach((kind, quantity) ->
                storeMapper.addBoostStock(userId, kind, quantity));
        if (plan.getLuna() > 0) {
            lunaService.grant(userId, plan.getLuna(), "CHARGE", plan.getProduct());
        }
    }

    private ReceiptVerifier resolveVerifier(String platform) {
        ReceiptVerifier verifier = verifiers.get(platform);
        if (verifier == null) {
            // 개발 환경에서는 MOCK이 모든 플랫폼을 대신 받는다.
            verifier = verifiers.get("MOCK");
        }
        if (verifier == null) {
            throw new ApiException(ErrorCode.PROVIDER_DISABLED, HttpStatus.SERVICE_UNAVAILABLE,
                    "현재 결제를 처리할 수 없어요.");
        }
        return verifier;
    }

    private String sha256(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
