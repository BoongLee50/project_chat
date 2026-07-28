package com.moonlighttalk.server.common.security;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/** 인증 없이 접근을 허용하는 컨트롤러 메서드/클래스에 부착(05 문서 §11). */
@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
public @interface NoAuth {
}
