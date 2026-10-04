# -*- coding: utf-8 -*-
"""프로필 [작성하기] 개편 검증 (기획서 261002 §8-1, V28).

확인하는 것:
  1. 사진 두 칸 — 얼굴(`/me/profile-photo`)과 자유(`/me/profile-main-photo`)가 **따로** 등록·제거된다.
     `GET /me`의 `photoUrl` / `mainPhotoUrl`, 남이 보는 [포스트 정보]의 `profilePhotoUrl` /
     `profileMainPhotoUrl`에 각각 실린다.
  2. 남의 업로드 key(`profile/<남의 id>/…`)는 내 칸에 등록할 수 없다 — 교체 때 남의 파일을 지우게 된다.
  3. 자기소개 300자(**코드포인트** — 이모지도 1자)까지 되고 301자는 거절된다. 옛 한도 50자를 넘는 글도 된다.
  4. 활동 지역은 1곳 — 2곳은 거절된다.
  5. 관심사는 그대로 3개.

실행: python tools/verify/verify_profile.py   (local 프로필 서버 + MariaDB)
"""
import sys
import urllib.request

sys.path.insert(0, __file__.rsplit('\\', 1)[0].rsplit('/', 1)[0])

from _common import BASE, Checks, call, clear_ties, login  # noqa: E402

check = Checks()

print('== 계정 준비 ==')
ta, a = login('verify-profile-a')
tb, b = login('verify-profile-b')
clear_ties([a, b])
for tok, nick in ((ta, 'vprofA'), (tb, 'vprofB')):
    call('POST', '/profile', tok,
         {'nickname': nick, 'birthYear': 2000, 'gender': 'FEMALE', 'country': 'KR'})
print('  A=%s  B=%s' % (a, b))

# 1x1 PNG
PNG = bytes.fromhex(
    '89504e470d0a1a0a0000000d4948445200000001000000010806000000'
    '1f15c4890000000d49444154789c6360000002000154a24f6d0000000049454e44ae426082')


def upload(token):
    st, issued = call('POST', '/me/profile-photo:upload-url?contentType=image/png', token)
    assert st == 200, (st, issued)
    url = issued['uploadUrl']
    req = urllib.request.Request(url if url.startswith('http') else BASE + url,
                                 data=PNG, method='PUT')
    req.add_header('Content-Type', 'image/png')
    req.add_header('Authorization', 'Bearer ' + token)
    urllib.request.urlopen(req).read()
    return issued['storageKey']


print('\n== 1. 사진 두 칸 ==')
for path in ('/me/profile-photo', '/me/profile-main-photo'):
    call('PUT', path, ta, {'storageKey': None})
face = upload(ta)
main = upload(ta)
check('얼굴 사진 등록', call('PUT', '/me/profile-photo', ta, {'storageKey': face})[0] == 200)
check('자유 사진 등록', call('PUT', '/me/profile-main-photo', ta, {'storageKey': main})[0] == 200)
me = call('GET', '/me', ta)[1]
check('GET /me — 두 칸이 각각 실린다',
      me['photoUrl'] and me['mainPhotoUrl'] and me['photoUrl'] != me['mainPhotoUrl'],
      (me['photoUrl'], me['mainPhotoUrl']))
info = call('GET', '/users/%s/post-info' % a, tb)
body = info[1] if info[0] == 200 else {}
check('[포스트 정보] — 남도 자유 사진을 받는다',
      body.get('profileMainPhotoUrl') and body.get('profilePhotoUrl'), info[0])

check('자유 사진만 제거 — 얼굴은 남는다',
      call('PUT', '/me/profile-main-photo', ta, {'storageKey': None})[0] == 200)
me = call('GET', '/me', ta)[1]
check('  → mainPhotoUrl 없음 · photoUrl 그대로', me['mainPhotoUrl'] is None and me['photoUrl'])

print('\n== 2. 남의 key ==')
other = upload(tb)
st, _ = call('PUT', '/me/profile-main-photo', ta, {'storageKey': other})
check('B의 업로드 key를 A의 칸에 등록 → 400', st == 400, st)
st, _ = call('PUT', '/me/profile-photo', ta, {'storageKey': other})
check('얼굴 칸도 같다 → 400', st == 400, st)

print('\n== 3. 자기소개 300자 ==')
check('120자(옛 한도 50 초과) 저장', call('PUT', '/me/intro', ta, {'intro': '가' * 120})[0] == 200)
check('300자 저장', call('PUT', '/me/intro', ta, {'intro': '가' * 300})[0] == 200)
check('이모지 300개(코드포인트 300, UTF-16 600) 저장',
      call('PUT', '/me/intro', ta, {'intro': '😀' * 300})[0] == 200)
st, _ = call('PUT', '/me/intro', ta, {'intro': '가' * 301})
check('301자 → 400', st == 400, st)
call('PUT', '/me/intro', ta, {'intro': ''})

print('\n== 4. 활동 지역 1곳 ==')
check('1곳 저장', call('PUT', '/me/regions', ta, {'codes': ['KR_SEOUL']})[0] == 200)
st, _ = call('PUT', '/me/regions', ta, {'codes': ['KR_SEOUL', 'KR_BUSAN']})
check('2곳 → 400', st == 400, st)
check('  → 1곳 그대로', call('GET', '/me', ta)[1]['regions'] == ['KR_SEOUL'])

print('\n== 5. 관심사 3개 ==')
check('3개 저장', call('PUT', '/me/interests', ta, {'codes': ['MOVIE', 'MUSIC', 'TRAVEL']})[0] == 200)
st, _ = call('PUT', '/me/interests', ta, {'codes': ['MOVIE', 'MUSIC', 'TRAVEL', 'GAME']})
check('4개 → 400', st == 400, st)

check.finish()
