package com.moonlighttalk.server.post.mapper;

import com.moonlighttalk.server.post.entity.Post;
import com.moonlighttalk.server.post.entity.PostPhoto;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Mapper
public interface PostMapper {

    Post selectByUserAndDate(@Param("userId") String userId, @Param("sessionDate") LocalDate sessionDate);

    void insertPost(Post post);

    void updateWindowStartedAt(@Param("postId") String postId, @Param("startedAt") LocalDateTime startedAt);

    void updateOneLiner(@Param("postId") String postId, @Param("oneLiner") String oneLiner);

    void updatePublishedAt(@Param("postId") String postId, @Param("publishedAt") LocalDateTime publishedAt);

    void incrementReplaceCount(@Param("postId") String postId);

    List<PostPhoto> selectPhotos(@Param("postId") String postId);

    PostPhoto selectPhotoById(@Param("photoId") String photoId);

    /**
     * 사진·한마디가 바뀐 시각을 찍는다(V8).
     *
     * <p>내가 스킵한 상대라도 <b>갱신하면 피드에 다시 보여야</b> 하는데(기획 4-1),
     * 그 판정 기준이 이 값이다. post_photos.created_at으로는 삭제·교체를 잡을 수 없다.
     */
    void touchContentUpdatedAt(@Param("postId") String postId);

    void insertPhoto(PostPhoto photo);

    void deletePhoto(@Param("photoId") String photoId);

    int countPhotos(@Param("postId") String postId);

    Integer selectMaxOrderIdx(@Param("postId") String postId);
}
