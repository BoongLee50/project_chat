# -*- coding: utf-8 -*-
"""달빛 한마디 검증 (기획서 261011 9-1·9-2, V29).

확인하는 것:
  1. **내 답을 등록해야 남의 답을 본다**(9-1) — 등록 전 [답글 목록]·남의 [답글 상세]는
     403 `DAILY_ANSWER_NOT_YET`. 내 것은 등록 직후 볼 수 있다.
  2. 답변글 **200자**(띄어쓰기 포함) — **코드포인트**로 센다. 이모지가 섞인 200자는 되고
     (`length()`로 세면 201이라 예전엔 거절됐다 — 함정 #82), 201자는 `DAILY_ANSWER_TOO_LONG`.
  3. 목록 셀 재료 — 얼굴 사진(`photoUrl`) · 접속(`online`) · 나라 · 시간(`createdAt`)이 실린다.

실행: python tools/verify/verify_word.py   (local 프로필 서버 + MariaDB)
⚠️ 두 검증 계정의 답을 지우고 시작하고, 끝나면 다시 지운다(하루 한 번만 쓸 수 있고, 실기기 목록에도 뜬다).
"""
import sys

sys.path.insert(0, __file__.rsplit('\\', 1)[0].rsplit('/', 1)[0])

from _common import Checks, call, clear_ties, login, sql  # noqa: E402

check = Checks()

print('== 계정 준비 ==')
ta, a = login('verify-word-a')
tb, b = login('verify-word-b')
clear_ties([a, b])
call('POST', '/profile', ta,
     {'nickname': 'vwordA', 'birthYear': 2000, 'gender': 'FEMALE', 'country': 'KR'})
call('POST', '/profile', tb,
     {'nickname': 'vwordB', 'birthYear': 2001, 'gender': 'MALE', 'country': 'JP'})
st, today = call('GET', '/daily-question/today?lang=ko', ta)
check('오늘의 질문', st == 200 and today.get('question'), st)
sql("DELETE FROM daily_answers WHERE user_id IN ('%s','%s')" % (a, b))
print('  A=%s(KR)  B=%s(JP)' % (a, b))

print('\n== 1. 등록 전에는 목록이 닫혀 있다 ==')
st, body = call('GET', '/daily-question/answers', ta)
check('등록 전 목록 → 403 DAILY_ANSWER_NOT_YET',
      st == 403 and body.get('code') == 'DAILY_ANSWER_NOT_YET', (st, body))

print('\n== 2. 200자 — 코드포인트 ==')
too_long = 'a' * 200 + '😀'
st, body = call('POST', '/daily-question/answers', ta, {'body': too_long})
check('201자(이모지 포함) → 400 DAILY_ANSWER_TOO_LONG',
      st == 400 and body.get('code') == 'DAILY_ANSWER_TOO_LONG', (st, body))

just = '오늘 ' + '가' * 196 + '😀'  # 코드포인트 200, UTF-16 201
assert len(just.encode('utf-16-le')) // 2 == 201
st, mine = call('POST', '/daily-question/answers', ta, {'body': just})
check('이모지 섞인 200자 → 등록된다', st == 200 and mine.get('body') == just, st)
check('DB에도 200자 그대로', sql(
    "SELECT CHAR_LENGTH(body) FROM daily_answers WHERE user_id = '%s'" % a) == [['200']])

st, body = call('POST', '/daily-question/answers', ta, {'body': '두 번째'})
check('하루 한 번 → 409 DAILY_ANSWER_ALREADY',
      st == 409 and body.get('code') == 'DAILY_ANSWER_ALREADY', (st, body))

print('\n== 1-2. 남의 상세도 등록 뒤에만 ==')
st, body = call('GET', '/daily-question/answers/%s' % mine['id'], tb)
check('B(미등록)가 A의 상세 → 403', st == 403 and body.get('code') == 'DAILY_ANSWER_NOT_YET',
      (st, body))
st, body = call('GET', '/daily-question/answers', tb)
check('B(미등록) 목록 → 403', st == 403, st)
st, _ = call('GET', '/daily-question/answers/me', ta)
check('A는 내 한마디를 본다', st == 200, st)

st, b_mine = call('POST', '/daily-question/answers', tb, {'body': 'こんばんは'})
check('B 등록', st == 200, st)
st, rows = call('GET', '/daily-question/answers', tb)
check('B 등록 뒤 목록이 열린다', st == 200 and isinstance(rows, list), st)
st, body = call('GET', '/daily-question/answers/%s' % mine['id'], tb)
check('B 등록 뒤 A의 상세가 열린다', st == 200, st)

print('\n== 3. 셀 재료 ==')
row = next((r for r in rows if r['id'] == mine['id']), None)
check('목록에 A가 있다', row is not None)
if row:
    for key in ('photoUrl', 'online', 'country', 'createdAt'):
        check('셀 재료 `%s`가 실린다' % key, key in row, row.get(key))
    check('A의 나라는 KR', row.get('country') == 'KR')

# 검증 데이터는 실기기 목록에도 뜬다(함정 #81) — 끝나면 지운다. 화면을 보려면 이 줄을 잠시 막을 것.
sql("DELETE FROM daily_answers WHERE user_id IN ('%s','%s')" % (a, b))

check.finish()
