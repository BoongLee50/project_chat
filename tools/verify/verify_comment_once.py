# -*- coding: utf-8 -*-
"""댓글 규칙 — 특히 **댓글 하나에 답글은 하나**(사용자 확정 2026-10-11, V30).

규칙(정본 docs/01 §댓글, 포스트·달빛 한마디 공통):
  1차 = 게시자 빼고 누구나 몇 번이든(게시자는 자기 글에 1차 금지)
  2차 = 게시자만, **1차 하나당 1번** · 3차 = 그 1차 쓴 사람만, **2차 하나당 1번** · 4차 없음

포스트 댓글 API로 확인한다. 달빛 한마디도 같은 `CommentService`를 지나므로 2·3차 규칙은 같이 검증되는 셈이다
(게시자 1차 금지만 호출부가 따로다 — 한마디 쪽은 verify_word.py가 본다).

🚨 **동시에 두 번 보낸 답글**도 본다 — 서버 검사("아직 답글이 없다")는 둘 다 통과하므로
DB 유니크(`uk_comments_parent`)가 막아야 한다. 500이 아니라 409 `COMMENT_ALREADY_REPLIED`여야 한다.

실행: python tools/verify/verify_comment_once.py   (local 프로필 서버 + MariaDB)
"""
import atexit
import sys
import threading

sys.path.insert(0, __file__.rsplit('\\', 1)[0].rsplit('/', 1)[0])
from _common import Checks, call, clear_ties, login, publish_post, sql  # noqa: E402

check = Checks()

ta, owner = login('verify-cmt-owner')    # 게시자
tb, b = login('verify-cmt-b')            # 댓글 단 사람
tc, c = login('verify-cmt-c')            # 제3자
clear_ties([owner, b, c])
for tok, nick in ((ta, 'vcmtA'), (tb, 'vcmtB'), (tc, 'vcmtC')):
    call('POST', '/profile', tok, {'nickname': nick, 'birthYear': 2000, 'gender': 'FEMALE', 'country': 'KR'})

post_id = 'vcmt-' + owner[:8]
publish_post(owner, post_id)


@atexit.register
def _cleanup():
    # 포스트는 _common이 지운다. 댓글은 포스트에 FK가 없어(V14) 따로 지운다 — 이 함수가 먼저 돈다(atexit은 역순).
    sql("DELETE FROM comments WHERE target_type = 'POST' AND target_id = '%s'" % post_id)


def comment(tok, body, parent=None):
    st, res = call('POST', '/posts/%s/comments' % owner, tok, {'body': body, 'parentId': parent})
    return st, (res or {}).get('code') if isinstance(res, dict) else None


def last_id_by(author, depth):
    return sql("SELECT id FROM comments WHERE target_type='POST' AND target_id='%s' AND author_id='%s' "
               "AND depth=%d ORDER BY created_at DESC, id DESC LIMIT 1" % (post_id, author, depth))[0][0]


print('\n[1차] 게시자는 못 달고, 남은 몇 번이든')
check('게시자 1차 → 403 COMMENT_OWN_POST', comment(ta, '내 글에 내가') == (403, 'COMMENT_OWN_POST'))
check('B 1차 → 200', comment(tb, '첫 댓글')[0] == 200)
c1 = last_id_by(b, 1)
check('B 1차 한 번 더 → 200(1차는 몇 번이든)', comment(tb, '두 번째 댓글')[0] == 200)
c1b = last_id_by(b, 1)

print('\n[2차] 게시자만 · 1차 하나당 1번')
check('제3자 C가 2차 → 403 COMMENT_REPLY_NOT_ALLOWED', comment(tc, '끼어들기', c1) == (403, 'COMMENT_REPLY_NOT_ALLOWED'))
check('B가 자기 1차에 2차 → 403 COMMENT_REPLY_NOT_ALLOWED', comment(tb, '혼잣말', c1) == (403, 'COMMENT_REPLY_NOT_ALLOWED'))
check('게시자 2차 → 200', comment(ta, '고마워요', c1)[0] == 200)
c2 = last_id_by(owner, 2)
check('🚨 게시자 같은 1차에 2차 또 → 409 COMMENT_ALREADY_REPLIED',
      comment(ta, '한 번 더', c1) == (409, 'COMMENT_ALREADY_REPLIED'))
check('제3자 C가 이미 답글 있는 1차에 → 403 NOT_ALLOWED(이 대화의 사람이 아니다가 먼저)',
      comment(tc, '끼어들기2', c1) == (403, 'COMMENT_REPLY_NOT_ALLOWED'))

print('\n[3차] 그 1차 쓴 사람만 · 2차 하나당 1번')
check('게시자가 자기 2차에 3차 → 403 NOT_ALLOWED', comment(ta, '혼잣말', c2) == (403, 'COMMENT_REPLY_NOT_ALLOWED'))
check('B 3차 → 200', comment(tb, '저도요', c2)[0] == 200)
c3 = last_id_by(b, 3)
check('🚨 B 같은 2차에 3차 또 → 409 COMMENT_ALREADY_REPLIED',
      comment(tb, '한 번 더', c2) == (409, 'COMMENT_ALREADY_REPLIED'))
check('4차 → 409 COMMENT_DEPTH_EXCEEDED', comment(ta, '4단계', c3) == (409, 'COMMENT_DEPTH_EXCEEDED'))

print('\n[새 1차] 더 이야기하려면 1차를 새로 — 그 아래에서 다시 세 마디')
check('B의 두 번째 1차에 게시자 2차 → 200', comment(ta, '이쪽도 고마워요', c1b)[0] == 200)

print('\n[동시에 두 번] 보내기를 두 번 누른 것처럼 — DB 유니크가 막는다')
check('B 1차(세 번째) → 200', comment(tb, '세 번째 댓글')[0] == 200)
c1c = last_id_by(b, 1)
results = []
barrier = threading.Barrier(2)


def race(n):
    barrier.wait()
    results.append(comment(ta, '동시 %d' % n, c1c))


ts = [threading.Thread(target=race, args=(n,)) for n in (1, 2)]
for t in ts:
    t.start()
for t in ts:
    t.join()
oks = [r for r in results if r[0] == 200]
dups = [r for r in results if r == (409, 'COMMENT_ALREADY_REPLIED')]
check('동시 2건 중 하나만 200, 나머지는 409(500 아님)', len(oks) == 1 and len(dups) == 1, results)

kids = sql("SELECT COUNT(*) FROM comments WHERE parent_id = '%s'" % c1c)[0][0]
check('그 1차의 답글은 정확히 1개', kids == '1', kids)
over = sql("SELECT COUNT(*) FROM (SELECT parent_id FROM comments WHERE target_id='%s' AND parent_id IS NOT NULL "
           "GROUP BY parent_id HAVING COUNT(*) > 1) x" % post_id)[0][0]
check('이 포스트에 답글이 둘 달린 댓글은 0개', over == '0', over)

check.finish()
