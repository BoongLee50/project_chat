package com.moonlighttalk.server.luna.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDate;

@Mapper
public interface LunaMapper {

    /** 지갑이 없으면 만든다(잔액 0). */
    void ensureWallet(@Param("userId") String userId);

    /** 비관적 락(FOR UPDATE) — 동시 차감으로 잔액이 음수가 되는 것을 막는다(05 문서 §3). */
    Integer selectBalanceForUpdate(@Param("userId") String userId);

    Integer selectBalance(@Param("userId") String userId);

    void addBalance(@Param("userId") String userId, @Param("delta") int delta);

    void insertTransaction(@Param("id") String id,
                            @Param("userId") String userId,
                            @Param("delta") int delta,
                            @Param("reason") String reason,
                            @Param("refId") String refId);

    /** 일일 무료 쿼터 사용량(없으면 0). */
    int selectDailyUsage(@Param("userId") String userId,
                          @Param("sessionDate") LocalDate sessionDate,
                          @Param("kind") String kind);

    /** 원자적 증가(동시 요청 시 lost update 방지). */
    void incrementDailyUsage(@Param("userId") String userId,
                              @Param("sessionDate") LocalDate sessionDate,
                              @Param("kind") String kind);
}
