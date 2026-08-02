package com.moonlighttalk.server.store.dto;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * 내 재화·구독·권리 요약. 클라가 화면 상태(PASS 표시·버튼 활성)를 한 번에 정하도록
 * 필요한 걸 모아서 내려준다. (01 §1.8 `GET /me/wallet`)
 */
public record WalletDto(
        int luna,
        boolean prime,
        String subscriptionProduct,
        LocalDateTime subscriptionExpiresAt,
        boolean autoRenew,
        Map<String, LocalDateTime> entitlements,
        Map<String, Integer> boostInventory,
        List<ActiveBoostDto> activeBoosts
) {
}
