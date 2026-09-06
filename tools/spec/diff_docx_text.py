# -*- coding: utf-8 -*-
"""기획서 두 판의 **본문 전체**를 비교한다.

🚨 **기획서를 새로 받으면 화면·이미지만 보지 말 것.** 260906판에서 아홉 줄이 달라졌는데
화면만 본 세션은 **네 줄로 기록**했고, 6-1·6-2에 조용히 늘어난 다섯 줄(받은 신청 14일 만료,
신고·차단 시 목록 삭제)을 놓쳤다. 이 스크립트면 몇 초다.

사용법:
    python tools/spec/diff_docx_text.py "<옛 기획서.docx>" "<새 기획서.docx>"
    python tools/spec/diff_docx_text.py "<기획서.docx>" --dump out.txt   # 본문만 뽑기

덤: `--media`는 문서에 박힌 그림을 해시로 비교해 **어느 화면이 교체됐는지** 알려 준다
(이미지는 Visio OLE의 EMF 미리보기라 그림 자체를 열려면 별도 처리가 필요하다).

이 PC에는 pandoc·LibreOffice가 없어 `word/document.xml`을 직접 읽는다.
⚠️ 정규식은 반드시 `<w:t(?: [^>]*)?>` — `<w:t[^>]*>`로 잡으면 **`<w:tblPr>`까지 매칭**돼
   표 서식 XML이 본문인 척 통째로 딸려 나온다(처음에 실제로 당했다).
"""
import difflib
import hashlib
import io
import re
import sys
import zipfile

# `<w:t>` 와 `<w:t xml:space="preserve">` 만. `<w:tbl...>` 류는 잡지 않는다.
TEXT_RE = re.compile(r'<w:t(?: [^>]*)?>(.*?)</w:t>|\n', re.S)
ENTITIES = (('&amp;', '&'), ('&lt;', '<'), ('&gt;', '>'),
            ('&quot;', '"'), ('&apos;', "'"))


def body_lines(path):
    """문단 단위 본문 줄 목록(빈 줄 제거)."""
    with zipfile.ZipFile(path) as z:
        xml = z.read('word/document.xml').decode('utf-8')

    xml = xml.replace('</w:p>', '\n</w:p>')          # 문단 경계
    xml = re.sub(r'<w:br[^>]*/>', '\n', xml)          # 줄바꿈
    xml = re.sub(r'<w:tab[^>]*/>', '\t', xml)

    parts = []
    for m in TEXT_RE.finditer(xml):
        parts.append('\n' if m.group(0) == '\n' else m.group(1))
    text = ''.join(parts)
    for a, b in ENTITIES:
        text = text.replace(a, b)
    return [ln.strip() for ln in text.split('\n') if ln.strip()]


def media_hashes(path):
    """{파일명: (해시8, 바이트수)} — 어느 그림이 바뀌었는지 보려는 것."""
    out = {}
    with zipfile.ZipFile(path) as z:
        for name in z.namelist():
            if name.startswith('word/media/'):
                data = z.read(name)
                out[name.split('/')[-1]] = (hashlib.md5(data).hexdigest()[:8], len(data))
    return out


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2

    if '--dump' in argv:
        i = argv.index('--dump')
        lines = body_lines(argv[0])
        with io.open(argv[i + 1], 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))
        print('%d줄 → %s' % (len(lines), argv[i + 1]))
        return 0

    old_path, new_path = argv[0], argv[1]

    if '--media' in argv:
        old, new = media_hashes(old_path), media_hashes(new_path)
        old_h = {v[0] for v in old.values()}
        new_h = {v[0] for v in new.values()}
        print('그림 — 옛 %d장 / 새 %d장' % (len(old), len(new)))
        for name, v in sorted(new.items()):
            if v[0] not in old_h:
                print('  새로 왔거나 교체됨: %s (%s, %d바이트)' % (name, v[0], v[1]))
        for name, v in sorted(old.items()):
            if v[0] not in new_h:
                print('  빠졌거나 교체됨:   %s (%s, %d바이트)' % (name, v[0], v[1]))
        return 0

    old_lines, new_lines = body_lines(old_path), body_lines(new_path)
    diff = list(difflib.unified_diff(old_lines, new_lines,
                                     fromfile=old_path, tofile=new_path, lineterm=''))
    if not diff:
        print('본문이 같다.')
        return 0
    print('\n'.join(diff))
    changed = sum(1 for ln in diff if ln[:1] in '+-' and not ln.startswith(('+++', '---')))
    print('\n달라진 줄 %d개 — **전부 반영했는지 확인할 것.**' % changed)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
