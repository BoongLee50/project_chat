# -*- coding: utf-8 -*-
"""🚨 가든 순서는 **진입할 때 한 번** 정해진다 — 그 뒤에 차단해도 사라지는가.

`verify_moderation.py`의 가든 검사는 **첫 페이지**만 본다. 커서가 없으면 순서를 다시 짜므로
후보 산정 질의(`selectFeedCandidates`)만 타고, 그쪽에는 원래부터 차단 조건이 있었다.

**진짜 구멍은 두 번째 페이지에 있었다.**
순서가 확정된 뒤의 스크롤은 전부 `selectCandidatesByIds`로 한 페이지씩 채우는데,
여기에는 아무 조건도 없어서 **차단당한 쪽 화면에 차단한 사람이 계속 나왔다.**

그래서 이 검사는 순서를 **먼저 만들어 두고**, 그 뒤에 차단하고, **2페이지를 읽는다.**
📌 이 파일을 지우지 말 것 — 첫 페이지만 보는 검사로는 이 회귀를 절대 못 잡는다.

실행: python tools/verify/verify_feed_block_page2.py
"""
import sys

sys.path.insert(0, __file__.rsplit('\\', 1)[0].rsplit('/', 1)[0])

from _common import Checks, call, login, publish_post, sql  # noqa: E402

PAGE_SIZE = 10          # GardenService.PAGE_SIZE
POPULATION = PAGE_SIZE + 5   # 두 페이지가 나오도록 넉넉히

check = Checks()

tb, viewer = login('verify-pg-viewer')

others = []
for i in range(POPULATION):
    _, uid = login('verify-pg-%d' % i)
    others.append(uid)
    publish_post(uid, 'vp-post-%d' % i)

ids = ','.join("'%s'" % u for u in others + [viewer])
sql("DELETE FROM blocks  WHERE blocker_id  IN (%s) OR blocked_id IN (%s)" % (ids, ids))
sql("DELETE FROM reports WHERE reporter_id IN (%s) OR target_id  IN (%s)" % (ids, ids))
sql("DELETE FROM feed_exposures WHERE user_id = '%s'" % viewer)

# ① 가든에 들어온다 — 이 순간 순서가 정해져 세션 동안 유지된다.
st, page1 = call('GET', '/feed', tb)
first = [i['userId'] for i in page1['items']] if isinstance(page1, dict) else []
cursor = page1.get('nextCursor') if isinstance(page1, dict) else None
print('  1페이지 %d명, 커서=%s' % (len(first), cursor))
if not check('두 번째 페이지가 나온다(후보가 충분한가)', bool(cursor), '' if cursor else page1):
    check.finish()

# ② **순서가 정해진 뒤에**, 1페이지에 없던 사람이 나를 차단한다.
later = [u for u in others if u not in first]
if not check('1페이지 밖에 있는 후보가 있다', bool(later)):
    check.finish()
blocker = later[0]
tv, _ = login('verify-pg-%d' % others.index(blocker))
st, _ = call('POST', '/blocks', tv, {'targetUserId': viewer})
check('차단이 접수됐다', st in (200, 204), st)

# ③ 계속 스크롤한다. 캐시된 순서에는 아직 그 사람이 들어 있다.
st, page2 = call('GET', '/feed?cursor=%s' % cursor, tb)
second = [i['userId'] for i in page2['items']] if isinstance(page2, dict) else []
print('  2페이지: %d명' % len(second))
check('순서가 정해진 뒤 차단해도 2페이지에서 사라진다', blocker not in second, blocker)

check.finish()
