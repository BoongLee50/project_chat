package com.moonlighttalk.server.common.response;

/** 01 문서 공통 규약의 에러 응답 형태: { "code", "message", "field" } */
public record ErrorResponse(String code, String message, String field) {

    public static ErrorResponse of(ErrorCode code, String message) {
        return new ErrorResponse(code.name(), message, null);
    }

    public static ErrorResponse of(ErrorCode code, String message, String field) {
        return new ErrorResponse(code.name(), message, field);
    }
}
