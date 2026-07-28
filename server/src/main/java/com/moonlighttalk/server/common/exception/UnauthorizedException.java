package com.moonlighttalk.server.common.exception;

import com.moonlighttalk.server.common.response.ErrorCode;
import org.springframework.http.HttpStatus;

public class UnauthorizedException extends ApiException {

    public UnauthorizedException(String message) {
        super(ErrorCode.UNAUTHORIZED, HttpStatus.UNAUTHORIZED, message);
    }
}
