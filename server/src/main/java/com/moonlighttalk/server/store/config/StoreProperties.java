package com.moonlighttalk.server.store.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 상품 카탈로그 — <b>가격·구성은 코드가 아니라 설정에서 온다</b>(01 문서 §1.8).
 * BM 값이 바뀌어도 코드를 고치지 않게 하기 위한 것이며, 현금 가격은 스토어 콘솔이 권위다.
 */
@Component
@ConfigurationProperties(prefix = "app.store")
public class StoreProperties {

    /** 루나로 사는 개별 상품(부스트·패스). IAP 대상이 아니다. */
    private Map<String, LunaProduct> lunaProducts = new LinkedHashMap<>();

    /** 인앱결제로 사는 것 — 루나 충전 패키지. */
    private Map<String, LunaPack> lunaPacks = new LinkedHashMap<>();

    /** 인앱결제로 사는 것 — 프라임 구독. */
    private Map<String, PrimePlan> primePlans = new LinkedHashMap<>();

    public Map<String, LunaProduct> getLunaProducts() {
        return lunaProducts;
    }

    public void setLunaProducts(Map<String, LunaProduct> lunaProducts) {
        this.lunaProducts = lunaProducts;
    }

    public Map<String, LunaPack> getLunaPacks() {
        return lunaPacks;
    }

    public void setLunaPacks(Map<String, LunaPack> lunaPacks) {
        this.lunaPacks = lunaPacks;
    }

    public Map<String, PrimePlan> getPrimePlans() {
        return primePlans;
    }

    public void setPrimePlans(Map<String, PrimePlan> primePlans) {
        this.primePlans = primePlans;
    }

    /** 루나로 사는 상품 하나. 부스트면 quantity, 패스면 durationDays를 쓴다. */
    public static class LunaProduct {
        /** BOOST | ENTITLEMENT */
        private String type;
        /** BOOST면 POST_BOOST/SPOTLIGHT_BOOST, ENTITLEMENT면 ALBUM_PASS/TRANSLATE_PASS 등 */
        private String kind;
        private int price;
        private int quantity = 1;
        private int durationDays;
        /** 원장에 남길 사유(BUY_BOOST 등). */
        private String reason;

        public String getType() {
            return type;
        }

        public void setType(String type) {
            this.type = type;
        }

        public String getKind() {
            return kind;
        }

        public void setKind(String kind) {
            this.kind = kind;
        }

        public int getPrice() {
            return price;
        }

        public void setPrice(int price) {
            this.price = price;
        }

        public int getQuantity() {
            return quantity;
        }

        public void setQuantity(int quantity) {
            this.quantity = quantity;
        }

        public int getDurationDays() {
            return durationDays;
        }

        public void setDurationDays(int durationDays) {
            this.durationDays = durationDays;
        }

        public String getReason() {
            return reason;
        }

        public void setReason(String reason) {
            this.reason = reason;
        }
    }

    /** 루나 충전 패키지(IAP). 표시 가격은 스토어 SDK의 현지 가격을 쓴다. */
    public static class LunaPack {
        private int luna;
        private int bonus;

        public int getLuna() {
            return luna;
        }

        public void setLuna(int luna) {
            this.luna = luna;
        }

        public int getBonus() {
            return bonus;
        }

        public void setBonus(int bonus) {
            this.bonus = bonus;
        }

        public int total() {
            return luna + bonus;
        }
    }

    /** 프라임 구독 플랜(IAP). 구독하면 아래 엔티틀먼트와 부스트가 함께 붙는다. */
    public static class PrimePlan {
        /** PRIME_1M | PRIME_6M */
        private String product;
        private int durationDays;
        /** 함께 발급할 엔티틀먼트 kind 목록. */
        private List<String> entitlements = new ArrayList<>();
        /** 함께 충전할 부스트(kind → 매수). */
        private Map<String, Integer> boosts = new LinkedHashMap<>();
        /** 함께 지급할 루나. */
        private int luna;

        public String getProduct() {
            return product;
        }

        public void setProduct(String product) {
            this.product = product;
        }

        public int getDurationDays() {
            return durationDays;
        }

        public void setDurationDays(int durationDays) {
            this.durationDays = durationDays;
        }

        public List<String> getEntitlements() {
            return entitlements;
        }

        public void setEntitlements(List<String> entitlements) {
            this.entitlements = entitlements;
        }

        public Map<String, Integer> getBoosts() {
            return boosts;
        }

        public void setBoosts(Map<String, Integer> boosts) {
            this.boosts = boosts;
        }

        public int getLuna() {
            return luna;
        }

        public void setLuna(int luna) {
            this.luna = luna;
        }
    }
}
