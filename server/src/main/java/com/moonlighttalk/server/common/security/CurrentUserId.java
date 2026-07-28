package com.moonlighttalk.server.common.security;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/** 컨트롤러 메서드 파라미터에 붙이면 AuthContext.currentUserId()를 자동 주입(CurrentUserArgumentResolver). */
@Target(ElementType.PARAMETER)
@Retention(RetentionPolicy.RUNTIME)
public @interface CurrentUserId {
}
