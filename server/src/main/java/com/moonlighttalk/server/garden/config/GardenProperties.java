package com.moonlighttalk.server.garden.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * 달빛가든 노출 알고리즘의 수치. (기획서 4-1 / docs/12 §4-2)
 *
 * <p><b>왜 설정으로 빼는가</b> — 여기 있는 값은 전부 "운영하며 만지는 숫자"다.
 * 점수 배분도 믹싱 비율도 기획이 바꾸겠다고 말한 적이 있고, 그때 재배포가 필요하면 안 된다.
 * {@code @Value} 대신 이 클래스를 쓰는 이유는 값이 열 개가 넘어 생성자가 읽을 수 없어지기 때문이다.
 *
 * <p>⚠️ <b>Plan_3에서 Pick Point(부스트 가점)가 사라졌다.</b> 부스트는 점수를 더 주는 게 아니라
 * <b>풀을 나누는 것</b>이다({@link #mix}) — 스코어 공식은 부스트 사용자에게도 똑같이 적용된다.
 */
@Component
@ConfigurationProperties(prefix = "app.garden")
public class GardenProperties {

    private int scoreOnline = 10;
    private Recency recency = new Recency();
    private Engage engage = new Engage();
    private Mix mix = new Mix();

    /** 한 번 보여준 상대를 다시 후보에 넣지 않는 시간(분). */
    private int exposureCooldownMinutes = 15;

    /**
     * 한 번 산정한 노출 순서를 유지하는 시간(분).
     *
     * <p>기획서는 "가든 진입 시 1회 산정, 그 세션 동안 순서 유지"라고만 하고 세션의 길이를
     * 정하지 않았다. 앱을 껐다 켜는 것을 서버가 알 수 없으므로 시간으로 끊는다.
     */
    private int sessionTtlMinutes = 30;

    /** Recency Point — 기준 시각은 <b>공유 시각과 사진 갱신 시각 중 나중</b>이다. */
    public static class Recency {
        private int within1h = 30;
        private int within3h = 20;
        private int within5h = 10;

        public int getWithin1h() { return within1h; }
        public void setWithin1h(int v) { this.within1h = v; }
        public int getWithin3h() { return within3h; }
        public void setWithin3h(int v) { this.within3h = v; }
        public int getWithin5h() { return within5h; }
        public void setWithin5h(int v) { this.within5h = v; }
    }

    /**
     * Engage Point — 전환율 = {(좋아요×{@link #likeWeight}) + (댓글×{@link #commentWeight})
     * + (대화신청×{@link #requestWeight})} / 총 노출 × 100.
     */
    public static class Engage {
        /** 노출이 이만큼 쌓이기 전에는 전환율을 0으로 본다(표본이 적으면 요동친다). */
        private int minExposures = 20;
        private int likeWeight = 1;
        private int commentWeight = 2;
        private int requestWeight = 4;

        /** 전환율(%) 구간별 점수. 높은 구간부터 확인한다. */
        private int rate30 = 30;
        private int rate20 = 20;
        private int rate15 = 15;
        private int rate10 = 10;
        private int rate5 = 5;

        public int getMinExposures() { return minExposures; }
        public void setMinExposures(int v) { this.minExposures = v; }
        public int getLikeWeight() { return likeWeight; }
        public void setLikeWeight(int v) { this.likeWeight = v; }
        public int getCommentWeight() { return commentWeight; }
        public void setCommentWeight(int v) { this.commentWeight = v; }
        public int getRequestWeight() { return requestWeight; }
        public void setRequestWeight(int v) { this.requestWeight = v; }
        public int getRate30() { return rate30; }
        public void setRate30(int v) { this.rate30 = v; }
        public int getRate20() { return rate20; }
        public void setRate20(int v) { this.rate20 = v; }
        public int getRate15() { return rate15; }
        public void setRate15(int v) { this.rate15 = v; }
        public int getRate10() { return rate10; }
        public void setRate10(int v) { this.rate10 = v; }
        public int getRate5() { return rate5; }
        public void setRate5(int v) { this.rate5 = v; }
    }

    /**
     * 일반 풀과 부스트 풀을 섞는 비율(기본 6:4).
     *
     * <p>부스트 풀이 일반 풀보다 크거나 같으면 <b>비율을 뒤집는다</b> — 그래야 소수인 쪽이
     * 항상 더 자주 나온다. 부스트가 팔리지 않은 날 일반 사용자가 되레 밀리는 것을 막는 규칙이다.
     */
    public static class Mix {
        private int normal = 6;
        private int boost = 4;

        public int getNormal() { return normal; }
        public void setNormal(int v) { this.normal = v; }
        public int getBoost() { return boost; }
        public void setBoost(int v) { this.boost = v; }
    }

    public int getScoreOnline() { return scoreOnline; }
    public void setScoreOnline(int v) { this.scoreOnline = v; }
    public Recency getRecency() { return recency; }
    public void setRecency(Recency v) { this.recency = v; }
    public Engage getEngage() { return engage; }
    public void setEngage(Engage v) { this.engage = v; }
    public Mix getMix() { return mix; }
    public void setMix(Mix v) { this.mix = v; }
    public int getExposureCooldownMinutes() { return exposureCooldownMinutes; }
    public void setExposureCooldownMinutes(int v) { this.exposureCooldownMinutes = v; }
    public int getSessionTtlMinutes() { return sessionTtlMinutes; }
    public void setSessionTtlMinutes(int v) { this.sessionTtlMinutes = v; }
}
