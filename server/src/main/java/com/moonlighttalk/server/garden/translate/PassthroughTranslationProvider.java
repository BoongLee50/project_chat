package com.moonlighttalk.server.garden.translate;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * 기본 구현 — 원문을 그대로 반환한다({@code app.translate.provider=none}).
 * 번역 API 키가 없어도 API 계약(01 문서 §1.4)을 그대로 구현/테스트할 수 있게 한다.
 */
@Component
@ConditionalOnProperty(name = "app.translate.provider", havingValue = "none", matchIfMissing = true)
public class PassthroughTranslationProvider implements TranslationProvider {

    @Override
    public String translate(String text, String targetLang) {
        return text;
    }

    @Override
    public String name() {
        return "none";
    }
}
