# -*- coding: utf-8 -*-
"""그래픽 전달본(Plan_Chat/그래픽 소스 — 2026-11-14까지는 Plan_Chat/UI)과 저장소 에셋을 **같은 이름끼리** 맞대 본다.

🚨 "그 해시가 에셋 어딘가에 있나"로는 부족하다. 기획은 **같은 이름으로 내용만 살짝 바꿔**
다시 보내기도 한다 — 그럴 때는 **그 이름의 파일이 같은가**를 봐야 잡힌다.

사용법:
    python tools/spec/compare_ui_delivery.py                 # 기본 경로
    python tools/spec/compare_ui_delivery.py "D:/Plan_Chat/그래픽 소스"   # 이 PC(기본값은 다른 기기 경로)

전달본 → 저장소 이름 규칙(docs/08 §0, docs/14 §2):
  - 폴더:  Scene_Post → scene_post,  "Talk List" → talk_list  (소문자 · 공백은 밑줄)
  - 파일:  `*_jap.png`·`*_jp.png` → 같은 폴더의 `ja/*.png`(UI 언어 변형) ·  `*_kor.png`·`*_kr.png` → 접미사를 뗀 원문
           · 파일명의 공백은 밑줄(`frame_post_album Pass.png` → `frame_post_album_pass.png`)
  - ⚠️ `icon_flag_kor/jap`·`filtering_nation_kor/jap`·`icon_sflag_*`·`icon_mflag_*`·`icon_mmflag_*`(달빛 한마디)은
    **언어가 아니라 나라**라서 이름 그대로 둔다(둘 다 항상 필요하다).
  - 시안(좌표·참고 그림)은 에셋이 아니라서 보지 않는다 — 예전엔 `Example/` 폴더, 2026-11부터는 **한글 파일명**(is_mockup).

결과 네 가지:
  같음            — 그대로 적용돼 있다
  🔴 이름 같고 다름 — 기획이 같은 이름으로 바꿔 보낸 것. 규격·바뀐 영역을 함께 보여 준다
  🆕 저장소에 없음  — 아직 안 들인 새 그림
  (저장소에만 있음) — 전달본에서 빠졌거나 이름이 바뀐 것
"""
import hashlib
import io
import os
import sys

try:
    from PIL import Image, ImageChops
except ImportError:  # 픽셀 비교 없이도 해시 대조는 된다
    Image = None

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ASSETS = os.path.join(ROOT, 'assets', 'images')
DEFAULT_UI = 'D:/MyProject/Plan_Chat/그래픽 소스'

# 🚨 2026-11-15부터 전달 폴더가 `Plan_Chat/그래픽 소스/`로 바뀌었다 — 폴더 이름이 **한글**이다.
# 한글은 소문자·밑줄 규칙으로 저장소 경로가 안 나오므로 **여기서 짝을 지어 준다**(저장소 쪽은 예전 `scene_*` 그대로).
# 표에 없는 폴더는 예전 규칙(소문자·공백→밑줄)으로 떨어지고 `⚠️ 짝 없음`으로 표시된다 — 새 폴더가 오면 여기에 한 줄.
KOREAN_DIRS = {
    '포스트 화면': 'scene_post',
    '달빛가든 화면': 'scene_garden',
    '대화방 화면': 'scene_talk', '대화방 화면/대화 목록': 'scene_talk/talk_list',
    '대화방 화면/받은 신청': 'scene_talk/application_received',
    '채팅창': 'scene_chat',
    '친구방 화면': 'scene_friend', '친구방 화면/친구목록': 'scene_friend/friend_list',
    '친구방 화면/받은 신청': 'scene_friend/application_received',
    '프로필 화면': 'scene_profile', '프로필 화면/작성하기': 'scene_profile/create',
    '프로필 화면/미리보기': 'scene_profile/preview',
    '달빛 한마디 화면': 'scene_word', '달빛 한마디 화면/타이틀': 'scene_word/title',
    '달빛 한마디 화면/질문 답글 화면': 'scene_word/reply_register',
    '달빛 한마디 화면/답글 목록 화면': 'scene_word/reply_list',
    '달빛 한마디 화면/답글 상세 화면': 'scene_word/reply_detail',
    # 상점(신버전)은 상점 세션이 **상품 화면 그림을 한 벌로 모아** `scene_shop/item`에 들였다(폴더마다 겹쳐 와서).
    # 프라임 구독 관리 쪽만 `prime_sub/` 아래 화면별로 나뉜다.
    '상점 화면 (신버전)': 'scene_shop/item',
    '상점 화면 (신버전)/상품별 관리 화면/프라임 구독 관리 화면/프라임 구독 관리': 'scene_shop/prime_sub/sub_manage',
    '상점 화면 (신버전)/상품별 관리 화면/프라임 구독 관리 화면/프라임 구독 해지': 'scene_shop/prime_sub/sub_end',
    '상점 화면 (신버전)/상품별 관리 화면/프라임 구독 관리 화면/프라임 구독 해지 취소': 'scene_shop/prime_sub/sub_end_cancel',
    '상점 화면 (신버전)/상품별 구매 화면/프라임 구독 구매': 'scene_shop/prime_sub/sub_start',
}
# 들이지 않는 폴더 — 구버전 상점은 루나 상점이 폐지되며 신버전으로 대체됐다(기획서 261111).
SKIP_DIRS = ('상점 화면 (구버전)',)
# 상점(신버전)의 짝 없는 하위 폴더는 모두 `scene_shop/item`으로 모은다(위 주석).
FLATTEN_PREFIX = {'상점 화면 (신버전)': 'scene_shop/item'}


def map_korean_dir(rel_dir):
    """한글 전달 폴더 → 저장소 폴더. 짝이 없으면 None."""
    if rel_dir in KOREAN_DIRS:
        return KOREAN_DIRS[rel_dir]
    for prefix, target in FLATTEN_PREFIX.items():
        if rel_dir.startswith(prefix + '/'):
            return target
    return None


def is_mockup(name):
    """시안(좌표값·참고화면)인가 — 2026-11부터 `Example/` 없이 리소스와 섞여 온다.

    **파일명에 한글이 있으면 시안**이다(`…_좌표값.png` · `… 참고화면.png` · `화면 확인 샘플.png`).
    실제 리소스는 영문 이름(`button_*` · `frame_*` · `icon_*` · `title_*` · `back_*`)이다.
    """
    return any('\uac00' <= ch <= '\ud7a3' for ch in name)

# 언어가 아니라 **나라**를 뜻하는 접미사 — ja/로 옮기지 않는다.
COUNTRY_PREFIXES = ('icon_flag_', 'filtering_nation_', 'icon_sflag_', 'icon_mflag_',
                    'icon_mmflag_')


def dir_name(part):
    return part.lower().replace(' ', '_')


def file_name(name):
    """공백이 든 이름만 **밑줄 + 소문자**로 바꾼다(`frame_post_album Pass` → `_pass`).

    그 밖의 대소문자는 전달본 그대로 둔다(`button_Moonlight`·`Interest_movie`).
    """
    return name.replace(' ', '_').lower() if ' ' in name else name


def target_rel(rel_dir, name):
    """전달 파일(상대 폴더, 이름) → 저장소 상대 경로."""
    folder = map_korean_dir(rel_dir) or '/'.join(dir_name(p) for p in rel_dir.split('/') if p)
    is_country = name.startswith(COUNTRY_PREFIXES)
    # 프로필(Scene_Profile)부터는 접미사가 `_jp`·`_kr`로도 온다 — 뜻은 같다.
    for suffix in ('_jap.png', '_jp.png'):
        if not is_country and name.endswith(suffix):
            return folder + '/ja/' + file_name(name[:-len(suffix)] + '.png')
    for suffix in ('_kor.png', '_kr.png'):
        if not is_country and name.endswith(suffix):
            return folder + '/' + file_name(name[:-len(suffix)] + '.png')
    return folder + '/' + file_name(name)


def md5(path):
    return hashlib.md5(io.open(path, 'rb').read()).hexdigest()


def describe_change(src, dst):
    if Image is None:
        return ''
    a = Image.open(src).convert('RGBA')
    b = Image.open(dst).convert('RGBA')
    if a.size != b.size:
        return '규격 %dx%d → %dx%d' % (b.size + a.size)
    diff = ImageChops.difference(a, b)
    # 🚨 RGBA의 getbbox()는 기본이 **알파 채널만** 본다(Pillow 10+) — 색만 바뀐 그림을
    # "픽셀 동일"로 잘못 말한다(실제로 그랬다). 모든 채널을 보게 한다.
    try:
        box = diff.getbbox(alpha_only=False)
    except TypeError:  # alpha_only가 없는 옛 Pillow
        box = diff.convert('RGB').getbbox() or diff.split()[3].getbbox()
    return '픽셀 동일(다시 저장만 됨)' if box is None else '바뀐 영역 %s' % (box,)


# 🚨 **같은 그림은 한 벌만**(사용자 결정 2026-11-15) — 여러 화면 폴더에 **바이트까지 같은** 그림이 오면
# **먼저 들어온 곳 한 벌만** 저장소에 두고 나머지 화면은 그것을 가리킨다. 이 표는
# "전달본의 이 자리(저장소 경로로 옮긴 것) → 실제로 쓰는 한 벌"이다.
# - 전달본이 그 자리에 **같은 그림**을 계속 보내면 `같음`으로 센다(군더더기를 다시 들이지 않는다).
# - **그 폴더 판만 바뀌어 오면** `🟠 공용 그림 다름`으로 따로 알린다 — 고치면 그 한 벌을 쓰는 화면이 **전부** 바뀐다.
#   두 화면이 같이 바뀌어도 되는지 보고, 안 되면 그때 따로 들여 가른다(그리고 이 표에서 그 줄을 지운다).
SHARED = {
    'scene_chat/icon_flag_jap.png': 'scene_garden/icon_flag_jap.png',
    'scene_chat/icon_flag_kor.png': 'scene_garden/icon_flag_kor.png',
    'scene_word/reply_detail/icon_flag_jap.png': 'scene_garden/icon_flag_jap.png',
    'scene_word/reply_detail/icon_flag_kor.png': 'scene_garden/icon_flag_kor.png',
    'scene_chat/button_infotrans.png': 'scene_word/reply_detail/button_infotrans.png',
    'scene_chat/button_message_color.png': 'scene_word/reply_detail/button_message_color.png',
    'scene_chat/button_message_normal.png': 'scene_word/reply_detail/button_message_normal.png',
    'scene_chat/frame_chat_profile.png': 'scene_word/reply_detail/frame_commentprofile.png',
    'scene_profile/preview/icon_mflag_jap.png': 'scene_friend/friend_list/icon_mflag_jap.png',
    'scene_profile/preview/icon_mflag_kor.png': 'scene_friend/friend_list/icon_mflag_kor.png',
    'scene_word/reply_detail/button_heart.png': 'scene_garden/button_heart.png',
    'scene_post/icon_pick.png': 'scene_garden/button_Pick.png',
    'scene_profile/create/Interest_movie.png': 'scene_garden/Interest_movie.png',
    'scene_word/reply_detail/button_previewback.png': 'scene_profile/preview/button_previewback.png',
    'scene_shop/item/icon_notice.png': 'scene_shop/prime_sub/sub_end/icon_notice.png',
    'scene_shop/item/icon_primecheck.png': 'scene_shop/prime_sub/sub_start/icon_primecheck.png',
    'scene_shop/item/icon_primeuse.png': 'scene_shop/prime_sub/sub_manage/icon_primeuse.png',
    'scene_shop/item/ja/icon_primeuse.png': 'scene_shop/prime_sub/sub_manage/ja/icon_primeuse.png',
    'scene_word/reply_detail/frame_userprofile.png': 'scene_word/reply_list/frame_userprofile.png',
    'scene_word/reply_detail/icon_mmflag_jap.png': 'scene_word/reply_list/icon_mmflag_jap.png',
    'scene_word/reply_detail/icon_mmflag_kor.png': 'scene_word/reply_list/icon_mmflag_kor.png',
    # 친구 [받은 신청] 탭 = 대화방 그림(2026-09-19부터 한 벌)
    'scene_friend/friend_list/button_receive_color.png': 'scene_talk/talk_list/button_receive_color.png',
    'scene_friend/friend_list/button_receive_normal.png': 'scene_talk/talk_list/button_receive_normal.png',
    # 화면 폴더마다 따라오는 상단 [Prime] — 공용은 가든 것 하나(ArtTopBar)
    # (포스트는 2026-11-15부터 자기 Prime(277×92)을 따로 쓴다 — 루나가 빠지며 커졌다. 공용 표에서 뺐다)
    'scene_talk/talk_list/button_prime.png': 'scene_garden/button_prime.png',
    'scene_talk/application_received/button_prime.png': 'scene_garden/button_prime.png',
    'scene_friend/friend_list/button_prime.png': 'scene_garden/button_prime.png',
    'scene_friend/application_received/button_prime.png': 'scene_garden/button_prime.png',
}


def asset_hashes():
    """저장소 에셋 전부의 해시 → 경로. 새 그림이 **이미 다른 이름·폴더로 있는지** 알려 주려고."""
    out = {}
    for dp, _, files in os.walk(ASSETS):
        for f in files:
            p = os.path.join(dp, f)
            out.setdefault(md5(p), os.path.relpath(p, ASSETS).replace(os.sep, '/'))
    return out


def main(ui_root):
    if not os.path.isdir(ui_root):
        print('전달본 폴더가 없다: %s' % ui_root)
        return 2

    seen_targets = set()
    counts = {'same': 0, 'changed': 0, 'new': 0, 'mockup': 0, 'shared_changed': 0}
    report = []
    unmapped = set()
    by_hash = asset_hashes()

    for dp, dirs, files in os.walk(ui_root):
        dirs[:] = [d for d in dirs if d != 'Example']
        rel_dir = os.path.relpath(dp, ui_root).replace(os.sep, '/')
        if rel_dir == '.':
            continue
        if rel_dir.startswith(SKIP_DIRS):
            continue
        if is_mockup(rel_dir.split('/')[0]) and map_korean_dir(rel_dir) is None:
            unmapped.add(rel_dir)
        for name in sorted(files):
            if not name.lower().endswith('.png'):
                continue
            if is_mockup(name):
                counts['mockup'] += 1  # 시안 — 에셋이 아니다
                continue
            src = os.path.join(dp, name)
            rel = target_rel(rel_dir, name)
            if rel in SHARED:  # 공용 한 벌과 맞대 본다
                shared = SHARED[rel]
                seen_targets.add(shared)
                dst = os.path.join(ASSETS, shared.replace('/', os.sep))
                if md5(src) == md5(dst):
                    counts['same'] += 1
                else:
                    counts['shared_changed'] += 1
                    report.append(('🟠 공용 그림 다름', rel_dir + '/' + name,
                                   '공용 %s · %s — 고치면 쓰는 화면 전부 바뀐다'
                                   % (shared, describe_change(src, dst))))
                continue
            dst = os.path.join(ASSETS, rel.replace('/', os.sep))
            seen_targets.add(rel)
            if not os.path.exists(dst):
                counts['new'] += 1
                twin = by_hash.get(md5(src))
                report.append(('🆕 저장소에 없음', rel_dir + '/' + name,
                               ('⚠️ 같은 그림이 이미 있다: %s → 들이지 말고 SHARED에 한 줄' % twin) if twin else ''))
            elif md5(src) == md5(dst):
                counts['same'] += 1
            else:
                counts['changed'] += 1
                report.append(('🔴 이름 같고 다름', rel_dir + '/' + name,
                               describe_change(src, dst)))

    only_repo = []
    for dp, _, files in os.walk(ASSETS):
        for f in files:
            rel = os.path.relpath(os.path.join(dp, f), ASSETS).replace(os.sep, '/')
            if rel.startswith('scene_') and rel not in seen_targets:
                only_repo.append(rel)

    print('전달본: %s' % ui_root)
    print('같음 %d · 🔴 이름 같고 다름 %d · 🟠 공용 그림 다름 %d · 🆕 새 그림 %d · 저장소에만 %d  (시안 %d장은 건너뜀)\n'
          % (counts['same'], counts['changed'], counts['shared_changed'], counts['new'],
             len(only_repo), counts['mockup']))
    for d in sorted(unmapped):
        print('  ⚠️ 짝 없음(KOREAN_DIRS에 한 줄 넣을 것): %s' % d)
    for kind, path, note in report:
        print('  %-16s %-58s %s' % (kind, path, note))
    for rel in sorted(only_repo):
        print('  %-16s %s' % ('(저장소에만 있음)', rel))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else DEFAULT_UI))
