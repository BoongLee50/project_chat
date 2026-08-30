package com.moonlighttalk.server.dailyquestion.controller;

import com.moonlighttalk.server.comment.dto.CommentDto;
import com.moonlighttalk.server.comment.dto.CreateCommentRequest;
import com.moonlighttalk.server.common.security.CurrentUserId;
import com.moonlighttalk.server.dailyquestion.dto.*;
import com.moonlighttalk.server.dailyquestion.service.DailyQuestionService;
import com.moonlighttalk.server.post.dto.UploadUrlResponse;
import jakarta.validation.Valid;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 달빛 한마디(기획서 8장, 01 문서 §1.9).
 *
 * <p>경로에 콘텐츠 이름을 넣지 않는다 — 이름이 바뀌어도 API는 그대로다(docs/12 §6 E).
 */
@RestController
public class DailyQuestionController {

    private final DailyQuestionService service;

    public DailyQuestionController(DailyQuestionService service) {
        this.service = service;
    }

    /** [타이틀] 화면 — 질문·참여 인원·남은 시간. lang은 질문 본문의 언어(ko|ja). */
    @GetMapping("/daily-question/today")
    public DailyQuestionTodayResponse today(@CurrentUserId String userId,
                                             @RequestParam(defaultValue = "ko") String lang) {
        return service.today(userId, lang);
    }

    /** 목록 — 최신순(기본) / 인기순. */
    @GetMapping("/daily-question/answers")
    public List<DailyAnswerDto> answers(
            @CurrentUserId String userId,
            @RequestParam(defaultValue = "LATEST") DailyAnswerSort sort,
            @RequestParam(defaultValue = "0") int page) {
        return service.answers(userId, sort, Math.max(0, page));
    }

    /** [내 한마디] — 없으면 404(화면이 안내 문구를 띄운다). */
    @GetMapping("/daily-question/answers/me")
    public DailyAnswerDto myAnswer(@CurrentUserId String userId) {
        return service.myAnswer(userId);
    }

    @GetMapping("/daily-question/answers/{answerId}")
    public DailyAnswerDto answer(@CurrentUserId String userId, @PathVariable String answerId) {
        return service.answer(userId, answerId);
    }

    @PostMapping("/daily-question/answers")
    public DailyAnswerDto write(@CurrentUserId String userId,
                                 @Valid @RequestBody CreateDailyAnswerRequest request) {
        return service.write(userId, request.body(), request.imageKey());
    }

    @PostMapping("/daily-question/answers/image:upload-url")
    public UploadUrlResponse issueImageUploadUrl(
            @CurrentUserId String userId,
            @RequestParam(defaultValue = MediaType.IMAGE_JPEG_VALUE) String contentType) {
        return service.issueImageUploadUrl(userId, contentType);
    }

    @PostMapping("/daily-question/answers/{answerId}/like")
    public void like(@CurrentUserId String userId, @PathVariable String answerId) {
        service.like(userId, answerId);
    }

    // ── 댓글은 포스트와 같은 규칙을 쓴다(3단계·50자·이미지 1장) ──

    @GetMapping("/daily-question/answers/{answerId}/comments")
    public List<CommentDto> comments(@PathVariable String answerId) {
        return service.comments(answerId);
    }

    @PostMapping("/daily-question/answers/{answerId}/comments")
    public void addComment(@CurrentUserId String userId,
                            @PathVariable String answerId,
                            @Valid @RequestBody CreateCommentRequest request) {
        service.addComment(userId, answerId, request.body(),
                request.parentId(), request.imageKey());
    }
}
