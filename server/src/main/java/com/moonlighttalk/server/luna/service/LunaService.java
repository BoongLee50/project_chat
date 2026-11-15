package com.moonlighttalk.server.luna.service;

import com.moonlighttalk.server.luna.mapper.LunaMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.UUID;

/**
 * 루나(재화) — 잔액은 luna_wallets, 변동 이력은 luna_transactions(원장, 02 문서 §1.2).
 *
 * <p>🗑 <b>차감(deduct)은 없앴다</b>(2026-11-15) — 마지막 사용처였던 대화 신청이 기획서 261111 4-3에서
 * 루나를 쓰지 않게 됐다(루나 폐지). 이 클래스에 남은 것은 무료 횟수 집계(daily/lifetime usage)와
 * 상점의 지급·잔액이다.
 */
@Service
public class LunaService {

    private final LunaMapper lunaMapper;

    public LunaService(LunaMapper lunaMapper) {
        this.lunaMapper = lunaMapper;
    }

    public int balance(String userId) {
        Integer balance = lunaMapper.selectBalance(userId);
        return balance == null ? 0 : balance;
    }

    /** 지급(충전·보상 등). */
    @Transactional
    public void grant(String userId, int amount, String reason, String refId) {
        lunaMapper.ensureWallet(userId);
        lunaMapper.addBalance(userId, amount);
        lunaMapper.insertTransaction(UUID.randomUUID().toString(), userId, amount, reason, refId);
    }

    public int dailyUsed(String userId, LocalDate sessionDate, String kind) {
        return lunaMapper.selectDailyUsage(userId, sessionDate, kind);
    }

    @Transactional
    public void useDaily(String userId, LocalDate sessionDate, String kind) {
        lunaMapper.incrementDailyUsage(userId, sessionDate, kind);
    }

    /**
     * 초기화되지 않는 누적 사용량(V21) — 기획서의 *"계정별 5회 무료. 초기화 되지 않음"*.
     *
     * <p>{@link #dailyUsed}와 헷갈리지 말 것. 저쪽은 영업일마다 0으로 돌아온다.
     */
    public int lifetimeUsed(String userId, String kind) {
        return lunaMapper.selectLifetimeUsage(userId, kind);
    }

    public void useLifetime(String userId, String kind) {
        lunaMapper.incrementLifetimeUsage(userId, kind);
    }
}
