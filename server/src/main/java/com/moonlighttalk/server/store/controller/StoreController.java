package com.moonlighttalk.server.store.controller;

import com.moonlighttalk.server.common.security.CurrentUserId;
import com.moonlighttalk.server.store.dto.*;
import com.moonlighttalk.server.store.service.PurchaseService;
import com.moonlighttalk.server.store.service.StoreService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

/** 01 문서 §1.8(유료 상점 / 구독 / 부스트) */
@RestController
public class StoreController {

    private final StoreService storeService;
    private final PurchaseService purchaseService;

    public StoreController(StoreService storeService, PurchaseService purchaseService) {
        this.storeService = storeService;
        this.purchaseService = purchaseService;
    }

    /** 상품 카탈로그(구성·혜택). 현금 표시가는 스토어 SDK의 현지 가격을 쓴다. */
    @GetMapping("/store/products")
    public ProductCatalogDto products() {
        return storeService.catalog();
    }

    /** 내 재화·구독·권리 요약 — 화면 상태(PASS 표시·버튼)를 정할 때 쓴다. */
    @GetMapping("/me/wallet")
    public WalletDto wallet(@CurrentUserId String userId) {
        return storeService.wallet(userId);
    }

    /** 루나로 개별 상품 구매(부스트 매수·패스). 인앱결제 아님. */
    @PostMapping("/store/luna:purchase")
    public WalletDto purchaseWithLuna(@CurrentUserId String userId,
                                       @Valid @RequestBody LunaPurchaseRequest request) {
        return storeService.purchaseWithLuna(userId, request.productId());
    }

    /** 보유 부스트 사용 → 1시간 활성. */
    @PostMapping("/boosts:use")
    public WalletDto useBoost(@CurrentUserId String userId,
                               @Valid @RequestBody UseBoostRequest request) {
        return storeService.useBoost(userId, request.kind());
    }

    /** 인앱결제 영수증 검증 → 루나 지급 또는 구독 활성화. */
    @PostMapping("/store/purchases:verify")
    public WalletDto verifyPurchase(@CurrentUserId String userId,
                                     @Valid @RequestBody VerifyPurchaseRequest request) {
        return purchaseService.verifyAndGrant(userId, request.platform(),
                request.productId(), request.purchaseToken());
    }

    /** 자동갱신 해지(만료까지 유효). */
    @PostMapping("/me/subscription:cancel")
    public WalletDto cancelSubscription(@CurrentUserId String userId) {
        return storeService.cancelSubscription(userId);
    }
}
