# -*- coding: utf-8 -*-
"""친구 화면 개편 검증 (기획서 260919 §7-1·7-2, V27).

확인하는 것:
  1. [친구 목록] 순서 = 상단 고정 > 신규 등록 > 온라인 > 최근 접속.
     고정·신규가 여럿이면 **최신순**(늦게 고정한 것 / 늦게 친구가 된 것이 위).
     접속 기록이 없는 친구는 맨 끝이다.
     (온라인은 소켓이 붙어야 켜져서 여기서는 못 만든다 — 순서 규칙은 서비스 정렬기 하나라 함께 확인된다.)
  2. 신규 등록 = 수락 후 7일(`app.friend.new-days`). 8일 전 친구는 신규가 아니다.
  3. 고정은 **보는 사람마다 따로**다 — A가 B를 고정해도 B의 목록에서 A는 고정이 아니다.
  4. `:pin` / `:unpin` — 붙으면 맨 위, 풀면 제자리. 남의 관계·대기 중인 신청은 고정할 수 없다.
  5. 친구를 끊었다가 다시 친구가 되면 **옛 고정이 되살아나지 않는다**(행 삭제로 함께 사라진다).
  6. 받은 친구 신청의 미확인(`N`) — 받는 사람이 [포스트 정보]를 열면 viewed=true.
     🚨 보낸 사람이 열어서는 안 켜진다.

실행: python tools/verify/verify_friend.py   (local 프로필 서버 + MariaDB)
"""
import sys

sys.path.insert(0, __file__.rsplit('\\', 1)[0].rsplit('/', 1)[0])

from _common import Checks, call, clear_ties, login, sql  # noqa: E402

check = Checks()

print('== 계정 준비 ==')
ta, a = login('verify-friend-a')
others = {}
for tag in 'bcdefgh':
    others[tag] = login('verify-friend-' + tag)
ids = {k: v[1] for k, v in others.items()}
tok = {k: v[0] for k, v in others.items()}
clear_ties([a] + list(ids.values()))
print('  A=%s' % a)


def befriend(fid, frm, to, accepted_days_ago, requester_pin=None, addressee_pin=None):
    """수락된 친구 관계 한 행. 핀 값은 'N분 전' 정수(None이면 고정 안 함)."""
    def at(minutes):
        return 'NULL' if minutes is None else 'NOW() - INTERVAL %d MINUTE' % minutes
    sql("INSERT INTO friendships (id, requester_id, addressee_id, status, pair_key, created_at, "
        "accepted_at, requester_pinned_at, addressee_pinned_at) VALUES "
        "('%s','%s','%s','ACCEPTED', CONCAT(LEAST('%s','%s'),'_',GREATEST('%s','%s')), "
        "NOW() - INTERVAL %d DAY, NOW() - INTERVAL %d DAY, %s, %s)"
        % (fid, frm, to, frm, to, frm, to, accepted_days_ago + 1, accepted_days_ago,
           at(requester_pin), at(addressee_pin)))


def seen(uid, hours):
    sql("UPDATE users SET last_seen_at = %s WHERE id = '%s'"
        % ('NULL' if hours is None else 'NOW() - INTERVAL %d HOUR' % hours, uid))


# b·c: 고정(c가 더 늦게 고정 → c가 위). b는 A가 신청한 쪽, c는 A가 받은 쪽 — 칼럼이 다르다.
befriend('vf-b', a, ids['b'], 30, requester_pin=60)
befriend('vf-c', ids['c'], a, 30, addressee_pin=5)
# d·e: 신규 등록(d가 더 늦게 친구가 됨 → d가 위)
befriend('vf-d', ids['d'], a, 1)
befriend('vf-e', a, ids['e'], 3)
# f·g·h: 7일이 지남. 최근 접속 순 f(1시간) > g(5시간) > h(기록 없음)
befriend('vf-f', ids['f'], a, 8)
befriend('vf-g', a, ids['g'], 20)
befriend('vf-h', ids['h'], a, 40)
for k, h in {'b': 50, 'c': 50, 'd': 50, 'e': 50, 'f': 1, 'g': 5, 'h': None}.items():
    seen(ids[k], h)


def friends(token):
    st, lst = call('GET', '/friends', token)
    if st != 200:
        raise RuntimeError('GET /friends %s %s' % (st, lst))
    return lst


def order(token):
    name = {v: k for k, v in ids.items()}
    return [name.get(f['userId'], '?') for f in friends(token)]


def row(token, uid):
    return next((f for f in friends(token) if f['userId'] == uid), None)


# ──────────────────────────────────────────────────────────────
print('\n== 1. 순서: 고정 > 신규 > (온라인) > 최근 접속 ==')
got = order(ta)
check('A의 목록 순서가 c b d e f g h', got == list('cbdefgh'), ''.join(got))

# ──────────────────────────────────────────────────────────────
print('\n== 2. 신규 등록 = 수락 후 7일 ==')
check('1일 전 친구(d)는 신규', row(ta, ids['d'])['newlyAdded'] is True)
check('3일 전 친구(e)는 신규', row(ta, ids['e'])['newlyAdded'] is True)
check('8일 전 친구(f)는 신규 아님', row(ta, ids['f'])['newlyAdded'] is False)
check('고정한 친구도 30일 전이면 신규 아님(b)', row(ta, ids['b'])['newlyAdded'] is False)

# ──────────────────────────────────────────────────────────────
print('\n== 3. 고정은 보는 사람마다 따로 ==')
check('A 목록에서 b는 고정', row(ta, ids['b'])['pinned'] is True)
check('  b 목록에서 A는 고정 아님', row(tok['b'], a)['pinned'] is False)
check('A 목록에서 c는 고정(A가 받은 쪽 칼럼)', row(ta, ids['c'])['pinned'] is True)
check('  c 목록에서 A는 고정 아님', row(tok['c'], a)['pinned'] is False)

# ──────────────────────────────────────────────────────────────
print('\n== 4. :pin / :unpin ==')
st, _ = call('POST', '/friends/vf-h:pin', ta)
check('A가 h를 고정한다', st in (200, 204), st)
check('  h가 맨 위로(방금 고정 = 가장 늦은 고정)', order(ta)[0] == 'h', ''.join(order(ta)))
st, _ = call('POST', '/friends/vf-h:unpin', ta)
check('고정을 푼다', st in (200, 204), st)
check('  h가 맨 끝으로 돌아간다', order(ta) == list('cbdefgh'), ''.join(order(ta)))

st, _ = call('POST', '/friends/vf-d:pin', tok['e'])  # e는 d-A 관계의 당사자가 아니다
check('남의 관계는 고정 못 한다', st in (403, 404), st)

sql("INSERT INTO friendships (id, requester_id, addressee_id, status, pair_key, message) VALUES "
    "('vf-p', '%s', '%s', 'PENDING', CONCAT(LEAST('%s','%s'),'_',GREATEST('%s','%s')), '친구해요')"
    % (ids['b'], ids['c'], ids['b'], ids['c'], ids['b'], ids['c']))
st, _ = call('POST', '/friends/vf-p:pin', tok['c'])
check('대기 중인 신청은 고정 못 한다', st >= 400, st)
sql("DELETE FROM friendships WHERE id = 'vf-p'")

# ──────────────────────────────────────────────────────────────
print('\n== 5. 끊었다 다시 친구 → 옛 고정은 없다 ==')
st, _ = call('DELETE', '/friends/vf-b', ta)
check('A가 b와 친구를 끊는다', st in (200, 204), st)
st, req = call('POST', '/friends/requests', tok['b'], {'targetUserId': a, 'message': '다시 친구해요'})
check('b가 다시 신청한다', st in (200, 201), (st, req))
rid = req.get('friendshipId') if isinstance(req, dict) else None
st, _ = call('POST', '/friends/requests/%s:accept' % rid, ta)
check('A가 수락한다', st in (200, 204), st)
r = row(ta, ids['b'])
check('  b는 고정이 아니다', r and r['pinned'] is False, r and r['pinned'])
check('  방금 친구가 됐으니 신규 등록', r and r['newlyAdded'] is True, r and r['newlyAdded'])
check('  신규 중 가장 늦게 친구가 됨 → 고정(c) 바로 아래', order(ta)[:2] == ['c', 'b'],
      ''.join(order(ta)))

# ──────────────────────────────────────────────────────────────
print('\n== 6. 받은 친구 신청 미확인(N) ==')
sql("DELETE FROM friendships WHERE id = 'vf-g'")
st, req = call('POST', '/friends/requests', tok['g'], {'targetUserId': a, 'message': 'また友達に'})
check('g가 A에게 신청한다', st in (200, 201), (st, req))


def received(token, frm):
    st, lst = call('GET', '/friends/requests', token)
    return next((x for x in (lst or []) if x.get('requesterId') == frm), None)


r = received(ta, ids['g'])
check('열기 전에는 viewed=false', r and r['viewed'] is False, r and r['viewed'])
call('GET', '/users/%s/post-info' % a, tok['g'])  # 🚨 보낸 사람이 받는 사람을 연다
r = received(ta, ids['g'])
check('보낸 사람이 열어도 그대로 false', r and r['viewed'] is False, r and r['viewed'])
st, _ = call('GET', '/users/%s/post-info' % ids['g'], ta)
check('A가 g의 [포스트 정보](= 친구 요청 상세)를 연다', st == 200, st)
r = received(ta, ids['g'])
check('  그 뒤에는 viewed=true', r and r['viewed'] is True, r and r['viewed'])

# 정리 — 이 스크립트가 만든 것을 남기지 않는다(함정 #81).
clear_ties([a] + list(ids.values()))
check.finish()
