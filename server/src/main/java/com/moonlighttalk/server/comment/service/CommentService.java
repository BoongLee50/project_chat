package com.moonlighttalk.server.comment.service;

import com.moonlighttalk.server.comment.dto.CommentDto;
import com.moonlighttalk.server.comment.dto.CommentTarget;
import com.moonlighttalk.server.comment.entity.Comment;
import com.moonlighttalk.server.comment.mapper.CommentMapper;
import com.moonlighttalk.server.common.exception.ApiException;
import com.moonlighttalk.server.common.response.ErrorCode;
import com.moonlighttalk.server.common.storage.FileStorageService;
import com.moonlighttalk.server.post.dto.UploadUrlResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * 댓글 — <b>포스트와 달빛 한마디가 함께 쓴다</b>(기획 4-2 / 8-2 / 8-3).
 *
 * <p>세 화면의 규칙이 문장까지 같다: <b>3단계까지</b> · <b>50자</b> · <b>이미지 1장</b>.
 * 그래서 표도 판정도 한 벌만 둔다 — 두 벌이면 언젠가 조용히 갈라진다(docs/12 §6 C).
 *
 * <p>대상별로 다른 것(누가 댓글을 달 수 있는가, 집계를 어디에 더하는가)은
 * <b>호출부가 판단한다</b>. 이 클래스는 댓글 자체의 규칙만 안다.
 */
@Service
public class CommentService {

    private final CommentMapper commentMapper;
    private final FileStorageService fileStorageService;

    private final int maxLength;
    private final int maxDepth;

    public CommentService(CommentMapper commentMapper,
                           FileStorageService fileStorageService,
                           @Value("${app.comment.max-length:50}") int maxLength,
                           @Value("${app.comment.max-depth:3}") int maxDepth) {
        this.commentMapper = commentMapper;
        this.fileStorageService = fileStorageService;
        this.maxLength = maxLength;
        this.maxDepth = maxDepth;
    }

    /** 대상의 댓글 목록. <b>트리 순서로 평탄화</b>해서 준다. */
    public List<CommentDto> list(CommentTarget targetType, String targetId) {
        return threaded(commentMapper.selectByTarget(targetType, targetId)).stream()
                .map(this::toDto)
                .toList();
    }

    public int count(CommentTarget targetType, String targetId) {
        return commentMapper.countByTarget(targetType, targetId);
    }

    /** 대상 여러 건의 댓글 수를 한 번에(목록 화면의 N+1 방지). */
    public Map<String, Integer> countAll(CommentTarget targetType, List<String> targetIds) {
        if (targetIds.isEmpty()) {
            return Map.of();
        }
        Map<String, Integer> counts = new HashMap<>();
        for (Comment row : commentMapper.countByTargets(targetType, targetIds)) {
            counts.put(row.getTargetId(), row.getDepth()); // depth 칸에 개수를 담아 온다
        }
        return counts;
    }

    /** 첨부 이미지 업로드 URL. 포스트 사진과 같은 흐름(직접 업로드 후 키를 등록). */
    public UploadUrlResponse issueImageUploadUrl(String userId, String contentType) {
        String storageKey = imagePrefix(userId) + UUID.randomUUID() + extensionOf(contentType);
        return new UploadUrlResponse(
                fileStorageService.issueUploadUrl(storageKey, contentType), storageKey);
    }

    /**
     * 댓글/답글 작성. 길이·깊이·<b>답글 자격</b>·이미지 소유를 여기서 판정한다.
     *
     * @param ownerId 글쓴이(포스트 주인 또는 한마디 작성자). 답글 자격 판정에 쓴다
     * @return 만들어진 댓글 id
     */
    @Transactional
    public String add(CommentTarget targetType, String targetId, String ownerId,
                       String authorId, String body, String parentId, String imageKey) {
        if (body != null && body.length() > maxLength) {
            throw new ApiException(ErrorCode.COMMENT_TOO_LONG, HttpStatus.BAD_REQUEST,
                    "댓글이 너무 깁니다.", String.valueOf(maxLength));
        }
        int depth = resolveDepth(parentId, targetType, targetId, ownerId, authorId);
        requireMyImageKey(authorId, imageKey);

        Comment comment = new Comment();
        comment.setId(UUID.randomUUID().toString());
        comment.setTargetType(targetType);
        comment.setTargetId(targetId);
        comment.setAuthorId(authorId);
        comment.setBody(body);
        comment.setParentId(emptyToNull(parentId));
        comment.setDepth(depth);
        comment.setImageKey(emptyToNull(imageKey));
        commentMapper.insert(comment);
        return comment.getId();
    }

    // ── 내부 ────────────────────────────────────────────────

    private CommentDto toDto(Comment c) {
        return new CommentDto(
                c.getId(),
                c.getParentId(),
                c.getDepth(),
                c.getAuthorId(),
                c.getAuthorNickname(),
                c.getBody(),
                c.getImageKey() == null
                        ? null
                        : fileStorageService.issueDownloadUrl(c.getImageKey()),
                c.getCreatedAt());
    }

    /**
     * 부모를 확인하고 내 깊이를 정한다. 부모가 없으면 1단계.
     *
     * <p><b>한 스레드는 두 사람의 1:1 대화다</b> — <b>글쓴이</b>와 <b>그 스레드를 시작한 사람</b>.
     * 그래서 답글은 <b>번갈아</b> 달린다:
     * <pre>
     *   A가 글을 올림
     *   → B가 댓글(1단계)        스레드 시작 = B
     *   → A가 답글(2단계)        부모(B)의 상대 = A
     *   → B가 답글(3단계)        부모(A)의 상대 = B  … 여기까지
     * </pre>
     * 제3자 C는 <b>1단계 댓글로 새 스레드를 시작</b>할 수는 있지만 남의 스레드에는 끼어들지 못한다.
     *
     * <p>규칙을 한 줄로 줄이면 <b>"답글은 부모를 쓴 사람의 상대만 단다"</b>이고,
     * 상대란 {글쓴이, 스레드 시작한 사람} 중 부모의 작성자가 아닌 쪽이다.
     * 이 한 문장이 <i>자기 댓글에 자기가 답글 달기</i>와 <i>제3자 난입</i>을 동시에 막는다.
     */
    private int resolveDepth(String parentId, CommentTarget targetType, String targetId,
                              String ownerId, String authorId) {
        if (emptyToNull(parentId) == null) {
            return 1; // 1단계 댓글은 누구나 — 새 스레드를 여는 것이다
        }
        Comment parent = commentMapper.selectById(parentId);
        if (parent == null
                || parent.getTargetType() != targetType
                || !parent.getTargetId().equals(targetId)) {
            // 다른 글의 댓글에 답글을 달면 트리가 두 글에 걸친다.
            throw new ApiException(ErrorCode.COMMENT_PARENT_NOT_FOUND, HttpStatus.NOT_FOUND,
                    "답글을 달 댓글을 찾을 수 없어요.");
        }
        int depth = parent.getDepth() + 1;
        if (depth > maxDepth) {
            throw new ApiException(ErrorCode.COMMENT_DEPTH_EXCEEDED, HttpStatus.CONFLICT,
                    "답글은 " + maxDepth + "단계까지만 달 수 있어요.", String.valueOf(maxDepth));
        }
        requireCounterpart(parent, ownerId, authorId);
        return depth;
    }

    /** 답글을 달 자격 — 부모를 쓴 사람의 <b>상대</b>여야 한다. */
    private void requireCounterpart(Comment parent, String ownerId, String authorId) {
        if (parent.getAuthorId().equals(authorId)) {
            // 자기 말에 자기가 답글을 달면 대화가 아니라 연속된 혼잣말이 된다.
            throw replyNotAllowed();
        }
        String starterId = threadStarterId(parent);
        if (!authorId.equals(ownerId) && !authorId.equals(starterId)) {
            // 이 스레드의 두 사람이 아니다 — 새 스레드(1단계)로 시작해야 한다.
            throw replyNotAllowed();
        }
    }

    /** 스레드를 시작한 사람(1단계 댓글의 작성자). 깊이가 3까지라 한 번만 거슬러 올라가면 된다. */
    private String threadStarterId(Comment parent) {
        if (parent.getDepth() == 1) {
            return parent.getAuthorId();
        }
        Comment root = commentMapper.selectById(parent.getParentId());
        return root == null ? parent.getAuthorId() : root.getAuthorId();
    }

    private ApiException replyNotAllowed() {
        return new ApiException(ErrorCode.COMMENT_REPLY_NOT_ALLOWED, HttpStatus.FORBIDDEN,
                "답글은 글쓴이와 댓글을 단 사람이 번갈아 주고받을 수 있어요.");
    }

    /**
     * 첨부 이미지가 <b>내가 방금 올린 것</b>인지. 키에 업로더 id가 들어 있어 접두사로 판정한다
     * (음성 메시지와 같은 방식) — 남의 키를 그대로 붙여 넣는 것을 막는다.
     */
    private void requireMyImageKey(String userId, String imageKey) {
        if (emptyToNull(imageKey) == null) {
            return;
        }
        if (!imageKey.startsWith(imagePrefix(userId))) {
            throw new ApiException(ErrorCode.COMMENT_IMAGE_KEY_INVALID, HttpStatus.FORBIDDEN,
                    "첨부 이미지가 올바르지 않아요.");
        }
    }

    private static String imagePrefix(String userId) {
        return "comment-images/" + userId + "/";
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

    /**
     * 시간순 목록을 <b>트리 순서</b>로 다시 늘어놓는다 — 각 댓글 뒤에 그 답글이 붙는다.
     *
     * <p>SQL로 하려면 경로 컬럼이나 재귀 CTE가 필요한데 깊이가 3까지뿐이라
     * 여기서 한 번 도는 편이 단순하고 정확하다. 부모를 잃은 답글(있을 수 없지만)은 뒤에 붙인다.
     */
    private List<Comment> threaded(List<Comment> all) {
        Map<String, List<Comment>> children = new HashMap<>();
        List<Comment> roots = new ArrayList<>();
        for (Comment c : all) {
            if (c.getParentId() == null) {
                roots.add(c);
            } else {
                children.computeIfAbsent(c.getParentId(), k -> new ArrayList<>()).add(c);
            }
        }

        List<Comment> ordered = new ArrayList<>(all.size());
        for (Comment root : roots) {
            appendWithChildren(root, children, ordered);
        }
        if (ordered.size() < all.size()) {
            Set<String> placed = new HashSet<>();
            for (Comment c : ordered) {
                placed.add(c.getId());
            }
            for (Comment c : all) {
                if (!placed.contains(c.getId())) {
                    ordered.add(c);
                }
            }
        }
        return ordered;
    }

    private void appendWithChildren(Comment node, Map<String, List<Comment>> children,
                                     List<Comment> out) {
        out.add(node);
        for (Comment child : children.getOrDefault(node.getId(), List.of())) {
            appendWithChildren(child, children, out);
        }
    }
}
