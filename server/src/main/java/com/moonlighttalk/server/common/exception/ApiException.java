package com.moonlighttalk.server.common.exception;

import com.moonlighttalk.server.common.response.ErrorCode;
import lombok.Getter;
import org.springframework.http.HttpStatus;

@Getter
public class ApiException extends RuntimeException {

    private final ErrorCode code;
    private final HttpStatus status;
    private final String field;

    public ApiException(ErrorCode code, HttpStatus status, String message) {
        this(code, status, message, null);
    }

    public ApiException(ErrorCode code, HttpStatus status, String message, String field) {
        super(message);
        this.code = code;
        this.status = status;
        this.field = field;
    }
}
