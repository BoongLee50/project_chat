# -*- coding: utf-8 -*-
"""대화 신청 무료 횟수 검증 (기획서 261111 4-3).

  *"대화 신청은 하루에 2회까지 무료. 하루 무료분은 사용여부와 상관없이 KST기준 18시 초기화.
    [프라임 멤버십 구독] 사용자는 대화 신청 무제한 무료."* — 루나는 없어졌다(루나 폐지).

확인하는 것:
  1. 안내(`GET /chat-requests/quota`)가 하루 2회 · 남은 2회를 말하고, 루나 값(`lunaCost`)은 더 없다.
  2. 두 번은 보내진다. 세 번째는 409 `CHAT_REQUEST_FREE_EXHAUSTED`, field에 하루 횟수 `2`. **루나가 빠지지 않는다.**
  3. 다 쓴 뒤 안내는 남은 0회.
  4. 무제한 권리(프라임)가 있으면 세 번째도 보내지고, 셈도 늘지 않는다.
  5. 셈은 **영업일(18시 기준)** 단위다 — 지난 영업일에 쓴 것은 오늘을 막지 않는다.

실행: python tools/verify/verify_chat_request_free.py   (local 프로필 서버 + MariaDB)
"""
import sys

sys.path.insert(0, __file__.rsplit('\\', 1)[0].rsplit('/', 1)[0])

from _common import Checks, call, clear_ties, login, scalar, sql  # noqa: E402

check = Checks()

print('== 계정 준비 ==')
ta, a = login('verify-free-a')
_, b = login('verify-free-b')
_, c = login('verify-free-c')
_, d = login('verify-free-d')
targets = [b, c, d]
clear_ties([a] + targets)
sql("DELETE FROM user_entitlements WHERE user_id = '%s' AND kind = 'UNLIMITED_CHAT_REQ'" % a)


def send(to):
    return call('POST', '/chat-requests', ta, {'targetUserId': to, 'message': '안녕하세요'})


def balance():
    return scalar("SELECT COALESCE((SELECT balance FROM luna_wallets WHERE user_id='%s'), 0)" % a, 0)


# ──────────────────────────────────────────────────────────────
print('\n== 1. 안내 ==')
st, q = call('GET', '/chat-requests/quota', ta)
check('quota 200', st == 200, (st, q))
check('  하루 무료 2회', isinstance(q, dict) and q.get('freePerDay') == 2, q)
check('  남은 2회', isinstance(q, dict) and q.get('freeRemaining') == 2, q)
check('  루나 값(lunaCost)은 없다', isinstance(q, dict) and 'lunaCost' not in q, q)

# ──────────────────────────────────────────────────────────────
print('\n== 2. 두 번까지 · 세 번째는 거절 ==')
luna_before = balance()
st, body = send(b)
check('1번째 신청 통과', st == 200, (st, body))
st, body = send(c)
check('2번째 신청 통과', st == 200, (st, body))
st, body = send(d)
check('3번째 신청은 409', st == 409, (st, body))
check('  CHAT_REQUEST_FREE_EXHAUSTED', isinstance(body, dict) and body.get('code') == 'CHAT_REQUEST_FREE_EXHAUSTED', body)
check('  field에 하루 횟수 2', isinstance(body, dict) and body.get('field') == '2', body)
check('  신청은 만들어지지 않았다',
      int(scalar("SELECT COUNT(*) FROM chat_requests WHERE from_user='%s' AND to_user='%s'" % (a, d), 0)) == 0)
check('  루나가 빠지지 않았다', balance() == luna_before, (luna_before, balance()))

# ──────────────────────────────────────────────────────────────
print('\n== 3. 다 쓴 뒤 안내 ==')
st, q = call('GET', '/chat-requests/quota', ta)
check('남은 0회', isinstance(q, dict) and q.get('freeRemaining') == 0, q)

# ──────────────────────────────────────────────────────────────
print('\n== 4. 무제한 권리(프라임) ==')
sql("INSERT INTO user_entitlements (user_id, kind, source, started_at, expires_at) "
    "VALUES ('%s','UNLIMITED_CHAT_REQ','PRIME', NOW() - INTERVAL 1 DAY, NOW() + INTERVAL 1 DAY)" % a)
used_before = scalar("SELECT COALESCE(SUM(used_count),0) FROM daily_usage WHERE user_id='%s' AND kind='CHAT_REQUEST'" % a, 0)
st, body = send(d)
check('무제한이면 3번째도 통과', st == 200, (st, body))
st, q = call('GET', '/chat-requests/quota', ta)
check('  안내는 unlimited', isinstance(q, dict) and q.get('unlimited') is True, q)
used_after = scalar("SELECT COALESCE(SUM(used_count),0) FROM daily_usage WHERE user_id='%s' AND kind='CHAT_REQUEST'" % a, 0)
check('  무제한 신청은 무료 셈을 늘리지 않는다', used_after == used_before, (used_before, used_after))
sql("DELETE FROM user_entitlements WHERE user_id = '%s' AND kind = 'UNLIMITED_CHAT_REQ'" % a)

# ──────────────────────────────────────────────────────────────
print('\n== 5. 18시(영업일) 초기화 ==')
# 지난 영업일에 다 쓴 기록을 둔다 — 18시가 지나 새 영업일이 된 것과 같다.
# (18시 전이면 '오늘 영업일'은 어제 날짜라, 확실히 지난 날짜로 3일 전을 쓴다)
clear_ties([a] + targets)
sql("INSERT INTO daily_usage (user_id, session_date, kind, used_count) "
    "VALUES ('%s', CURDATE() - INTERVAL 3 DAY, 'CHAT_REQUEST', 2)" % a)
st, q = call('GET', '/chat-requests/quota', ta)
check('지난 영업일에 2회 썼어도 오늘은 남은 2회', isinstance(q, dict) and q.get('freeRemaining') == 2, q)
st, body = send(b)
check('  오늘 첫 신청 통과', st == 200, (st, body))

clear_ties([a] + targets)
sql("DELETE FROM daily_usage WHERE user_id = '%s'" % a)
check.finish()
