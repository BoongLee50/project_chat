package com.moonlighttalk.server.luna.service;

import com.moonlighttalk.server.common.exception.ApiException;
import com.moonlighttalk.server.common.response.ErrorCode;
import com.moonlighttalk.server.luna.mapper.LunaMapper;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.UUID;

/**
 * 루나(재화) — 잔액은 luna_wallets, 변동 이력은 luna_transactions(원장, 02 문서 §1.2).
 * 차감은 반드시 트랜잭션 안에서 비관적 락을 잡고 수행한다.
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

    /**
     * 루나 차감. 잔액이 모자라면 {@link ErrorCode#LUNA_INSUFFICIENT}로 실패한다.
     * 호출부의 트랜잭션에 합류하도록 REQUIRED(기본) 전파를 사용한다.
     */
    @Transactional
    public void deduct(String userId, int amount, String reason, String refId) {
        deduct(userId, amount, reason, refId, "루나가 부족해요.");
    }

    /** 부족할 때 보여줄 문구는 호출부가 정한다(대화 신청 / 상점 구매 등 맥락이 다르다). */
    @Transactional
    public void deduct(String userId, int amount, String reason, String refId,
                        String insufficientMessage) {
        lunaMapper.ensureWallet(userId);
        Integer balance = lunaMapper.selectBalanceForUpdate(userId);
        int current = balance == null ? 0 : balance;
        if (current < amount) {
            throw new ApiException(ErrorCode.LUNA_INSUFFICIENT, HttpStatus.CONFLICT,
                    insufficientMessage);
        }
        lunaMapper.addBalance(userId, -amount);
        lunaMapper.insertTransaction(UUID.randomUUID().toString(), userId, -amount, reason, refId);
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
}
