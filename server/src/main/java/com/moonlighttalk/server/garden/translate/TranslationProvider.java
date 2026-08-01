package com.moonlighttalk.server.garden.translate;

/** 번역 공급자 추상화(05 문서 §9.2). 키 발급 전에는 패스스루로 동작. */
public interface TranslationProvider {

    String translate(String text, String targetLang);

    /** 로깅/응답 표기에 쓰는 공급자 이름. */
    String name();
}
