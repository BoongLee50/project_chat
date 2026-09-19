# -*- coding: utf-8 -*-
"""대화방 개편 검증 (기획서 260919 §6-1·6-2 + 기획사항 2026-09-19, V26).

확인하는 것 다섯:
  1. 신청 한마디가 대화·친구 **둘 다 100자**다 — 101자는 거절하고 한도(`100`)를 field에 싣는다.
  2. "공백·이모지·특수문자도 한 글자" — 코드포인트로 센다. 결합 이모지도 여러 글자다.
  3. "줄바꾸기 불가" — 줄바꿈이 섞여 와도 **공백으로 바뀌어** 저장된다(거절하지 않는다).
  4. 받은 신청의 미확인(`N`) — 열기 전 viewed=false, 받는 사람이 [포스트 정보]를 열면 true.
     🚨 **보낸 사람이** 그 화면을 열어도 켜지면 안 된다(받는 사람의 '확인'이다).
  5. 대화 목록 미리보기는 **마지막 글**이다 — 음성이 마지막이어도 그 전 글을 보여 준다.
     시각은 종류와 무관하게 마지막 메시지(음성 포함)다.
  6. 받은 신청 번역(scope=REQUEST)은 **무료** — 쿼터 없이 200이 온다.

실행: python tools/verify/verify_talk_room.py   (local 프로필 서버 + MariaDB)
"""
import sys

sys.path.insert(0, __file__.rsplit('\\', 1)[0].rsplit('/', 1)[0])

from _common import Checks, call, clear_ties, login, sql  # noqa: E402

check = Checks()

print('== 계정 준비 ==')
ta, a = login('verify-talk-a')
tb, b = login('verify-talk-b')
tc, c = login('verify-talk-c')
print('  A=%s\n  B=%s\n  C=%s' % (a, b, c))
clear_ties([a, b, c])
sql("DELETE FROM chat_messages WHERE room_id IN (SELECT id FROM chat_rooms "
    "WHERE user_a IN ('%s','%s','%s') OR user_b IN ('%s','%s','%s'))" % (a, b, c, a, b, c))
sql("DELETE FROM chat_rooms WHERE user_a IN ('%s','%s','%s') OR user_b IN ('%s','%s','%s')"
    % (a, b, c, a, b, c))


def last_request(frm, to):
    rows = sql("SELECT message FROM chat_requests WHERE from_user='%s' AND to_user='%s' "
               "ORDER BY created_at DESC LIMIT 1" % (frm, to))
    return rows[0][0] if rows else None


# ──────────────────────────────────────────────────────────────
print('\n== 1. 100자 통일 ==')
st, body = call('POST', '/chat-requests', ta, {'targetUserId': b, 'message': 'a' * 101})
check('대화 신청 101자는 거절', st == 400, st)
check('  한도 100을 field에 싣는다', isinstance(body, dict) and body.get('field') == '100', body)

st, body = call('POST', '/chat-requests', ta, {'targetUserId': b, 'message': 'a' * 100})
check('대화 신청 100자는 통과', st == 200, (st, body))
clear_ties([a, b, c])

st, body = call('POST', '/friends/requests', ta, {'targetUserId': c, 'message': 'b' * 101})
check('친구 신청 101자는 거절(예전 한도 25가 아니다)', st == 400, st)
check('  친구 신청도 한도 100을 싣는다', isinstance(body, dict) and body.get('field') == '100', body)

st, body = call('POST', '/friends/requests', ta, {'targetUserId': c, 'message': 'b' * 100})
check('친구 신청 100자는 통과', st in (200, 201), (st, body))
clear_ties([a, b, c])

# ──────────────────────────────────────────────────────────────
print('\n== 2. 이모지·공백·특수문자도 한 글자(코드포인트) ==')
# 👍🏽 = 코드포인트 2개. 50개면 100 → 통과, 거기에 하나 더면 101 → 거절.
thumbs = '\U0001F44D\U0001F3FD'
st, _ = call('POST', '/chat-requests', ta, {'targetUserId': b, 'message': thumbs * 50})
check('피부색 이모지 50개(=코드포인트 100)는 통과', st == 200, st)
clear_ties([a, b, c])
st, _ = call('POST', '/chat-requests', ta, {'targetUserId': b, 'message': thumbs * 50 + '!'})
check('거기에 느낌표 하나(=101)면 거절', st == 400, st)
# ⚠️ 공백은 **글 사이에** 넣어야 한다 — 서버는 앞뒤 공백을 다듬은 뒤(저장되는 글 기준) 센다.
# 앞에 공백 50개를 붙이면 다듬어져 사라지므로 통과하는 게 맞다(처음엔 그걸 실패로 적었다).
st, _ = call('POST', '/chat-requests', ta, {'targetUserId': b, 'message': 'x' * 50 + ' ' + 'x' * 50})
check('글 사이 공백도 한 글자로 센다(50 + 공백 1 + 50 = 101 → 거절)', st == 400, st)
st, _ = call('POST', '/chat-requests', ta, {'targetUserId': b, 'message': '  ' + 'x' * 100 + '  '})
check('  앞뒤 공백은 다듬고 센다(저장되는 글이 100자 → 통과)', st == 200, st)

# ──────────────────────────────────────────────────────────────
print('\n== 3. 줄바꾸기 불가 ==')
clear_ties([a, b, c])
st, _ = call('POST', '/chat-requests', ta, {'targetUserId': b, 'message': '안녕\n하세요\r\n반가워요'})
saved = last_request(a, b)
check('줄바꿈이 섞여 와도 받는다', st == 200, st)
check('  저장된 글에 줄바꿈이 없다(공백으로 바뀜)', saved is not None and '\n' not in saved
      and '\r' not in saved, repr(saved))

# ──────────────────────────────────────────────────────────────
print('\n== 4. 받은 신청 미확인(N) ==')
st, lst = call('GET', '/chat/rooms/received', tb)
mine = [r for r in (lst or []) if r.get('fromUserId') == a]
check('B의 받은 신청에 A가 있다', len(mine) == 1, len(mine))
check('  열기 전에는 viewed=false', mine and mine[0].get('viewed') is False,
      mine and mine[0].get('viewed'))

call('GET', '/users/%s/post-info' % b, ta)  # 🚨 보낸 사람(A)이 B를 연다 — 켜지면 안 된다
st, lst = call('GET', '/chat/rooms/received', tb)
mine = [r for r in (lst or []) if r.get('fromUserId') == a]
check('보낸 사람이 열어도 그대로 false', mine and mine[0].get('viewed') is False,
      mine and mine[0].get('viewed'))

st, _ = call('GET', '/users/%s/post-info' % a, tb)  # 받는 사람(B)이 A의 [포스트 정보]를 연다
check('B가 A의 [포스트 정보]를 연다', st == 200, st)
st, lst = call('GET', '/chat/rooms/received', tb)
mine = [r for r in (lst or []) if r.get('fromUserId') == a]
check('  그 뒤에는 viewed=true', mine and mine[0].get('viewed') is True,
      mine and mine[0].get('viewed'))

# ──────────────────────────────────────────────────────────────
print('\n== 5. 대화 목록 미리보기는 마지막 "글" ==')
rid = mine[0]['id'] if mine else None
st, acc = call('POST', '/chat/requests/%s:accept' % rid, tb)
room = acc.get('roomId') if isinstance(acc, dict) else None
check('수락 → 방이 생긴다', st == 200 and room, (st, acc))
sql("INSERT INTO chat_messages (id, room_id, sender_id, type, body, created_at) VALUES "
    "('vt-m1','%s','%s','TEXT','마지막 글이에요', NOW() - INTERVAL 5 MINUTE)" % (room, a))
sql("INSERT INTO chat_messages (id, room_id, sender_id, type, body, audio_key, "
    "audio_duration_ms, created_at) VALUES "
    "('vt-m2','%s','%s','VOICE','','voice/vt.m4a',3000, NOW() - INTERVAL 1 MINUTE)" % (room, a))
st, rooms = call('GET', '/chat/rooms', tb)
r = next((x for x in (rooms or []) if x.get('roomId') == room), None)
check('미리보기는 음성이 아니라 그 전 글', r and r.get('lastMessage') == '마지막 글이에요',
      r and r.get('lastMessage'))
check('  시각은 음성(1분 전) 기준', r and r.get('lastMessageAt') is not None,
      r and r.get('lastMessageAt'))
check('  안 읽은 수는 음성 포함 2', r and r.get('unreadCount') == 2, r and r.get('unreadCount'))

# ──────────────────────────────────────────────────────────────
print('\n== 6. 받은 신청 번역은 무료 ==')
st, body = call('POST', '/translate', tb,
                {'text': 'はじめまして', 'targetLang': 'ko', 'scope': 'REQUEST'})
check('scope=REQUEST → 200', st == 200, (st, body))
check('  쿼터를 세지 않는다(unlimited)', isinstance(body, dict) and body.get('unlimited') is True,
      body)

# 정리 — 이 스크립트가 만든 것을 남기지 않는다(함정 #81).
sql("DELETE FROM chat_messages WHERE id IN ('vt-m1','vt-m2')")
if room:
    sql("DELETE FROM chat_rooms WHERE id = '%s'" % room)
clear_ties([a, b, c])
check.finish()
