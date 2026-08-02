package com.moonlighttalk.server.friend.mapper;

import com.moonlighttalk.server.friend.entity.FriendPost;
import com.moonlighttalk.server.friend.entity.FriendSummary;
import com.moonlighttalk.server.friend.entity.Friendship;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Mapper
public interface FriendMapper {

    void insert(Friendship friendship);

    Friendship selectById(@Param("id") String id);

    /** 방향과 무관하게 두 사람의 관계 1건(요청 중이든 성립이든). */
    Friendship selectByPairKey(@Param("pairKey") String pairKey);

    void accept(@Param("id") String id, @Param("acceptedAt") LocalDateTime acceptedAt);

    /** 거절·친구삭제는 행 자체를 지운다(status에 REJECTED가 없다 — 02 §1.6). */
    void delete(@Param("id") String id);

    /** 내 친구 목록(ACCEPTED). 필터는 모두 선택. */
    List<FriendSummary> selectFriends(@Param("userId") String userId,
                                       @Param("gender") String gender,
                                       @Param("ageMin") Integer ageMin,
                                       @Param("ageMax") Integer ageMax,
                                       @Param("country") String country);

    /** 내가 받은 친구 요청(PENDING). */
    List<Friendship> selectReceivedRequests(@Param("userId") String userId);

    /** 내가 보낸 친구 요청(PENDING). */
    List<Friendship> selectSentRequests(@Param("userId") String userId);

    /** 성립된 친구 수(최대 친구 수 제한 검사용). */
    int countFriends(@Param("userId") String userId);

    /** 친구의 오늘 포스트(공유한 것만). 없으면 null. */
    FriendPost selectTodayPost(@Param("userId") String userId,
                                @Param("sessionDate") LocalDate sessionDate);
}
