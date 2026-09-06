# -*- coding: utf-8 -*-
"""검증 스크립트 공용 도구 — 로컬 서버 + 로컬 MariaDB를 직접 두드린다.

왜 파이썬인가: 규칙 검증에는 **DB를 직접 만지는 일**이 꼭 낀다.
"15일 전에 온 신청"을 API로 만들 방법은 없어서, 행을 넣고 시각을 뒤로 미는 수밖에 없다.

⚠️ **local 프로필로 띄운 개발 서버에서만 쓸 것.**
   - 목 로그인(`app.auth.social.mock.enabled`)으로 계정을 만든다
   - 배치 수동 실행(`app.scheduler.dev-trigger-enabled`)을 부른다
   둘 다 운영에서는 꺼져 있다.

⚠️ **배치는 개발 DB 전체를 본다.** 내 테스트 계정만 세면 결과가 안 맞는다(함정 #61) —
   배치가 돌려주는 건수를 `==`로 단정하지 말고 `>=`로 볼 것.
"""
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request

BASE = os.environ.get('VERIFY_BASE', 'http://localhost:8080')
MYSQL = os.environ.get(
    'VERIFY_MYSQL', r'D:/dev-tools/mariadb-11.4.5-winx64/bin/mysql.exe')
DB_USER = os.environ.get('VERIFY_DB_USER', 'moonlighttalk')
DB_PASS = os.environ.get('VERIFY_DB_PASS', 'moonlighttalk')
DB_NAME = os.environ.get('VERIFY_DB_NAME', 'moonlighttalk')


def sql(query):
    """행 목록(각 행은 칼럼 문자열 리스트). 결과가 없으면 빈 리스트."""
    p = subprocess.run(
        [MYSQL, '-u' + DB_USER, '-p' + DB_PASS, '-N', '-B', DB_NAME, '-e', query],
        capture_output=True, text=True, encoding='utf-8')
    if p.returncode != 0:
        raise RuntimeError('SQL 실패: ' + (p.stderr or '').strip())
    out = (p.stdout or '').strip()
    return [ln.split('\t') for ln in out.split('\n') if ln.strip()] if out else []


def scalar(query, default=None):
    rows = sql(query)
    return rows[0][0] if rows else default


def call(method, path, token=None, body=None):
    """(status, parsed_body). 오류 응답도 예외 대신 그대로 돌려준다."""
    data = json.dumps(body).encode('utf-8') if body is not None else None
    req = urllib.request.Request(BASE + path, data=data, method=method)
    req.add_header('Content-Type', 'application/json')
    if token:
        req.add_header('Authorization', 'Bearer ' + token)
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read().decode('utf-8')
            return r.status, (json.loads(raw) if raw else None)
    except urllib.error.HTTPError as e:
        raw = e.read().decode('utf-8')
        try:
            return e.code, json.loads(raw)
        except ValueError:
            return e.code, raw


def login(tag):
    """목 로그인 → (accessToken, userId). 같은 tag면 같은 계정이 돌아온다."""
    st, body = call('POST', '/auth/social',
                    body={'provider': 'GOOGLE', 'providerToken': tag})
    if st != 200:
        raise RuntimeError(
            '목 로그인 실패(%s) — local 프로필로 띄웠는가? %s' % (st, body))
    return body['accessToken'], body['user']['id']


def session_date():
    """영업일 경계는 KST 18시다 — 18시 이전이면 '어제'가 오늘 영업일이다."""
    return scalar("SELECT DATE(NOW() - INTERVAL IF(HOUR(NOW()) < 18, 1, 0) DAY)")


def publish_post(user_id, post_id):
    """그 사람을 오늘 가든 후보로 만든다(포스트를 '공유'한 상태)."""
    sql("INSERT INTO posts (id, user_id, session_date, published_at, content_updated_at) "
        "VALUES ('%s','%s','%s', NOW(), NOW()) "
        "ON DUPLICATE KEY UPDATE published_at = NOW(), content_updated_at = NOW()"
        % (post_id, user_id, session_date()))


def clear_ties(user_ids):
    """검증 시작 전 이 사람들 사이의 신청·친구·신고·차단을 지운다."""
    ids = ','.join("'%s'" % u for u in user_ids)
    sql("DELETE FROM chat_requests WHERE from_user IN (%s) OR to_user IN (%s)" % (ids, ids))
    sql("DELETE FROM friendships WHERE requester_id IN (%s) OR addressee_id IN (%s)" % (ids, ids))
    sql("DELETE FROM blocks  WHERE blocker_id  IN (%s) OR blocked_id IN (%s)" % (ids, ids))
    sql("DELETE FROM reports WHERE reporter_id IN (%s) OR target_id  IN (%s)" % (ids, ids))


class Checks:
    """통과/실패를 모아 두었다가 마지막에 종료 코드로 돌려준다."""

    def __init__(self):
        self.rows = []

    def __call__(self, name, ok, detail=''):
        self.rows.append((name, bool(ok)))
        print(('  OK   ' if ok else '  FAIL ') + name + ('  ' + str(detail) if detail else ''))
        return bool(ok)

    def finish(self):
        bad = [n for n, ok in self.rows if not ok]
        print('\n== 결과 == %d/%d 통과' % (len(self.rows) - len(bad), len(self.rows)))
        for n in bad:
            print('  실패: ' + n)
        sys.exit(1 if bad else 0)
