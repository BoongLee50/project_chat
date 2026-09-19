# -*- coding: utf-8 -*-
"""UI 전달본(Plan_Chat/UI)과 저장소 에셋을 **같은 이름끼리** 맞대 본다.

🚨 "그 해시가 에셋 어딘가에 있나"로는 부족하다. 기획은 **같은 이름으로 내용만 살짝 바꿔**
다시 보내기도 한다 — 그럴 때는 **그 이름의 파일이 같은가**를 봐야 잡힌다.

사용법:
    python tools/spec/compare_ui_delivery.py                 # 기본 경로
    python tools/spec/compare_ui_delivery.py "<UI 폴더>"      # 다른 기기(D:/Plan_Chat/UI 등)

전달본 → 저장소 이름 규칙(docs/08 §0, docs/14 §2):
  - 폴더:  Scene_Post → scene_post,  "Talk List" → talk_list  (소문자 · 공백은 밑줄)
  - 파일:  `*_jap.png` → 같은 폴더의 `ja/*.png`(UI 언어 변형) ·  `*_kor.png` → 접미사를 뗀 원문
           · 파일명의 공백은 밑줄(`frame_post_album Pass.png` → `frame_post_album_pass.png`)
  - ⚠️ `icon_flag_kor/jap`·`filtering_nation_kor/jap`·`icon_sflag_*`·`icon_mflag_*`은
    **언어가 아니라 나라**라서 이름 그대로 둔다(둘 다 항상 필요하다).
  - `Example/` 폴더(좌표·참고 그림)는 에셋이 아니라서 보지 않는다.

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
DEFAULT_UI = 'D:/MyProject/Plan_Chat/UI'

# 언어가 아니라 **나라**를 뜻하는 접미사 — ja/로 옮기지 않는다.
COUNTRY_PREFIXES = ('icon_flag_', 'filtering_nation_', 'icon_sflag_', 'icon_mflag_')


def dir_name(part):
    return part.lower().replace(' ', '_')


def file_name(name):
    """공백이 든 이름만 **밑줄 + 소문자**로 바꾼다(`frame_post_album Pass` → `_pass`).

    그 밖의 대소문자는 전달본 그대로 둔다(`button_Moonlight`·`Interest_movie`).
    """
    return name.replace(' ', '_').lower() if ' ' in name else name


def target_rel(rel_dir, name):
    """전달 파일(상대 폴더, 이름) → 저장소 상대 경로."""
    folder = '/'.join(dir_name(p) for p in rel_dir.split('/') if p)
    is_country = name.startswith(COUNTRY_PREFIXES)
    if not is_country and name.endswith('_jap.png'):
        return folder + '/ja/' + file_name(name[:-len('_jap.png')] + '.png')
    if not is_country and name.endswith('_kor.png'):
        return folder + '/' + file_name(name[:-len('_kor.png')] + '.png')
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


def main(ui_root):
    if not os.path.isdir(ui_root):
        print('전달본 폴더가 없다: %s' % ui_root)
        return 2

    seen_targets = set()
    counts = {'same': 0, 'changed': 0, 'new': 0}
    report = []

    for dp, dirs, files in os.walk(ui_root):
        dirs[:] = [d for d in dirs if d != 'Example']
        rel_dir = os.path.relpath(dp, ui_root).replace(os.sep, '/')
        if rel_dir == '.':
            continue
        for name in sorted(files):
            if not name.lower().endswith('.png'):
                continue
            src = os.path.join(dp, name)
            rel = target_rel(rel_dir, name)
            dst = os.path.join(ASSETS, rel.replace('/', os.sep))
            seen_targets.add(rel)
            if not os.path.exists(dst):
                counts['new'] += 1
                report.append(('🆕 저장소에 없음', rel_dir + '/' + name, ''))
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
    print('같음 %d · 🔴 이름 같고 다름 %d · 🆕 새 그림 %d · 저장소에만 %d\n'
          % (counts['same'], counts['changed'], counts['new'], len(only_repo)))
    for kind, path, note in report:
        print('  %-16s %-58s %s' % (kind, path, note))
    for rel in sorted(only_repo):
        print('  %-16s %s' % ('(저장소에만 있음)', rel))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else DEFAULT_UI))
