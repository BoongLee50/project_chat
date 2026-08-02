package com.moonlighttalk.server.scheduler.service;

import com.moonlighttalk.server.scheduler.mapper.SchedulerMapper;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 보관 만료 메시지를 배치 크기만큼 끊어서 지운다.
 *
 * <p>별도 빈으로 둔 이유: {@code @Transactional}은 프록시로 동작해 <b>같은 빈 안에서 호출하면
 * 적용되지 않는다</b>. 반복 호출하는 쪽({@link SchedulerService})과 트랜잭션 단위를 분리해야 한다.
 */
@Component
public class MessageRetentionPurger {

    private final SchedulerMapper schedulerMapper;

    public MessageRetentionPurger(SchedulerMapper schedulerMapper) {
        this.schedulerMapper = schedulerMapper;
    }

    /** 한 묶음 삭제. 지운 행 수를 돌려주며, 배치 크기보다 적으면 남은 게 없다는 뜻이다. */
    @Transactional
    public int purgeBatch(LocalDateTime matchBefore, LocalDateTime friendBefore, int batchSize) {
        List<String> ids = schedulerMapper.selectExpiredMessageIds(matchBefore, friendBefore, batchSize);
        if (ids.isEmpty()) {
            return 0;
        }
        return schedulerMapper.deleteMessagesByIds(ids);
    }
}
