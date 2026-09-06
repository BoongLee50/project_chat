# -*- coding: utf-8 -*-
"""받은 신청 만료 + 신고·차단의 정리 범위 검증 (기획서 260906 §6-1·6-2, V24).

확인하는 것 셋:
  1. 받은 신청은 14일 답이 없으면 사라진다 — 대화 신청은 EXPIRED, 친구 신청은 행 삭제.
     🚨 **만료는 거절이 아니다** — 만료된 뒤에도 다시 신청할 수 있어야 한다.
  2. 신고·차단이 두 사람 사이의 대기 중인 신청을 **양방향으로** 닫는다.
  3. 차단하면 **차단당한 쪽 화면에서도** 상대가 사라진다(가든 목록 · [포스트 정보] 상세).

실행: python tools/verify/verify_moderation.py   (local 프로필 서버 + MariaDB가 떠 있어야 한다)
"""
import sys

sys.path.insert(0, __file__.rsplit('\\', 1)[0].rsplit('/', 1)[0])

from _common import Checks, call, clear_ties, login, publish_post, sql  # noqa: E402

check = Checks()


def mk_chat_request(rid, frm, to, days_ago):
    sql("INSERT INTO chat_requests (id, from_user, to_user, message, status, created_at) "
        "VALUES ('%s','%s','%s','hi','PENDING', NOW() - INTERVAL %d DAY)"
        % (rid, frm, to, days_ago))


def mk_friend_request(fid, requester, addressee, days_ago):
    lo, hi = sorted([requester, addressee])
    sql("INSERT INTO friendships (id, requester_id, addressee_id, status, pair_key, created_at) "
        "VALUES ('%s','%s','%s','PENDING','%s_%s', NOW() - INTERVAL %d DAY)"
        % (fid, requester, addressee, lo, hi, days_ago))


def status_of(rid):
    rows = sql("SELECT status FROM chat_requests WHERE id = '%s'" % rid)
    return rows[0][0] if rows else None


def friend_exists(fid):
    return bool(sql("SELECT 1 FROM friendships WHERE id = '%s'" % fid))


print('== 계정 준비 ==')
ta, a = login('verify-mod-a')
tb, b = login('verify-mod-b')
tc, c = login('verify-mod-c')
print('  A=%s\n  B=%s\n  C=%s' % (a, b, c))
clear_ties([a, b, c])

# ──────────────────────────────────────────────────────────────
print('\n== 1. 14일 무응답 만료 ==')
mk_chat_request('vm-old', a, b, 15)      # 15일 → 만료
mk_chat_request('vm-old2', a, c, 40)     # 40일 → 만료
mk_chat_request('vm-edge', c, b, 13)     # 13일 → 살아남는다(경계)
mk_chat_request('vm-done', c, a, 0)      # 이미 답한 것은 건드리지 않는다
sql("UPDATE chat_requests SET status='ACCEPTED', responded_at=NOW() WHERE id='vm-done'")

mk_friend_request('vm-fold', a, b, 20)   # 20일 → 행 삭제
mk_friend_request('vm-fnew', c, a, 3)    # 3일  → 남는다
lo, hi = sorted([b, c])
sql("INSERT INTO friendships (id, requester_id, addressee_id, status, pair_key, created_at, accepted_at) "
    "VALUES ('vm-facc','%s','%s','ACCEPTED','%s_%s', NOW() - INTERVAL 90 DAY, NOW() - INTERVAL 89 DAY)"
    % (b, c, lo, hi))

st, body = call('POST', '/internal/scheduler/expire-requests', ta)
print('  배치 →', st, body)
# ⚠️ `==`로 세지 말 것 — 배치는 개발 DB에 있는 **남의 오래된 신청까지** 정리한다(함정 #61).
check('배치가 돈다',
      st == 200 and body.get('chatRequests') >= 2 and body.get('friendRequests') >= 1, body)
check('15일 지난 대화 신청 → EXPIRED', status_of('vm-old') == 'EXPIRED', status_of('vm-old'))
check('40일 지난 대화 신청 → EXPIRED', status_of('vm-old2') == 'EXPIRED', status_of('vm-old2'))
check('13일짜리는 그대로 PENDING', status_of('vm-edge') == 'PENDING', status_of('vm-edge'))
check('이미 답한 신청은 건드리지 않는다', status_of('vm-done') == 'ACCEPTED', status_of('vm-done'))
check('20일 지난 친구 신청 → 행 삭제', not friend_exists('vm-fold'))
check('3일짜리 친구 신청은 남는다', friend_exists('vm-fnew'))
check('성립된 친구(90일)는 만료되지 않는다', friend_exists('vm-facc'))

# 🚨 이게 이 파일에서 가장 중요한 한 줄이다.
# 만료를 REJECTED로 구현하면 여기가 깨진다 — 거절에 딸린 "1일 재신청 금지"(V18)가 걸려,
# 답을 안 한 쪽이 아니라 **신청한 쪽**이 벌을 받는다.
st, body = call('POST', '/chat-requests', ta, {'targetUserId': b, 'message': '다시 인사'})
check('만료된 뒤 재신청이 막히지 않는다(만료 ≠ 거절)', st == 200, '%s %s' % (st, body))
if st == 200:
    sql("DELETE FROM chat_requests WHERE from_user='%s' AND to_user='%s' AND status='PENDING'"
        % (a, b))

# ──────────────────────────────────────────────────────────────
print('\n== 2. 신고·차단이 대기 중인 신청을 닫는다 ==')
mk_chat_request('vm-ab', a, b, 1)   # A → B
mk_chat_request('vm-ba', b, a, 1)   # B → A  (양방향인가)
mk_chat_request('vm-cb', c, b, 1)   # 무관한 신청은 남아야 한다

st, body = call('POST', '/blocks', ta, {'targetUserId': b})
check('차단 성공', st in (200, 204), '%s %s' % (st, body))
check('A가 보낸 신청이 닫힌다', status_of('vm-ab') == 'BLOCKED', status_of('vm-ab'))
check('B가 보낸 신청도 함께 닫힌다', status_of('vm-ba') == 'BLOCKED', status_of('vm-ba'))
check('무관한 신청은 그대로', status_of('vm-cb') == 'PENDING', status_of('vm-cb'))

st, body = call('GET', '/chat/rooms/received', tb)
senders = [r['fromUserId'] for r in body] if isinstance(body, list) else []
check('B의 [받은 신청]에서 A가 사라졌다', a not in senders)
check('B의 [받은 신청]에 C는 남아 있다', c in senders)

# 신고도 부수효과가 같다(기록만 다르다).
tr, r = login('verify-mod-r')
tt, t = login('verify-mod-t')
clear_ties([r, t])
mk_chat_request('vm-rt', t, r, 1)
mk_chat_request('vm-tr', r, t, 1)
st, _ = call('POST', '/reports', tr, {'targetUserId': t, 'reason': 'ABUSIVE', 'detail': 'verify'})
check('신고도 양방향 신청을 닫는다',
      st in (200, 204) and status_of('vm-rt') == 'BLOCKED' and status_of('vm-tr') == 'BLOCKED',
      '%s / %s %s' % (st, status_of('vm-rt'), status_of('vm-tr')))

# ──────────────────────────────────────────────────────────────
print('\n== 3. 차단당한 쪽에서도 안 보인다 ==')
st, body = call('GET', '/users/%s/post-info' % a, tb)
check('B가 A의 [포스트 정보]를 못 연다(409)', st == 409, '%s %s' % (st, body))
st, _ = call('GET', '/users/%s/post-info' % a, tc)
check('무관한 C는 A를 볼 수 있다(200)', st == 200, st)

# 가든 목록 — 차단 전/후를 같은 눈(B)으로 본다.
sql("DELETE FROM blocks WHERE blocker_id='%s' AND blocked_id='%s'" % (a, b))
publish_post(a, 'vm-post-a')
publish_post(c, 'vm-post-c')


def garden_of(token, viewer_id):
    """B가 보는 가든 **전체**를 훑는다.

    ⚠️ 한 페이지만 보면 안 된다 — 개발 DB에는 오늘 공유한 사람이 여럿이라
    찾는 사람이 2페이지로 밀리면 **버그가 없는데도 실패**한다(실제로 한 번 당했다).
    노출 기록을 지우는 것은 15분 재노출 제외를 푸는 것이다.
    """
    sql("DELETE FROM feed_exposures WHERE user_id = '%s'" % viewer_id)
    found, cursor = [], None
    for _ in range(20):   # 무한 루프 방지
        path = '/feed' if cursor is None else '/feed?cursor=%s' % cursor
        _, page = call('GET', path, token)
        if not isinstance(page, dict):
            break
        found += [i['userId'] for i in page.get('items', [])]
        cursor = page.get('nextCursor')
        if not cursor:
            break
    return found


seen = garden_of(tb, b)
check('차단 전에는 A가 B의 가든에 뜬다', a in seen)
check('무관한 C도 보인다', c in seen)

call('POST', '/blocks', ta, {'targetUserId': b})
seen = garden_of(tb, b)
check('A가 차단한 뒤 B의 가든에서 사라진다', a not in seen)
check('무관한 C는 여전히 보인다', c in seen)

check.finish()
