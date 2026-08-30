package com.moonlighttalk.server.garden.translate;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * <b>개발용</b> 가짜 번역기({@code app.translate.provider=mock}).
 *
 * <p>🚨 <b>운영에서는 절대 켜지 말 것.</b> 번역하지 않고 표시만 붙인다.
 *
 * <p>왜 필요한가 — 무료 쿼터(댓글창 5회 호출 · 대화방 동시 5개)는 <b>번역이 실제로
 * 되는 상태에서만</b> 동작한다. 공급자가 {@code none}이면 자리를 쓰지 않도록 해 두었기
 * 때문이다(번역도 못 받는데 횟수만 깎을 수는 없다). 그래서 키가 오기 전에는
 * 이 공급자 없이는 쿼터 흐름을 눈으로도 자동으로도 확인할 수 없다.
 *
 * <p>붙인 표시가 <b>원문과 눈에 띄게 달라야</b> "번역된 것처럼 보이는데 원문 그대로"라는
 * 착각을 막는다. 그래서 앞뒤를 꺾쇠로 감싸고 대상 언어를 적는다.
 */
@Component
@ConditionalOnProperty(name = "app.translate.provider", havingValue = "mock")
public class MockTranslationProvider implements TranslationProvider {

    @Override
    public String translate(String text, String targetLang) {
        if (text == null || text.isBlank()) return text;
        return "〔" + (targetLang == null ? "??" : targetLang) + "〕" + text;
    }

    @Override
    public String name() {
        return "mock";
    }
}
