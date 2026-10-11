"""달빛 한마디 더미 — 임시 유저(`seed_users.py`의 40명) 일부가 **오늘의 질문에 답한 것처럼** 채운다.

    python tools/demo/seed_word.py           # 오늘 것을 지우고 다시 채운다(몇 초)
    python tools/demo/seed_word.py --clean   # 지우기만
    python tools/demo/seed_word.py --me      # + [LINE] 목 계정(`mock-dev-line`)이 대댓글을 시험할 댓글들

- 14명(한국 7 · 일본 7)이 답한다. 글은 각자 나라 말 · 사진은 절반쯤(그 사람의 포스트 사진을 다시 쓴다) ·
  하나는 200자 가까운 긴 글(셀이 틀 높이보다 커지는 모양 확인용)
- 서로 **좋아요**(자기 글엔 안 누른다 — 2026-10-11 규칙)와 **댓글**(A → B → A 한 스레드 포함)을 붙인다
- 시각은 지금으로부터 몇 분 ~ 몇 시간 전으로 흩어 `N분 전`·`N시간 전`이 섞여 보이게
- `--me`: [LINE] 목 계정(내 계정)으로 **대댓글을 직접 달아 보게** 판을 깐다(2026-10-11 사용자 요청)
  · **내 한마디에 남이 단 1단계 댓글 5개**(사진 1개 포함) → 내가 **2단계 답글**을 단다
  · 그중 하나는 이미 끝난 대화(남 → 나 → 남, 3단계)라 더는 못 다는 것도 볼 수 있다
  · **남의 한마디 2개에 내 1단계 댓글 + 글쓴이 답글** → 내가 **3단계**를 단다
  · 내 한마디가 없으면 하나 만든다(`temp-word-me`). 내가 직접 쓴 한마디는 지우지 않는다

🚨 **오늘 영업일 것이라 KST 18:05 배치에 지워진다** — 다음 날 목록이 비면 다시 돌릴 것.
먼저 `python tools/demo/seed_users.py`로 40명이 있어야 한다(얼굴·포스트 사진 파일도 그 스크립트가 만든다).
전부 `temp-word-` 접두어라 다른 더미와 섞이지 않는다. 오늘 질문이 아직 없으면 서버와 같은 방법으로 후보에서 하나 만든다.
"""

import random
import subprocess
import sys
import uuid
from datetime import datetime, timedelta, timezone

MYSQL = r"D:/dev-tools/mariadb-11.4.5-winx64/bin/mysql.exe"
DB = ["-umoonlighttalk", "-pmoonlighttalk", "moonlighttalk", "--default-character-set=utf8mb4"]
KST = timezone(timedelta(hours=9))
ROLLOVER_HOUR = 18  # app.session.rollover-hour

KR_BODIES = [
    "퇴근길에 본 노을이 오늘 제일 예뻤어요. 하늘이 분홍색으로 물들었거든요 🌇",
    "한강 따라 걷다가 본 야경이요. 바람도 시원해서 한참 앉아 있었어요.",
    "오랜만에 친구랑 통화하면서 실컷 웃었던 순간이요. 별거 아닌데 기분이 좋아지더라고요.",
    "창밖으로 보이는 보름달! 사진으로는 반도 안 담겨서 아쉬워요 🌕",
    "점심에 먹은 따뜻한 국밥 한 그릇이 오늘을 버티게 해줬어요 ㅎㅎ",
    "비 그친 뒤 골목길 냄새가 좋았어요. 이런 날은 천천히 걷게 돼요.",
    "오늘은 정말 길었어요. 아침에 버스를 놓쳐서 뛰었고, 회의는 두 번이나 미뤄졌고, 점심도 거의 못 먹었어요. "
    "그런데 집에 오는 길에 편의점 앞 고양이가 제 다리에 몸을 비비는데 그 순간 하루 피로가 다 풀리는 느낌이었어요. "
    "작은 위로가 제일 크게 남는 것 같아요. 내일은 간식 챙겨서 다시 가 보려고요 😺",
]
JP_BODIES = [
    "帰り道に見た夕焼けが一番きれいでした。空がピンク色に染まっていました🌇",
    "川沿いを散歩しながら見た夜景です。風も気持ちよくて、つい長居しちゃいました。",
    "久しぶりに友だちと電話して笑ったことかな。小さなことだけど元気が出ました。",
    "窓から見えた満月！写真だと半分も伝わらないのが残念です🌕",
    "お昼に食べたあったかいラーメンが今日の支えでした笑",
    "雨上がりの路地の匂いが好きでした。こんな日はゆっくり歩きたくなります。",
    "猫がひざの上で寝てしまった瞬間です。動けなくて困ったけど幸せでした😺",
]
KR_COMMENTS = ["와 저도 오늘 노을 봤어요!", "사진 너무 예뻐요 😍", "공감해요 ㅎㅎ", "저도 그런 날 있었어요", "오늘 하루도 수고했어요 🌙"]
JP_COMMENTS = ["わかります！", "写真すてきですね😍", "今日もお疲れさまでした🌙", "私も同じこと思いました", "いいですね〜"]


def q(v):
    if v is None:
        return "NULL"
    return "'" + str(v).replace("\\", "\\\\").replace("'", "''") + "'"


def run_sql(text):
    p = subprocess.run([MYSQL, *DB, "-N", "-B"], input=text, capture_output=True, text=True, encoding="utf-8")
    if p.returncode != 0:
        sys.exit("SQL 실패:\n" + p.stderr)
    return p.stdout.strip()


def session_date():
    now = datetime.now(KST)
    return (now - timedelta(days=1)).date() if now.hour < ROLLOVER_HOUR else now.date()


CLEAN = """
-- 더미 댓글에 사람이 앱에서 단 답글(3단계까지)도 함께 — 부모가 사라져 떠도는 줄이 남지 않게.
DELETE FROM comments WHERE target_type = 'DAILY_ANSWER' AND parent_id IN
    (SELECT id FROM (SELECT id FROM comments WHERE parent_id LIKE 'temp-word-%') x);
DELETE FROM comments WHERE target_type = 'DAILY_ANSWER' AND parent_id LIKE 'temp-word-%';
DELETE FROM comments WHERE target_type = 'DAILY_ANSWER' AND (target_id LIKE 'temp-word-%' OR id LIKE 'temp-word-%');
DELETE FROM daily_answers WHERE id LIKE 'temp-word-%';
"""


def ensure_question(sdate):
    """오늘 질문 id. 없으면 서버(`selectUnusedFromBank`)처럼 아직 안 쓴 후보에서 하나 만든다."""
    qid = run_sql("SELECT id FROM daily_questions WHERE session_date = %s;" % q(sdate))
    if qid:
        return qid
    run_sql("""
INSERT IGNORE INTO daily_questions (id, session_date, body_ko, body_ja, created_at)
SELECT %s, %s, b.body_ko, b.body_ja, NOW()
FROM daily_question_bank b
     LEFT JOIN (SELECT body_ko, MAX(session_date) AS last_used FROM daily_questions GROUP BY body_ko) x
            ON x.body_ko = b.body_ko
ORDER BY x.last_used IS NOT NULL, x.last_used, b.id
LIMIT 1;""" % (q(str(uuid.uuid4())), q(sdate)))
    return run_sql("SELECT id FROM daily_questions WHERE session_date = %s;" % q(sdate))


def main():
    run_sql(CLEAN)
    if "--clean" in sys.argv:
        print("달빛 한마디 더미를 지웠다.")
        return

    rows = run_sql("""
SELECT u.id, u.country, p.photo_key FROM users u JOIN user_profiles p ON p.user_id = u.id
WHERE u.id LIKE 'temp-%' AND u.status = 'ACTIVE' ORDER BY u.id;""")
    users = [r.split("\t") for r in rows.splitlines() if r]
    kr = [u for u in users if u[1] == "KR"]
    jp = [u for u in users if u[1] == "JP"]
    if len(kr) < 7 or len(jp) < 7:
        sys.exit("임시 유저가 모자란다 — 먼저 python tools/demo/seed_users.py")

    rnd = random.Random(1011)
    sdate = session_date()
    qid = ensure_question(sdate)
    writers = rnd.sample(kr, 7) + rnd.sample(jp, 7)
    rnd.shuffle(writers)

    s = []
    answers = []  # (answer_id, user_id, country, minutes)
    used = {"KR": 0, "JP": 0}  # 나라별로 글을 차례대로 — 7명에 7개라 긴 글도 꼭 하나 들어간다
    for i, (uid, country, face) in enumerate(writers):
        aid = "temp-word-%02d" % i
        bodies = KR_BODIES if country == "KR" else JP_BODIES
        body = bodies[used[country] % len(bodies)]
        used[country] += 1
        # 사진은 그 사람의 포스트 사진(seed/temp/NN_post1.jpg) — 절반쯤만.
        num = face.split("/")[-1].split("_")[0] if face else None
        image = "seed/temp/%s_post1.jpg" % num if num and rnd.random() < 0.55 else None
        minutes = rnd.randint(2, 330)
        s.append(
            "INSERT INTO daily_answers (id, question_id, user_id, session_date, body, image_key, created_at) "
            "VALUES (%s,%s,%s,%s,%s,%s, NOW(3) - INTERVAL %d MINUTE);"
            % (q(aid), q(qid), q(uid), q(sdate), q(body), q(image), minutes))
        answers.append((aid, uid, country, minutes))

    everyone = [u[0] for u in users]
    for aid, owner, country, minutes in answers:
        # 좋아요 — 자기 글엔 누르지 않는다(규칙).
        for liker in rnd.sample([u for u in everyone if u != owner], rnd.randint(0, 9)):
            s.append("INSERT IGNORE INTO daily_answer_likes (answer_id, user_id, created_at) VALUES (%s,%s, NOW());"
                     % (q(aid), q(liker)))
        # 댓글 — 1단계는 남이, 그중 하나엔 글쓴이 답글 → 댓글 단 사람 답글(A → B → A).
        for k in range(rnd.randint(0, 3)):
            author = rnd.choice([u for u in users if u[0] != owner])
            pool = KR_COMMENTS if author[1] == "KR" else JP_COMMENTS
            cid = "%s-c%d" % (aid, k)
            ago = rnd.randint(1, max(1, minutes - 1))
            s.append("INSERT INTO comments (id, target_type, target_id, author_id, body, parent_id, depth, created_at) "
                     "VALUES (%s,'DAILY_ANSWER',%s,%s,%s,NULL,1, NOW(3) - INTERVAL %d MINUTE);"
                     % (q(cid), q(aid), q(author[0]), q(rnd.choice(pool)), ago))
            if k == 0 and rnd.random() < 0.6:
                reply = "고마워요 🙂" if country == "KR" else "ありがとうございます🙂"
                s.append("INSERT INTO comments (id, target_type, target_id, author_id, body, parent_id, depth, created_at) "
                         "VALUES (%s,'DAILY_ANSWER',%s,%s,%s,%s,2, NOW(3) - INTERVAL %d MINUTE);"
                         % (q(cid + "r"), q(aid), q(owner), q(reply), q(cid), max(0, ago - 1)))
                s.append("INSERT INTO comments (id, target_type, target_id, author_id, body, parent_id, depth, created_at) "
                         "VALUES (%s,'DAILY_ANSWER',%s,%s,%s,%s,3, NOW(3) - INTERVAL %d MINUTE);"
                         % (q(cid + "rr"), q(aid), q(author[0]), q("🙌"), q(cid + "r"), max(0, ago - 2)))
    run_sql("\n".join(s))

    if "--me" in sys.argv:
        seed_me(qid, sdate, users, answers)

    n = run_sql("SELECT COUNT(*) FROM daily_answers WHERE id LIKE 'temp-word-%';")
    c = run_sql("SELECT COUNT(*) FROM comments WHERE target_id LIKE 'temp-word-%';")
    l = run_sql("SELECT COUNT(*) FROM daily_answer_likes WHERE answer_id LIKE 'temp-word-%';")
    print("영업일 %s : 답 %s · 좋아요 %s · 댓글 %s" % (sdate, n, l, c))


def comment_sql(cid, target, author, body, parent, depth, ago_min, image=None):
    return ("INSERT INTO comments (id, target_type, target_id, author_id, body, parent_id, depth, image_key, created_at) "
            "VALUES (%s,'DAILY_ANSWER',%s,%s,%s,%s,%d,%s, NOW(3) - INTERVAL %d MINUTE);"
            % (q(cid), q(target), q(author), q(body), q(parent), depth, q(image), ago_min))


def seed_me(qid, sdate, users, answers):
    """[LINE] 목 계정이 2단계·3단계 답글을 직접 달아 볼 수 있는 판."""
    me = run_sql("SELECT id FROM users WHERE provider='LINE' AND provider_uid='mock-dev-line';")
    if not me:
        print("[LINE] 목 계정이 없다 — 앱에서 [LINE]으로 한 번 로그인할 것. --me 건너뜀")
        return
    mine = run_sql("SELECT id FROM daily_answers WHERE question_id = %s AND user_id = %s;" % (q(qid), q(me)))
    if not mine:
        mine = "temp-word-me"
        run_sql("INSERT INTO daily_answers (id, question_id, user_id, session_date, body, created_at) "
                "VALUES (%s,%s,%s,%s,%s, NOW(3) - INTERVAL 90 MINUTE);"
                % (q(mine), q(qid), q(me), q(sdate), q("오늘은 퇴근길 한강 야경이 제일 예뻤어요 🌙")))

    others = [u for u in users if u[0] != me]
    kr = [u for u in others if u[1] == "KR"]
    jp = [u for u in others if u[1] == "JP"]
    s = []
    # ① 내 한마디에 남이 단 1단계 댓글 — 내가 2단계를 단다.
    firsts = [
        (kr[0], "저도 오늘 한강 갔었어요! 바람 좋더라고요", None),
        (jp[0], "夜景いいですね！どのあたりですか？", None),
        (kr[1], "사진도 보여주세요 📸", None),
        (jp[1], "私もこんな景色見てみたいです✨", "seed/temp/%s_post1.jpg" % jp[1][2].split('/')[-1].split('_')[0]),
        (kr[2], "퇴근길 야경 최고죠 👍", None),
    ]
    for k, (u, body, image) in enumerate(firsts):
        s.append(comment_sql("temp-word-me-c%d" % k, mine, u[0], body, None, 1, 40 - k * 6, image))
    # 이미 끝난 대화 하나(남 → 나 → 남) — 3단계라 더는 답글을 못 단다.
    s.append(comment_sql("temp-word-me-done", mine, jp[2][0], "今日もお疲れさまでした🌙", None, 1, 70))
    s.append(comment_sql("temp-word-me-done-r", mine, me, "감사해요! 좋은 밤 보내세요", "temp-word-me-done", 2, 65))
    s.append(comment_sql("temp-word-me-done-rr", mine, jp[2][0], "おやすみなさい😊", "temp-word-me-done-r", 3, 60))

    # ② 남의 한마디에 내 1단계 + 글쓴이 2단계 — 내가 3단계를 단다.
    picked = [a for a in answers if a[1] != me][:2]
    for k, (aid, owner, country, minutes) in enumerate(picked):
        cid = "temp-word-me-on%d" % k
        reply = "고마워요! 오늘 하루 어땠어요?" if country == "KR" else "ありがとう！今日はどんな一日でした？"
        s.append(comment_sql(cid, aid, me, "글 너무 좋아요 :)", None, 1, 30 + k))
        s.append(comment_sql(cid + "r", aid, owner, reply, cid, 2, 20 + k))
    run_sql("\n".join(s))
    print("내 계정(%s): 내 한마디 %s 에 1단계 댓글 %d개(+끝난 대화 1) · 남의 한마디 %d개에 3단계 차례"
          % (me[:8], mine[:12], len(firsts), len(picked)))


if __name__ == "__main__":
    main()
