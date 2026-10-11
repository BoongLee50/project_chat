# -*- coding: utf-8 -*-
"""포스트 사진 잠금 검증 — 기획서 261011 3-1 (유료 → 무료 전환).

규칙
  1. 유료(앨범패스)로 9장 올렸다가 무료가 되면 **사진은 지우지 않는다**
  2. 남에게는 **메인(TOP) 1장 + 바로 다음 슬롯 1장**만 보인다 — 가든·[포스트 정보]·친구 포스트 전부
     (메인이 마지막 슬롯이면 **직전 슬롯** — 메인 삭제 승계와 같은 방향)
  3. 내 화면에는 9장이 다 오고, 나머지 7장은 `locked: true`
  4. 잠긴 사진은 TOP으로 세울 수 없다(`POST_PHOTO_LOCKED`) — 세우면 공개 범위가 옮겨 가 잠금이 풀린다
  5. 유료를 다시 쓰면 잠금이 전부 풀린다(저장하지 않고 매번 계산하므로 따로 할 일이 없다)

사진은 DB에 직접 넣는다(파일 없음). 다운로드 URL에 storage key가 실리므로 **어느 사진이 나갔는지**를
key로 가려낸다. 끝나면 이 계정의 포스트·친구 관계·패스를 지운다(가든에 빈 사진 카드가 남지 않게).

실행: python tools/verify/verify_post_lock.py   (local 프로필 서버 + MariaDB)
"""
import sys
import urllib.parse

sys.path.insert(0, __file__.rsplit('\\', 1)[0].rsplit('/', 1)[0])
from _common import Checks, call, clear_ties, login, session_date, sql  # noqa: E402

check = Checks()

to, owner = login('verify-lock-owner')
tv, viewer = login('verify-lock-viewer')
clear_ties([owner, viewer])
for tok, nick in ((to, 'vlockO'), (tv, 'vlockV')):
    call('POST', '/profile', tok,
         {'nickname': nick, 'birthYear': 2000, 'gender': 'FEMALE', 'country': 'KR'})
print('  owner=%s  viewer=%s' % (owner, viewer))

day = session_date()
post_id = 'vlock-' + owner[:8]


def reset():
    sql("DELETE FROM post_photos WHERE user_id = '%s'" % owner)
    sql("DELETE FROM posts WHERE user_id = '%s' AND session_date = '%s'" % (owner, day))


def album_pass(user_id, on):
    sql("DELETE FROM user_entitlements WHERE user_id = '%s' AND kind = 'ALBUM_PASS'" % user_id)
    if on:
        sql("INSERT INTO user_entitlements (user_id, kind, source, started_at, expires_at) "
            "VALUES ('%s','ALBUM_PASS','LUNA_PURCHASE', NOW() - INTERVAL 1 DAY, NOW() + INTERVAL 1 DAY)"
            % user_id)
    else:
        # 만료 = 기간이 지난 행(구매 이력은 남는 실제 상황과 같게)
        sql("INSERT INTO user_entitlements (user_id, kind, source, started_at, expires_at) "
            "VALUES ('%s','ALBUM_PASS','LUNA_PURCHASE', NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 1 MINUTE)"
            % user_id)


def pid(n):
    return '%s-p%d' % (post_id, n)


def set_main(n):
    sql("UPDATE posts SET main_photo_id = '%s' WHERE id = '%s'" % (pid(n), post_id))


def slots(urls):
    """다운로드 URL → 사진 번호(order_idx). key가 `verify/vlock-…-pN.jpg`다."""
    out = []
    for u in urls:
        key = urllib.parse.unquote(u.split('key=')[-1])
        out.append(int(key.rsplit('-p', 1)[1].split('.')[0]))
    return out


def my_post():
    st, body = call('GET', '/posts/me', to)
    assert st == 200, (st, body)
    return body


def post_info_slots():
    st, body = call('GET', '/users/%s/post-info' % owner, tv)
    assert st == 200, (st, body)
    return slots(body['photoUrls']), body['totalPhotos']


def friend_slots():
    st, body = call('GET', '/friends/%s/today-post' % fid, tv)
    assert st == 200, (st, body)
    return slots(body['photoUrls'])


# ── 준비: 유료로 9장(order 0~8, 표시 순서는 최신순 8,7,…,0), 메인은 가운데 4번 ──
reset()
album_pass(owner, True)
album_pass(viewer, True)  # 보는 쪽 열람 제한(무료는 메인 1장)이 안 끼게
sql("INSERT INTO posts (id, user_id, session_date, published_at, content_updated_at) "
    "VALUES ('%s','%s','%s', NOW(), NOW())" % (post_id, owner, day))
for n in range(9):
    sql("INSERT INTO post_photos (id, post_id, user_id, storage_key, order_idx, created_at) "
        "VALUES ('%s','%s','%s','verify/%s.jpg', %d, NOW())" % (pid(n), post_id, owner, pid(n), n))
set_main(4)
fid = 'vlock-f-' + owner[:8]
sql("INSERT INTO friendships (id, requester_id, addressee_id, status, pair_key, accepted_at) "
    "VALUES ('%s','%s','%s','ACCEPTED', CONCAT(LEAST('%s','%s'),'_',GREATEST('%s','%s')), NOW())"
    % (fid, owner, viewer, owner, viewer, owner, viewer))

print('\n[유료] 9장 전부 열림')
me = my_post()
check('내 화면 9장', len(me['photos']) == 9, len(me['photos']))
check('잠금 0장', not any(p['locked'] for p in me['photos']))
check('maxPhotos 9', me['maxPhotos'] == 9, me['maxPhotos'])
s, total = post_info_slots()
check('[포스트 정보] 9장 · 메인이 첫 장', len(s) == 9 and s[0] == 4 and total == 9, (s, total))

print('\n[무료 전환] 메인 4 + 다음 슬롯 3만 공개')
album_pass(owner, False)
me = my_post()
locked = sorted(int(p['id'].rsplit('-p', 1)[1]) for p in me['photos'] if p['locked'])
check('내 화면에는 9장 그대로(안 지운다)', len(me['photos']) == 9, len(me['photos']))
check('잠금 7장 = 메인·다음 슬롯 뺀 나머지', locked == [0, 1, 2, 5, 6, 7, 8], locked)
check('maxPhotos 2', me['maxPhotos'] == 2, me['maxPhotos'])
s, total = post_info_slots()
check('[포스트 정보] [4, 3]', s == [4, 3] and total == 2, (s, total))
check('친구 포스트 [4, 3]', friend_slots() == [4, 3], friend_slots())

print('\n[TOP] 잠긴 사진은 못 세우고, 열린 사진은 세울 수 있다')
st, body = call('POST', '/posts/photos/%s:main' % pid(6), to)
check('잠긴 6번 TOP → 409 POST_PHOTO_LOCKED',
      st == 409 and (body or {}).get('code') == 'POST_PHOTO_LOCKED', (st, body))
st, _ = call('POST', '/posts/photos/%s:main' % pid(3), to)
check('열린 3번 TOP → 200', st == 200, st)
s, _ = post_info_slots()
check('공개가 [3, 2]로 옮겨 감', s == [3, 2], s)

print('\n[끝 슬롯] 메인이 마지막(0번)이면 직전 슬롯 1번')
set_main(0)
s, _ = post_info_slots()
check('[포스트 정보] [0, 1]', s == [0, 1], s)
set_main(4)

print('\n[무료에서 메인 삭제] 다음 슬롯이 메인을 잇고 공개도 한 칸 내려간다')
st, _ = call('DELETE', '/posts/photos/%s' % pid(4), to)
check('4번 삭제 → 200', st == 200, st)
s, _ = post_info_slots()
check('[포스트 정보] [3, 2]', s == [3, 2], s)

print('\n[유료 재개] 잠금이 전부 풀린다')
album_pass(owner, True)
me = my_post()
check('잠금 0장', not any(p['locked'] for p in me['photos']))
s, total = post_info_slots()
check('[포스트 정보] 8장 · 메인 3이 첫 장', len(s) == 8 and s[0] == 3 and total == 8, (s, total))

# ── 정리 ──
reset()
clear_ties([owner, viewer])
sql("DELETE FROM user_entitlements WHERE user_id IN ('%s','%s') AND kind = 'ALBUM_PASS'"
    % (owner, viewer))
check.finish()
