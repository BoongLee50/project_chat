package com.moonlighttalk.server.garden.service;

import com.moonlighttalk.server.auth.service.SessionTimeService;
import com.moonlighttalk.server.chat.mapper.ChatMapper;
import com.moonlighttalk.server.garden.config.TranslateProperties;
import com.moonlighttalk.server.garden.dto.TranslateAccessDto;
import com.moonlighttalk.server.garden.mapper.GardenMapper;
import com.moonlighttalk.server.garden.translate.TranslationProvider;
import com.moonlighttalk.server.luna.service.LunaService;
import com.moonlighttalk.server.store.entity.Entitlement;
import com.moonlighttalk.server.store.service.EntitlementService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;

/**
 * 무료 번역 자리를 잡는 곳(기획 4-2 · 5장 · 8-3).
 *
 * <p>🚨 <b>자리마다 세는 단위가 다르다</b> — 이것이 이 클래스가 따로 있는 이유다.
 * <ul>
 *   <li><b>댓글창</b>: *"댓글창 5회 <b>호출</b>까지 무료"*. 창을 열 때 하나 쓰고,
 *       그 창 안의 댓글은 몇 개든 번역된다. 영업일마다 다시 채워진다.</li>
 *   <li><b>대화방</b>: *"[대화방]은 5개까지 무료. <b>대화방 삭제 전까지</b> 계속"*.
 *       날짜가 아니라 <b>동시에 열어 둔 방의 수</b>다 — 방이 끝나면 자리가 빈다.</li>
 * </ul>
 *
 * <p>⑦단계 전에는 둘 다 "하루 2회"였고 댓글은 번역 <b>건수</b>를 셌다.
 * 값도 단위도 기획서와 달랐다.
 *
 * <p>🚨 <b>공급자가 없으면 자리를 쓰지 않는다.</b> 지금 {@code provider: none}이라
 * 번역해도 원문이 그대로 나온다 — 그 상태로 쿼터만 깎으면 사용자는 아무것도 못 받고
 * 무료 횟수만 잃는다.
 */
@Service
public class TranslateAccessService {

    /** 댓글창 호출 카운터의 kind. `daily_usage`에 쌓인다. */
    public static final String USAGE_COMMENT_OPEN = "COMMENT_TRANSLATE";

    private static final String PROVIDER_NONE = "none";

    private final TranslateProperties properties;
    private final TranslationProvider provider;
    private final EntitlementService entitlementService;
    private final LunaService lunaService;
    private final SessionTimeService sessionTime;
    private final GardenMapper gardenMapper;
    private final ChatMapper chatMapper;

    public TranslateAccessService(TranslateProperties properties,
                                   TranslationProvider provider,
                                   EntitlementService entitlementService,
                                   LunaService lunaService,
                                   SessionTimeService sessionTime,
                                   GardenMapper gardenMapper,
                                   ChatMapper chatMapper) {
        this.properties = properties;
        this.provider = provider;
        this.entitlementService = entitlementService;
        this.lunaService = lunaService;
        this.sessionTime = sessionTime;
        this.gardenMapper = gardenMapper;
        this.chatMapper = chatMapper;
    }

    /** 실제로 번역이 되는 상태인가. 아니면 자리를 쓰지 않는다. */
    public boolean providerReady() {
        return !PROVIDER_NONE.equals(provider.name());
    }

    /**
     * 댓글창을 연다 — 자리를 하나 쓴다(기획 4-2 · 8-3).
     *
     * <p>포스트 댓글과 달빛 한마디가 <b>같은 통</b>을 쓴다. 기획서의 두 문장이
     * 글자까지 같고("댓글창 5회 호출까지 무료"), 사용자에게도 같은 기능이다.
     */
    @Transactional
    public TranslateAccessDto openCommentSheet(String userId) {
        if (unlimited(userId)) {
            return unlimitedAccess(userId, properties.getFreeCommentOpens());
        }
        if (!providerReady()) {
            // 번역이 안 되는데 자리를 깎지 않는다. 화면에는 "지금은 안 된다"로 보인다.
            return denied(properties.getFreeCommentOpens(),
                    remainingCommentOpens(userId));
        }

        int remaining = remainingCommentOpens(userId);
        if (remaining <= 0) {
            return denied(properties.getFreeCommentOpens(), 0);
        }
        lunaService.useDaily(userId, sessionTime.currentSessionDate(), USAGE_COMMENT_OPEN);
        return new TranslateAccessDto(true, false, remaining - 1,
                properties.getFreeCommentOpens(), provider.name(), null);
    }

    /**
     * 대화방에 들어간다 — 이미 열어 둔 방이면 그냥 통과, 아니면 새 자리를 쓴다.
     *
     * <p>*"대화방 삭제 전까지 계속 번역 지원"* — 한 번 연 방은 끝날 때까지 무료다.
     * 그래서 자리를 세는 기준이 <b>살아 있는 방의 수</b>다.
     */
    @Transactional
    public TranslateAccessDto openChatRoom(String userId, String roomId) {
        int free = properties.getFreeChatRooms();
        if (unlimited(userId)) {
            return unlimitedAccess(userId, free);
        }

        boolean alreadyOpen = gardenMapper.existsTranslateRoom(userId, roomId);
        if (alreadyOpen) {
            // 이미 산 자리다 — 공급자가 잠깐 없어도 이 방은 계속 열려 있는 것으로 본다.
            return new TranslateAccessDto(providerReady(), false,
                    Math.max(0, free - countOpenRooms(userId)), free, provider.name(), null);
        }
        if (!providerReady()) {
            return denied(free, Math.max(0, free - countOpenRooms(userId)));
        }

        int used = countOpenRooms(userId);
        if (used >= free) {
            return denied(free, 0);
        }
        gardenMapper.insertTranslateRoom(userId, roomId);
        return new TranslateAccessDto(true, false, Math.max(0, free - (used + 1)),
                free, provider.name(), null);
    }

    /** 지금 상태만 본다(자리를 쓰지 않는다) — 버튼 문구를 그릴 때. */
    public TranslateAccessDto peekCommentSheet(String userId) {
        if (unlimited(userId)) {
            return unlimitedAccess(userId, properties.getFreeCommentOpens());
        }
        int remaining = remainingCommentOpens(userId);
        return new TranslateAccessDto(providerReady() && remaining > 0, false, remaining,
                properties.getFreeCommentOpens(), provider.name(), null);
    }

    // ── 내부 ────────────────────────────────────────────────

    private boolean unlimited(String userId) {
        return entitlementService.hasTranslatePass(userId)
                || entitlementService.isPrime(userId);
    }

    /**
     * 무제한 상태. 패스로 무제한이면 <b>남은 시간</b>을 함께 준다 —
     * 시안이 *"구매 후 남은 시간 표시는 일, 시간, 분으로"* 라고 했다.
     */
    private TranslateAccessDto unlimitedAccess(String userId, int free) {
        Entitlement pass = entitlementService.activeEntitlement(
                userId, EntitlementService.TRANSLATE_PASS);
        Long minutes = pass == null || pass.getExpiresAt() == null
                ? null
                : Math.max(0, Duration.between(LocalDateTime.now(), pass.getExpiresAt())
                        .toMinutes());
        return new TranslateAccessDto(providerReady(), true, 0, free, provider.name(), minutes);
    }

    private TranslateAccessDto denied(int free, int remaining) {
        return new TranslateAccessDto(false, false, remaining, free, provider.name(), null);
    }

    private int remainingCommentOpens(String userId) {
        int used = lunaService.dailyUsed(
                userId, sessionTime.currentSessionDate(), USAGE_COMMENT_OPEN);
        return Math.max(0, properties.getFreeCommentOpens() - used);
    }

    /** 열어 둔 방 중 **아직 살아 있는** 것만 센다. 끝난 방은 자리를 돌려준다. */
    private int countOpenRooms(String userId) {
        return chatMapper.countActiveTranslateRooms(userId);
    }
}
