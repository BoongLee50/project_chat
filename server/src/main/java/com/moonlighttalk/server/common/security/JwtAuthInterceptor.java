package com.moonlighttalk.server.common.security;

import com.moonlighttalk.server.common.exception.UnauthorizedException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * Spring Security 없이 JWT를 검증하는 인터셉터(05 문서 §11).
 * Filter가 아닌 HandlerInterceptor를 쓰는 이유: 인증 실패 시 GlobalExceptionHandler가
 * 그대로 처리해주고, 매칭된 컨트롤러 메서드의 @NoAuth 애노테이션을 조회할 수 있음.
 */
@Component
public class JwtAuthInterceptor implements HandlerInterceptor {

    private static final String BEARER_PREFIX = "Bearer ";

    private final JwtProvider jwtProvider;

    public JwtAuthInterceptor(JwtProvider jwtProvider) {
        this.jwtProvider = jwtProvider;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        if (handler instanceof HandlerMethod handlerMethod && isNoAuth(handlerMethod)) {
            return true;
        }

        String header = request.getHeader("Authorization");
        if (header == null || !header.startsWith(BEARER_PREFIX)) {
            throw new UnauthorizedException("인증 토큰이 없습니다.");
        }

        String token = header.substring(BEARER_PREFIX.length());
        try {
            String userId = jwtProvider.parseUserId(token);
            AuthContext.set(userId);
            return true;
        } catch (RuntimeException e) {
            throw new UnauthorizedException("유효하지 않은 토큰입니다.");
        }
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        AuthContext.clear();
    }

    private boolean isNoAuth(HandlerMethod handlerMethod) {
        return handlerMethod.hasMethodAnnotation(NoAuth.class)
                || handlerMethod.getBeanType().isAnnotationPresent(NoAuth.class);
    }
}
