package com.moonlighttalk.server.comment.mapper;

import com.moonlighttalk.server.comment.dto.CommentTarget;
import com.moonlighttalk.server.comment.entity.Comment;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDate;
import java.util.List;

@Mapper
public interface CommentMapper {

    /** 대상의 댓글 전부(시간순). 트리 정렬은 서비스가 한다 — 깊이가 3까지뿐이다. */
    List<Comment> selectByTarget(@Param("targetType") CommentTarget targetType,
                                  @Param("targetId") String targetId);

    int countByTarget(@Param("targetType") CommentTarget targetType,
                       @Param("targetId") String targetId);

    /** 여러 대상의 댓글 수를 한 번에(목록 화면에서 N+1을 피한다). */
    List<Comment> countByTargets(@Param("targetType") CommentTarget targetType,
                                  @Param("targetIds") List<String> targetIds);

    /** 답글을 달 부모 댓글(없으면 null). */
    Comment selectById(@Param("commentId") String commentId);

    void insert(Comment comment);

    /**
     * 주인이 사라진 댓글 정리(V14).
     *
     * <p>대상이 두 종류가 되며 posts로 걸려 있던 FK가 사라졌다 —
     * 포스트가 지워져도 댓글이 남으므로 배치가 치운다.
     */
    int deleteOrphans(@Param("sessionDate") LocalDate sessionDate);
}
