package com.moonlighttalk.server.common.config;

import com.moonlighttalk.server.common.security.CurrentUserIdArgumentResolver;
import com.moonlighttalk.server.common.security.JwtAuthInterceptor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.List;

/** 05 문서 §10(CORS) · §11(JWT 인증, Spring Security 미사용) 참고. */
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    private final JwtAuthInterceptor jwtAuthInterceptor;
    private final CurrentUserIdArgumentResolver currentUserIdArgumentResolver;

    public WebMvcConfig(JwtAuthInterceptor jwtAuthInterceptor,
                         CurrentUserIdArgumentResolver currentUserIdArgumentResolver) {
        this.jwtAuthInterceptor = jwtAuthInterceptor;
        this.currentUserIdArgumentResolver = currentUserIdArgumentResolver;
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOriginPatterns("*")
                .allowedMethods("*")
                .allowedHeaders("*")
                .allowCredentials(false); // 와일드카드 오리진 + allowCredentials(true) 조합은 Spring이 예외를 던짐
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(jwtAuthInterceptor)
                .addPathPatterns("/**")
                .excludePathPatterns("/ws/**"); // WebSocket 핸드셰이크는 연결 후 AUTH 패킷으로 별도 인증(05 §4)
    }

    @Override
    public void addArgumentResolvers(List<HandlerMethodArgumentResolver> resolvers) {
        resolvers.add(currentUserIdArgumentResolver);
    }
}
