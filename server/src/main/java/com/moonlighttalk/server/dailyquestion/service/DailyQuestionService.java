package com.moonlighttalk.server.dailyquestion.service;

import com.moonlighttalk.server.auth.service.SessionTimeService;
import com.moonlighttalk.server.comment.dto.CommentDto;
import com.moonlighttalk.server.comment.dto.CommentTarget;
import com.moonlighttalk.server.comment.service.CommentService;
import com.moonlighttalk.server.common.exception.ApiException;
import com.moonlighttalk.server.common.response.ErrorCode;
import com.moonlighttalk.server.common.storage.FileStorageService;
import com.moonlighttalk.server.dailyquestion.dto.*;
import com.moonlighttalk.server.dailyquestion.entity.DailyAnswer;
import com.moonlighttalk.server.dailyquestion.entity.DailyQuestion;
import com.moonlighttalk.server.dailyquestion.mapper.DailyQuestionMapper;
import com.moonlighttalk.server.post.dto.UploadUrlResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * 달빛 한마디 이벤트(기획서 8장).
 *
 * <p>매일 질문 하나에 <b>한마디(100자) + 사진 1장(선택)</b> 으로 답하고 서로 본다.
 * <b>KST 18시에 모든 정보가 초기화</b>되고 새 질문이 나온다 — ①단계의 영업일 경계와 <b>같은 시계</b>다
 * ({@code app.session.rollover-hour}). 화면 문구도 "매일 저녁 6시에 새로운 미션이 열려요"다.
 *
 * <p><b>댓글은 만들지 않았다.</b> 기획서 8-2·8-3의 댓글 규칙이 4-2와 문장까지 같아
 * {@link CommentService}를 그대로 쓴다(3단계·50자·이미지 1장).
 *
 * <p>🚨 클래스·테이블·API 이름에 콘텐츠를 넣지 않았다 — "달빛우편"이 "달빛 한마디"가 된 전례가 있다.
 * 이름이 또 바뀌면 <b>ARB 문구만</b> 고치면 된다(docs/12 §6 E).
 */
@Service
public class DailyQuestionService {

    private static final int PAGE_SIZE = 20;

    private final DailyQuestionMapper mapper;
    private final CommentService commentService;
    private final SessionTimeService sessionTime;
    private final FileStorageService fileStorageService;

    private final int maxLength;

    public DailyQuestionService(DailyQuestionMapper mapper,
                                 CommentService commentService,
                                 SessionTimeService sessionTime,
                                 FileStorageService fileStorageService,
                                 @Value("${app.daily-question.max-length:100}") int maxLength) {
        this.mapper = mapper;
        this.commentService = commentService;
        this.sessionTime = sessionTime;
        this.fileStorageService = fileStorageService;
        this.maxLength = maxLength;
    }

    /** [타이틀] 화면 — 오늘의 질문 · 참여 인원 · 남은 시간 · 내가 답했는지. */
    @Transactional
    public DailyQuestionTodayResponse today(String userId, String lang) {
        DailyQuestion question = requireTodayQuestion();
        DailyAnswer mine = mapper.selectMyAnswer(question.getId(), userId);

        return new DailyQuestionTodayResponse(
                question.getId(),
                question.bodyFor(lang),
                mapper.countAnswers(question.getId()),
                secondsUntilRollover(),
                mine != null,
                mine == null ? null : mine.getId());
    }

    /** 목록(기획 8-1). 기본 최신순, 인기순은 <b>좋아요 + 댓글 합</b>. */
    @Transactional
    public List<DailyAnswerDto> answers(String userId, DailyAnswerSort sort, int page) {
        DailyQuestion question = requireTodayQuestion();
        List<DailyAnswer> rows = mapper.selectAnswers(
                question.getId(), userId, sort.name(), page * PAGE_SIZE, PAGE_SIZE);
        return toDtos(rows, userId);
    }

    /** 상세(기획 8-2). */
    @Transactional
    public DailyAnswerDto answer(String userId, String answerId) {
        DailyAnswer row = mapper.selectAnswerById(answerId, userId);
        if (row == null) {
            throw notFound();
        }
        return toDtos(List.of(row), userId).get(0);
    }

    /** [내 한마디] — 없으면 404. 화면은 이 코드로 안내 문구를 띄운다. */
    @Transactional
    public DailyAnswerDto myAnswer(String userId) {
        DailyQuestion question = requireTodayQuestion();
        DailyAnswer mine = mapper.selectMyAnswer(question.getId(), userId);
        if (mine == null) {
            throw new ApiException(ErrorCode.DAILY_ANSWER_NOT_YET, HttpStatus.NOT_FOUND,
                    "아직 작성한 내 한마디가 없어요.");
        }
        return answer(userId, mine.getId());
    }

    /** 메인 이미지 업로드 URL(1장, 선택). */
    public UploadUrlResponse issueImageUploadUrl(String userId, String contentType) {
        String storageKey = imagePrefix(userId) + UUID.randomUUID() + extensionOf(contentType);
        return new UploadUrlResponse(
                fileStorageService.issueUploadUrl(storageKey, contentType), storageKey);
    }

    /** 작성(기획 8-3). 하루에 한 번만 — 두 번째는 DB 유니크가 막고 여기서 먼저 걸러 준다. */
    @Transactional
    public DailyAnswerDto write(String userId, String body, String imageKey) {
        if (body != null && body.length() > maxLength) {
            throw new ApiException(ErrorCode.DAILY_ANSWER_TOO_LONG, HttpStatus.BAD_REQUEST,
                    "한마디가 너무 깁니다.", String.valueOf(maxLength));
        }
        requireMyImageKey(userId, imageKey);

        DailyQuestion question = requireTodayQuestion();
        if (mapper.selectMyAnswer(question.getId(), userId) != null) {
            throw new ApiException(ErrorCode.DAILY_ANSWER_ALREADY, HttpStatus.CONFLICT,
                    "오늘은 이미 한마디를 남겼어요.");
        }

        DailyAnswer answer = new DailyAnswer();
        answer.setId(UUID.randomUUID().toString());
        answer.setQuestionId(question.getId());
        answer.setUserId(userId);
        answer.setSessionDate(question.getSessionDate());
        answer.setBody(body);
        answer.setImageKey(emptyToNull(imageKey));
        mapper.insertAnswer(answer);

        return answer(userId, answer.getId());
    }

    /** 좋아요(기획 8-2). 사람마다 한 번 — 두 번 눌러도 수치가 늘지 않는다. */
    @Transactional
    public void like(String userId, String answerId) {
        if (mapper.selectAnswerById(answerId, userId) == null) {
            throw notFound();
        }
        mapper.insertLike(answerId, userId);
    }

    // ── 댓글은 공용을 그대로 쓴다 ──────────────────────────────

    public List<CommentDto> comments(String answerId) {
        return commentService.list(CommentTarget.DAILY_ANSWER, answerId);
    }

    @Transactional
    public void addComment(String userId, String answerId, String body,
                            String parentId, String imageKey) {
        DailyAnswer answer = mapper.selectAnswerById(answerId, userId);
        if (answer == null) {
            throw notFound();
        }
        // 글쓴이는 한마디를 쓴 사람이다 — 답글은 그와 스레드 시작자가 번갈아 단다.
        commentService.add(CommentTarget.DAILY_ANSWER, answerId, answer.getUserId(),
                userId, body, parentId, imageKey);
    }

    // ── 내부 ────────────────────────────────────────────────

    /**
     * 오늘의 질문. 없으면 후보에서 하나 꺼내 만든다.
     *
     * <p>배치로 미리 만들지 않는 이유 — 배치가 한 번 실패하면 그날 이벤트가 통째로 비어 버린다.
     * <b>처음 들여다보는 사람이 만들게</b> 두면 그런 구멍이 없다.
     * 동시에 들어와도 {@code session_date} 유니크와 {@code INSERT IGNORE}가 하나만 남긴다.
     */
    private DailyQuestion requireTodayQuestion() {
        LocalDate sessionDate = sessionTime.currentSessionDate();
        DailyQuestion today = mapper.selectQuestionByDate(sessionDate);
        if (today != null) {
            return today;
        }

        DailyQuestion picked = mapper.selectUnusedFromBank();
        if (picked == null) {
            throw new ApiException(ErrorCode.DAILY_QUESTION_NOT_READY, HttpStatus.NOT_FOUND,
                    "오늘의 질문이 아직 준비되지 않았어요.");
        }
        DailyQuestion created = new DailyQuestion();
        created.setId(UUID.randomUUID().toString());
        created.setSessionDate(sessionDate);
        created.setBodyKo(picked.getBodyKo());
        created.setBodyJa(picked.getBodyJa());
        mapper.insertQuestion(created);

        // 같은 순간 다른 요청이 먼저 넣었을 수 있으니 **다시 읽어** 그쪽 것을 쓴다.
        return mapper.selectQuestionByDate(sessionDate);
    }

    /**
     * 다음 초기화(경계 시각)까지 남은 초.
     *
     * <p><b>서버가 계산해서 준다</b> — 기기 시계를 믿으면 사람마다 다른 시간이 보인다.
     * 경계는 영업일과 같은 값이라 {@code currentSessionDate() + 1일}의 경계 시각이 다음 초기화다.
     */
    private long secondsUntilRollover() {
        LocalDateTime now = sessionTime.nowKst().toLocalDateTime();
        LocalDateTime next = sessionTime.currentSessionDate()
                .plusDays(1)
                .atTime(sessionTime.rolloverHour(), 0);
        return Math.max(0, ChronoUnit.SECONDS.between(now, next));
    }

    private List<DailyAnswerDto> toDtos(List<DailyAnswer> rows, String viewerId) {
        List<String> ids = rows.stream().map(DailyAnswer::getId).toList();
        Map<String, Integer> commentCounts =
                commentService.countAll(CommentTarget.DAILY_ANSWER, ids);

        int year = sessionTime.nowKst().getYear();
        List<DailyAnswerDto> out = new ArrayList<>(rows.size());
        for (DailyAnswer a : rows) {
            out.add(new DailyAnswerDto(
                    a.getId(),
                    a.getUserId(),
                    a.getNickname(),
                    a.getBirthYear() == null ? null : year - a.getBirthYear(),
                    a.getCountry(),
                    a.getBody(),
                    a.getImageKey() == null
                            ? null
                            : fileStorageService.issueDownloadUrl(a.getImageKey()),
                    a.getLikes(),
                    commentCounts.getOrDefault(a.getId(), 0),
                    a.isLikedByMe(),
                    a.getUserId().equals(viewerId),
                    a.getCreatedAt()));
        }
        return out;
    }

    private void requireMyImageKey(String userId, String imageKey) {
        if (emptyToNull(imageKey) == null) {
            return;
        }
        if (!imageKey.startsWith(imagePrefix(userId))) {
            throw new ApiException(ErrorCode.DAILY_ANSWER_IMAGE_KEY_INVALID, HttpStatus.FORBIDDEN,
                    "첨부 이미지가 올바르지 않아요.");
        }
    }

    private ApiException notFound() {
        return new ApiException(ErrorCode.DAILY_ANSWER_NOT_FOUND, HttpStatus.NOT_FOUND,
                "한마디를 찾을 수 없어요.");
    }

    private static String imagePrefix(String userId) {
        return "daily-answers/" + userId + "/";
    }

    private static String extensionOf(String contentType) {
        if (contentType == null) {
            return "";
        }
        return switch (contentType) {
            case "image/png" -> ".png";
            case "image/webp" -> ".webp";
            default -> ".jpg";
        };
    }

    private static String emptyToNull(String value) {
        return (value == null || value.isBlank()) ? null : value;
    }
}
