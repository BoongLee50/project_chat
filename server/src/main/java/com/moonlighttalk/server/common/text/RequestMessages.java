package com.moonlighttalk.server.common.text;

/**
 * 대화 신청 · 친구 신청의 한마디 규칙(기획사항 2026-09-19 변경사항).
 *
 * <p><i>"대화신청과 친구신청의 요청문구의 최대숫자는 100자로 변경 및 통일.
 * 공백, 이모지, 특수문자 까지 모두 문구로 취급. 줄바꾸기는 불가."</i>
 *
 * <p>두 신청이 <b>같은 규칙</b>이 됐으므로 한 곳에 둔다 — 갈라 두면 한쪽만 늙는다.
 *
 * <ul>
 *   <li><b>줄바꿈</b>은 공백으로 바꾼다. 화면이 이미 막지만(붙여넣기 포함),
 *       API를 직접 부르면 들어올 수 있다. 거절하지 않고 바꾸는 이유는 사용자가 잘못한 게 아니라
 *       붙여넣은 글에 섞여 들어온 경우가 대부분이라서다.</li>
 *   <li><b>길이</b>는 코드포인트로 센다 — 공백·이모지·특수문자 모두 한 글자다.
 *       DB의 VARCHAR(n)도 같은 단위라 서버 검사와 저장 한도가 어긋나지 않는다.</li>
 * </ul>
 */
public final class RequestMessages {

    private RequestMessages() {
    }

    /** 줄바꿈(\r\n · \r · \n · 유니코드 줄/문단 구분자)을 공백 하나로 바꾸고 앞뒤를 다듬는다. */
    public static String normalize(String message) {
        if (message == null) {
            return null;
        }
        return message.replaceAll("\\r\\n|[\\r\\n\\u2028\\u2029]", " ").trim();
    }

    /** 공백·이모지·특수문자를 모두 한 글자로 센 길이. */
    public static int length(String message) {
        return message == null ? 0 : message.codePointCount(0, message.length());
    }
}
