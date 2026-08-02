package com.moonlighttalk.server.moderation.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * 신고. reason은 화면에서 고른 사유 코드(01 문서 §1.7).
 * 자유 서술이 아니라 코드로 받는 이유는 집계·운영 대응을 위해서다.
 */
public record CreateReportRequest(
        @NotBlank String targetUserId,
        @NotBlank @Size(max = 500) String reason,
        @Size(max = 500) String detail
) {
}
