package com.moonlighttalk.server.moderation.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface ModerationMapper {

    void insertReport(@Param("id") String id,
                       @Param("reporterId") String reporterId,
                       @Param("targetId") String targetId,
                       @Param("reason") String reason);

    /** 이미 차단했다면 아무 일도 하지 않는다(유니크 위반 대신 조용히 통과). */
    int insertBlock(@Param("id") String id,
                     @Param("blockerId") String blockerId,
                     @Param("blockedId") String blockedId);

    boolean existsBlock(@Param("blockerId") String blockerId,
                         @Param("blockedId") String blockedId);
}
