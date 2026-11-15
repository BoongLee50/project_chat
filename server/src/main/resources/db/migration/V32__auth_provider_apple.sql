-- 로그인 수단에 **애플**을 더한다(사용자 2026-11-15 — 구글·애플·라인·카카오 넷 중 하나로 연동).
--
-- 애플 앱스토어 심사 규칙: 앱이 구글·카카오·라인 같은 제3자 로그인을 쓰면 **Sign in with Apple도 반드시** 넣어야 한다.
-- providerUid는 애플 identity token의 `sub`(앱 팀마다 고정된 사용자 식별자)다.
--
-- ENUM 끝에 값을 붙이는 것은 기존 행을 건드리지 않는다(넓히는 방향).
ALTER TABLE users
    MODIFY COLUMN provider ENUM('LINE','KAKAO','GOOGLE','APPLE') NOT NULL;
