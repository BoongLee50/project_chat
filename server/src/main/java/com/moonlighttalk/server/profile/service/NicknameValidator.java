package com.moonlighttalk.server.profile.service;

import com.moonlighttalk.server.auth.mapper.UserMapper;
import com.moonlighttalk.server.common.exception.ApiException;
import com.moonlighttalk.server.common.response.ErrorCode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.regex.Pattern;

/**
 * 닉네임 규칙: 특수문자·이모지 불가 / 10자 이내 / 중복 불가 / 금지어(01 문서 §1.2).
 * 금지어 목록은 app.profile.forbidden-nicknames 설정으로 관리(작은 규모라 DB 테이블 대신 설정 파일 사용).
 */
@Component
public class NicknameValidator {

    private static final Pattern ALLOWED =
            Pattern.compile("^[\\p{IsHangul}\\p{IsHan}\\p{IsKatakana}\\p{IsHiragana}a-zA-Z0-9]{1,10}$");

    private final UserMapper userMapper;
    private final List<String> forbiddenNicknames;

    public NicknameValidator(UserMapper userMapper,
                              @Value("${app.profile.forbidden-nicknames:}") List<String> forbiddenNicknames) {
        this.userMapper = userMapper;
        this.forbiddenNicknames = forbiddenNicknames;
    }

    public void validateFormat(String nickname) {
        if (nickname == null || !ALLOWED.matcher(nickname).matches()) {
            throw new ApiException(ErrorCode.NICKNAME_INVALID, HttpStatus.BAD_REQUEST,
                    "닉네임은 특수문자·이모지 없이 10자 이내여야 합니다.", "nickname");
        }
        if (forbiddenNicknames.stream().anyMatch(f -> f.equalsIgnoreCase(nickname))) {
            throw new ApiException(ErrorCode.NICKNAME_INVALID, HttpStatus.BAD_REQUEST,
                    "사용할 수 없는 닉네임입니다.", "nickname");
        }
    }

    /** @return 사용 가능 여부(예외를 던지지 않고 boolean으로 반환 — 중복 체크 API용) */
    public boolean isAvailable(String nickname) {
        try {
            validateFormat(nickname);
        } catch (ApiException e) {
            return false;
        }
        return userMapper.countByNickname(nickname) == 0;
    }

    /** 프로필 생성/수정 시 사용 — 실패하면 예외로 중단 */
    public void validateAvailableOrThrow(String nickname) {
        validateFormat(nickname);
        if (userMapper.countByNickname(nickname) > 0) {
            throw new ApiException(ErrorCode.NICKNAME_DUPLICATE, HttpStatus.CONFLICT,
                    "이미 사용 중인 닉네임입니다.", "nickname");
        }
    }
}
