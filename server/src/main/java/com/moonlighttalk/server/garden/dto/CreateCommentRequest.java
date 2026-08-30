package com.moonlighttalk.server.garden.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * 댓글 작성(기획서 4-2). 최대 <b>50자</b>, <b>3단계</b>까지, 이미지 <b>1장</b>.
 *
 * <p>⚠️ 길이 검사를 {@code @Size}로 하지 않는다. 애노테이션에는 상수만 쓸 수 있어
 * <b>50이 코드에 굳어 버리고</b> 설정({@code app.comment.max-length})과 따로 놀게 된다.
 * 게다가 걸리면 일반 {@code VALIDATION_FAILED}가 나가서, 기획서가 지정한
 * <i>"댓글은 50자까지 입력할 수 있어요"</i> 를 만들 수 없다.
 * 길이는 서비스가 설정값으로 판정하고 {@code COMMENT_TOO_LONG}에 숫자를 실어 보낸다.
 *
 * @param parentId 답글을 달 부모 댓글. 1단계 댓글이면 null
 * @param imageKey 업로드를 마친 첨부 이미지의 스토리지 키(선택)
 */
public record CreateCommentRequest(
        @NotBlank String body,
        String parentId,
        String imageKey
) {
}
