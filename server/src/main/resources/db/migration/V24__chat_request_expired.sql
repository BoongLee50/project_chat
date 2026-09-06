-- 받은 대화 신청의 **14일 무응답 만료**(기획서 260906 §6-2 "[받은 신청] 목록 삭제 조건").
--
-- 기획: "받은 신청 목록에 대해 14일동안 자신이 아무런 회신을 하지 않을 경우" 목록에서 삭제.
--
-- 🚨 **REJECTED로 만료시키면 안 된다.** 거절에는 "1일간 다시 신청 못 함"(V18)이 딸려 있어서,
-- 내가 답을 안 한 것뿐인데 상대가 벌을 받게 된다. 만료는 **아무 일도 없었던 것**에 가깝다 —
-- 그래서 값을 따로 둔다. `existsRecentRejection`은 REJECTED만 보므로 EXPIRED는 걸리지 않는다.
--
-- 행은 지우지 않고 상태만 바꾼다. 목록 조회가 전부 `status = 'PENDING'`이라
-- 상태만 바꿔도 목록에서는 사라지고, 이력(누가 언제 신청했는가)은 남는다.
--
-- 친구 신청(`friendships`)은 같은 규칙이지만 **행을 지운다** — 그쪽은 status가
-- ENUM('PENDING','ACCEPTED')이고 `pair_key`가 UNIQUE라, 만료 행을 남기면
-- 같은 사람에게 다시 신청할 수 없게 된다(거절도 이미 행 삭제로 처리한다).

ALTER TABLE chat_requests
    MODIFY COLUMN status ENUM('PENDING','ACCEPTED','REJECTED','BLOCKED','EXPIRED')
        NOT NULL DEFAULT 'PENDING';
