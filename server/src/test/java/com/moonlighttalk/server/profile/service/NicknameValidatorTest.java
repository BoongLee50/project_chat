package com.moonlighttalk.server.profile.service;

import com.moonlighttalk.server.auth.mapper.UserMapper;
import com.moonlighttalk.server.common.exception.ApiException;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class NicknameValidatorTest {

    private final UserMapper userMapper = mock(UserMapper.class);
    private final NicknameValidator validator =
            new NicknameValidator(userMapper, List.of("관리자", "admin"));

    @Test
    void 한글_영문_숫자_10자_이내는_통과한다() {
        validator.validateFormat("달빛나그네12");
    }

    @Test
    void 특수문자가_포함되면_실패한다() {
        assertThatThrownBy(() -> validator.validateFormat("달빛!"))
                .isInstanceOf(ApiException.class);
    }

    @Test
    void 열자를_초과하면_실패한다() {
        assertThatThrownBy(() -> validator.validateFormat("가나다라마바사아자차카"))
                .isInstanceOf(ApiException.class);
    }

    @Test
    void 금지어는_대소문자_구분없이_실패한다() {
        assertThatThrownBy(() -> validator.validateFormat("Admin"))
                .isInstanceOf(ApiException.class);
    }

    @Test
    void 이미_존재하는_닉네임은_사용불가로_판정한다() {
        when(userMapper.countByNickname("중복닉네임")).thenReturn(1);

        assertThat(validator.isAvailable("중복닉네임")).isFalse();
    }

    @Test
    void 존재하지_않는_닉네임은_사용가능으로_판정한다() {
        when(userMapper.countByNickname("새닉네임")).thenReturn(0);

        assertThat(validator.isAvailable("새닉네임")).isTrue();
    }
}
