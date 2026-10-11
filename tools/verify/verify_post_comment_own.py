# -*- coding: utf-8 -*-
"""내 포스트에 내가 새 댓글을 못 단다 — 기획 2026-10-11.

규칙
  1. 내 포스트에 **1단계 댓글** → 403 `COMMENT_OWN_POST` (내 포스트 좋아요가 안 되는 것과 같다)
  2. 남이 단 댓글에 **답글**은 된다 — "남 댓글 → 내 답글 → 남 답글"의 가운데가 글쓴이 몫
  3. 남은 내 포스트에 1단계 댓글을 단다
  4. `GET /posts/me`의 `comments`는 답글까지 센다

실행: python tools/verify/verify_post_comment_own.py   (local 프로필 서버 + MariaDB)
"""
import sys

sys.path.insert(0, __file__.rsplit('\\', 1)[0].rsplit('/', 1)[0])
from _common import Checks, call, clear_ties, login, publish_post, session_date, sql  # noqa: E402

check = Checks()

to, owner = login('verify-cmt-owner')
tv, other = login('verify-cmt-other')
clear_ties([owner, other])
for tok, nick in ((to, 'vcmtO'), (tv, 'vcmtV')):
    call('POST', '/profile', tok,
         {'nickname': nick, 'birthYear': 2000, 'gender': 'FEMALE', 'country': 'KR'})

post_id = 'vcmt-' + owner[:8]
sql("DELETE FROM comments WHERE target_type = 'POST' AND target_id = '%s'" % post_id)
publish_post(owner, post_id)


def comments_on_me():
    st, body = call('GET', '/posts/me', to)
    assert st == 200, (st, body)
    return body['comments']


before = comments_on_me()

print('\n[주인] 내 포스트에 새 댓글')
st, body = call('POST', '/posts/%s/comments' % owner, to, {'body': '내가 내 글에'})
check('403 COMMENT_OWN_POST', st == 403 and (body or {}).get('code') == 'COMMENT_OWN_POST', (st, body))

print('\n[남] 내 포스트에 댓글 → [주인] 답글 → [남] 답글')
st, _ = call('POST', '/posts/%s/comments' % owner, tv, {'body': '예뻐요'})
check('남의 1단계 댓글 200', st == 200, st)
st, rows = call('GET', '/posts/%s/comments' % owner, to)
root = next(c for c in rows if c['depth'] == 1 and c['authorId'] == other)
st, body = call('POST', '/posts/%s/comments' % owner, to, {'body': '고마워요', 'parentId': root['id']})
check('주인의 답글(2단계) 200', st == 200, (st, body))
st, rows = call('GET', '/posts/%s/comments' % owner, tv)
reply = next(c for c in rows if c['depth'] == 2)
st, _ = call('POST', '/posts/%s/comments' % owner, tv, {'body': '천만에요', 'parentId': reply['id']})
check('남의 답글(3단계) 200', st == 200, st)

print('\n[숫자] 내 포스트 댓글 수')
after = comments_on_me()
check('3개 늘었다(답글 포함)', after == before + 3, (before, after))

sql("DELETE FROM comments WHERE target_type = 'POST' AND target_id = '%s'" % post_id)
sql("DELETE FROM post_photos WHERE post_id = '%s'" % post_id)
sql("DELETE FROM posts WHERE id = '%s'" % post_id)
check.finish()
