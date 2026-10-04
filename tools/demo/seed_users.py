"""임시 유저 40명 — 가든·대화방·친구 화면이 사람으로 찼을 때 어떻게 보이는지 보려는 데이터.

    python tools/demo/seed_users.py            # 넣기(다시 돌리면 비우고 새로 넣는다)
    python tools/demo/seed_users.py --clean    # 지우기만

한국 남 10 · 한국 여 10 · 일본 남 10 · 일본 여 10. 나이는 18~44 랜덤(시드 고정이라 돌릴 때마다 같다).
전원에게 **얼굴 사진**(`photo_key` — 목록·셀) · **자유 사진**(`main_photo_key` — [미리 보기] 큰 칸) ·
**오늘 공유한 포스트 1~4장**(가든 카드)을 넣는다. 자기소개·관심사(0~3)·활동 지역(1곳)도 섞어서.

🚨 **포스트는 오늘 영업일 것이라 KST 18:05 배치에 지워진다.** 다음 날 가든이 비면 이 스크립트를 다시 돌릴 것
(사진 파일은 있으면 다시 안 만든다 — 몇 초면 끝난다).

[LINE] 목 로그인 계정(`mock-dev-line`)이 있으면 **대화방·친구 칸도 채운다**:
대화 중 6 · 받은 대화 신청 4 · 친구 8 · 받은 친구 신청 4. 계정이 없으면 이 부분만 건너뛴다.

전부 `temp-` 접두어다(`demo-`·`seed-`·`mock-verify-` 와 겹치지 않는다).
사진은 `server/server/uploads/seed/temp/` — 저장소에 없는 폴더(gitignore)라 기기마다 이 스크립트가 만든다.
그림은 **사람 실루엣 + 밤 풍경**이고, 구석에 `#07 FACE` 처럼 번호를 박아 두어 **어느 칸이 어느 사진을 쓰는지** 눈으로 맞춰 볼 수 있다.
"""

import random
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "server" / "server" / "uploads" / "seed" / "temp"
KEY_DIR = "seed/temp"
MYSQL = r"D:/dev-tools/mariadb-11.4.5-winx64/bin/mysql.exe"
DB = ["-umoonlighttalk", "-pmoonlighttalk", "moonlighttalk", "--default-character-set=utf8mb4"]
KST = timezone(timedelta(hours=9))
ROLLOVER_HOUR = 18  # app.session.rollover-hour

KR_M = ["민준", "서준", "도윤", "예준", "시우", "하준", "지호", "주원", "현우", "건우"]
KR_F = ["서연", "지민", "하은", "수빈", "윤아", "지유", "채은", "예나", "소율", "다은"]
JP_M = ["はると", "ゆうと", "そうた", "大翔", "蓮", "湊", "りく", "陽太", "かいと", "悠真"]
JP_F = ["ゆい", "さくら", "ひなた", "陽菜", "結衣", "あかり", "芽依", "りん", "美咲", "こはる"]

KR_INTRO = [
    "주말엔 사진 찍으러 돌아다녀요. 편하게 이야기해요!",
    "야경 보는 걸 좋아해요 🌙 일본 여행 계획 중이에요",
    "카페 투어랑 전시회 좋아합니다. 추천 받아요",
    "운동 끝나고 보는 밤하늘이 제일 좋아요",
    "일본어 공부 중이에요. 같이 대화해요 :)",
    "퇴근길 노을 사진 모으는 중",
    None, None,
]
JP_INTRO = [
    "韓国ドラマが大好きです！よろしくお願いします",
    "夜の散歩が好きです🌙 韓国語を勉強中です",
    "カフェ巡りと写真が趣味です。気軽に話しかけてね",
    "週末はよくキャンプに行きます",
    "ソウルに旅行したいです！おすすめ教えてください",
    "音楽とアニメが好き。仲良くしてください",
    None, None,
]
INTERESTS = ["TRAVEL", "PHOTO", "ART", "READING", "MUSIC", "MOVIE", "DRAMA", "GAME", "WORKOUT",
             "COOKING", "CAFE", "PET", "CAMPING", "EXHIBITION", "SINGING", "SELF_DEV", "FINANCE",
             "IT", "FASHION", "BEAUTY", "WELLBEING", "MINIMAL", "SUSTAINABLE", "KPOP", "JPOP",
             "ANIME", "WEBTOON", "MUSICAL", "FESTIVAL", "SOCCER", "BASEBALL", "BASKETBALL",
             "GOLF", "TENNIS", "SWIMMING", "CLIMBING", "CYCLING"]
KR_REGIONS = ["KR_SEOUL", "KR_SEOUL", "KR_BUSAN", "KR_INCHEON", "KR_DAEGU", "KR_GWANGJU",
              "KR_DAEJEON", "KR_SUWON", "KR_SEONGNAM", "KR_GOYANG"]
JP_REGIONS = ["JP_TOKYO", "JP_TOKYO", "JP_OSAKA", "JP_KYOTO", "JP_NAGOYA", "JP_YOKOHAMA",
              "JP_FUKUOKA", "JP_SAPPORO", "JP_KOBE", "JP_SENDAI"]

# 묶음별 바탕색 — 목록에서 한눈에 갈리게(한남 파랑 · 한여 분홍 · 일남 청록 · 일여 산호)
GROUP_TINT = {("KR", "MALE"): (60, 90, 170), ("KR", "FEMALE"): (190, 90, 140),
              ("JP", "MALE"): (40, 140, 140), ("JP", "FEMALE"): (210, 110, 90)}
SKIN = [(244, 214, 190), (232, 196, 165), (214, 170, 135), (250, 225, 205)]
HAIR = [(30, 25, 25), (60, 40, 30), (95, 65, 45), (20, 20, 35), (140, 100, 70)]


# ───────────────────────── 사진 ─────────────────────────

def font(size):
    try:
        return ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", size)
    except OSError:
        return ImageFont.load_default(size=size)


def gradient(w, h, top, bottom):
    col = Image.linear_gradient("L").resize((w, h))
    return Image.composite(Image.new("RGB", (w, h), bottom), Image.new("RGB", (w, h), top), col)


def mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def tag(img, text):
    d = ImageDraw.Draw(img)
    f = font(max(22, img.width // 22))
    x0, y0, x1, y1 = d.textbbox((0, 0), text, font=f)
    pad = f.size // 3
    box = (pad, img.height - (y1 - y0) - pad * 3, pad * 3 + (x1 - x0), img.height - pad)
    d.rounded_rectangle(box, radius=pad, fill=(0, 0, 0))
    d.text((box[0] + pad, box[1] + pad - y0), text, font=f, fill=(255, 255, 255))


def person(img, rnd, gender, cx, cy, r):
    """머리·어깨 실루엣. r = 머리 반지름."""
    d = ImageDraw.Draw(img)
    skin, hair = rnd.choice(SKIN), rnd.choice(HAIR)
    shirt = tuple(rnd.randint(40, 220) for _ in range(3))
    if gender == "FEMALE":  # 긴 머리는 어깨 뒤로
        d.rounded_rectangle((cx - r * 1.25, cy - r * 0.6, cx + r * 1.25, cy + r * 2.3), radius=r, fill=hair)
    d.ellipse((cx - r * 2.3, cy + r * 1.6, cx + r * 2.3, cy + r * 5.2), fill=shirt)   # 어깨
    d.rectangle((cx - r * 0.38, cy + r * 0.7, cx + r * 0.38, cy + r * 1.8), fill=skin)  # 목
    d.ellipse((cx - r, cy - r * 1.1, cx + r, cy + r * 1.1), fill=skin)                  # 얼굴
    if gender == "FEMALE":
        d.chord((cx - r * 1.12, cy - r * 1.3, cx + r * 1.12, cy + r * 0.7), 180, 360, fill=hair)
    else:
        d.chord((cx - r * 1.05, cy - r * 1.25, cx + r * 1.05, cy + r * 0.25), 180, 360, fill=hair)
    ey = cy - r * 0.05
    for ex in (cx - r * 0.38, cx + r * 0.38):
        d.ellipse((ex - r * 0.09, ey - r * 0.09, ex + r * 0.09, ey + r * 0.09), fill=(40, 30, 30))
    d.arc((cx - r * 0.35, cy + r * 0.2, cx + r * 0.35, cy + r * 0.6), 20, 160, fill=(150, 70, 70), width=max(2, r // 18))


def moon(img, cx, cy, r):
    glow = Image.new("L", img.size, 0)
    ImageDraw.Draw(glow).ellipse((cx - r * 2, cy - r * 2, cx + r * 2, cy + r * 2), fill=120)
    glow = glow.filter(ImageFilter.GaussianBlur(r))
    img.paste(Image.composite(Image.new("RGB", img.size, (255, 244, 210)), img, glow))
    ImageDraw.Draw(img).ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 246, 222))


def stars(img, rnd, n, max_y):
    d = ImageDraw.Draw(img)
    for _ in range(n):
        x, y, s = rnd.randrange(img.width), rnd.randrange(int(max_y)), rnd.choice([1, 1, 2, 3])
        d.ellipse((x, y, x + s, y + s), fill=(255, 255, 240))


def scene(rnd, w, h):
    """밤 풍경 한 장 — 산 · 도시 · 바다 · 별밭 중 하나."""
    top = (rnd.randint(5, 40), rnd.randint(10, 40), rnd.randint(40, 100))
    bottom = mix(top, (rnd.randint(150, 250), rnd.randint(80, 170), rnd.randint(90, 180)), 0.8)
    img = gradient(w, h, top, bottom)
    stars(img, rnd, 140, h * 0.55)
    moon(img, rnd.randint(w // 5, w * 4 // 5), rnd.randint(h // 8, h // 3), rnd.randint(45, 80))
    d = ImageDraw.Draw(img)
    kind = rnd.choice(["mountain", "city", "sea", "field"])
    if kind == "mountain":
        for layer, base in enumerate((0.62, 0.72, 0.82)):
            c = mix(top, (0, 0, 0), 0.35 + layer * 0.2)
            pts, x = [(0, h)], 0
            while x <= w:
                pts.append((x, h * base - rnd.randint(0, int(h * 0.12))))
                x += rnd.randint(w // 8, w // 4)
            pts += [(w, h * base), (w, h)]
            d.polygon(pts, fill=c)
    elif kind == "city":
        x = 0
        while x < w:
            bw, bh = rnd.randint(w // 14, w // 6), rnd.randint(int(h * 0.15), int(h * 0.5))
            d.rectangle((x, h - bh, x + bw, h), fill=(15, 15, 25))
            for wy in range(h - bh + 12, h - 10, 26):
                for wx in range(x + 8, x + bw - 10, 20):
                    if rnd.random() < 0.45:
                        d.rectangle((wx, wy, wx + 9, wy + 12), fill=(255, 210, 120))
            x += bw + rnd.randint(2, 10)
    elif kind == "sea":
        sea_y = int(h * rnd.uniform(0.58, 0.7))
        d.rectangle((0, sea_y, w, h), fill=mix(top, (0, 0, 0), 0.3))
        for i in range(40):
            y = sea_y + i * (h - sea_y) // 40
            half = rnd.randint(10, 60)
            d.line((w // 2 - half, y, w // 2 + half, y), fill=(255, 240, 200), width=2)
    else:
        stars(img, rnd, 500, h * 0.8)
        d.ellipse((-w * 0.3, h * 0.78, w * 1.3, h * 1.6), fill=(10, 20, 15))
    return img


def face_photo(rnd, u):
    w = h = 640
    tint = GROUP_TINT[(u["country"], u["gender"])]
    img = gradient(w, h, mix(tint, (255, 255, 255), 0.35), mix(tint, (0, 0, 0), 0.3))
    person(img, rnd, u["gender"], w // 2, int(h * 0.42), int(w * 0.17))
    tag(img, "#%02d FACE" % u["n"])
    return img


def main_photo(rnd, u):
    img = scene(rnd, 900, 1200)
    person(img, rnd, u["gender"], rnd.randint(330, 570), 640, 120)
    tag(img, "#%02d MAIN" % u["n"])
    return img


def post_photo(rnd, u, i, total):
    img = scene(rnd, 900, 1200)
    tag(img, "#%02d POST %d/%d" % (u["n"], i + 1, total))
    return img


# ───────────────────────── 데이터 ─────────────────────────

def build_users():
    rnd = random.Random(20261004)
    now_year = datetime.now(KST).year
    users, n = [], 0
    for country, gender, names in (("KR", "MALE", KR_M), ("KR", "FEMALE", KR_F),
                                   ("JP", "MALE", JP_M), ("JP", "FEMALE", JP_F)):
        for name in names:
            n += 1
            seen = rnd.choice([timedelta(minutes=rnd.randint(1, 50)), timedelta(hours=rnd.randint(1, 20)),
                               timedelta(days=rnd.randint(1, 20)), None])
            users.append({
                "n": n, "id": "temp-%02d" % n, "nickname": name, "country": country, "gender": gender,
                "birth_year": now_year - rnd.randint(18, 44),
                "intro": rnd.choice(KR_INTRO if country == "KR" else JP_INTRO),
                "interests": rnd.sample(INTERESTS, rnd.choice([0, 1, 2, 3, 3, 3])),
                "region": rnd.choice(KR_REGIONS if country == "KR" else JP_REGIONS) if rnd.random() < 0.85 else None,
                "seen": seen, "photos": rnd.randint(1, 4),
            })
    return users


def q(v):
    if v is None:
        return "NULL"
    return "'" + str(v).replace("\\", "\\\\").replace("'", "''") + "'"


def ago(delta):
    return "NULL" if delta is None else "NOW() - INTERVAL %d SECOND" % int(delta.total_seconds())


def session_date():
    now = datetime.now(KST)
    return (now - timedelta(days=1)).date() if now.hour < ROLLOVER_HOUR else now.date()


CLEAN = """
DELETE FROM chat_messages   WHERE sender_id LIKE 'temp-%' OR room_id IN (SELECT id FROM chat_rooms WHERE user_a LIKE 'temp-%' OR user_b LIKE 'temp-%');
DELETE FROM translate_rooms WHERE room_id IN (SELECT id FROM chat_rooms WHERE user_a LIKE 'temp-%' OR user_b LIKE 'temp-%');
DELETE FROM chat_rooms      WHERE user_a LIKE 'temp-%' OR user_b LIKE 'temp-%';
DELETE FROM chat_requests   WHERE from_user LIKE 'temp-%' OR to_user LIKE 'temp-%';
DELETE FROM reports         WHERE reporter_id LIKE 'temp-%' OR target_id LIKE 'temp-%';
DELETE FROM users           WHERE id LIKE 'temp-%';
"""


def pair(a, b):
    return "CONCAT(LEAST(%s,%s),'_',GREATEST(%s,%s))" % (a, q(b), a, q(b))


def ties_sql():
    """[LINE] 목 로그인 계정과의 관계. @me가 NULL이면 INSERT … SELECT … WHERE @me IS NOT NULL 로 전부 건너뛴다."""
    s = ["SET @me = (SELECT id FROM users WHERE provider='LINE' AND provider_uid='mock-dev-line');"]
    # 대화 중 6 — 묶음마다 섞어서. 몇 칸은 안 읽음(N), 하나는 오래된 대화(시각 숨김 확인은 30일 넘어야 해서 생략)
    rooms = [("temp-01", "오늘 올린 야경 사진 어디서 찍었어요?", 3, True),
             ("temp-12", "저도 그 카페 가 봤어요! 분위기 정말 좋죠", 40, False),
             ("temp-23", "はじめまして！写真すごくきれいですね", 90, True),
             ("temp-34", "今度ソウルに行くので、おすすめ教えてください！", 300, False),
             ("temp-05", "네 좋아요 다음에 또 이야기해요 :)", 1500, False),
             ("temp-37", "おやすみなさい🌙", 4000, True)]
    for i, (uid, body, minutes, unread) in enumerate(rooms, 1):
        rid = "temp-r%d" % i
        s.append("INSERT INTO chat_rooms (id, user_a, user_b, status, type, active_pair_key, created_at) "
                 "SELECT %s, @me, %s, 'ACTIVE', 'MATCH', %s, NOW() - INTERVAL 3 DAY FROM DUAL WHERE @me IS NOT NULL;"
                 % (q(rid), q(uid), pair("@me", uid)))
        s.append("INSERT INTO chat_messages (id, room_id, sender_id, type, body, created_at, read_at) "
                 "SELECT %s, %s, @me, 'TEXT', '안녕하세요!', NOW() - INTERVAL %d MINUTE, NOW() FROM DUAL WHERE @me IS NOT NULL;"
                 % (q(rid + "-m1"), q(rid), minutes + 30))
        s.append("INSERT INTO chat_messages (id, room_id, sender_id, type, body, created_at, read_at) "
                 "SELECT %s, %s, %s, 'TEXT', %s, NOW() - INTERVAL %d MINUTE, %s FROM DUAL WHERE @me IS NOT NULL;"
                 % (q(rid + "-m2"), q(rid), q(uid), q(body), minutes, "NULL" if unread else "NOW()"))
    # 받은 대화 신청 4 — 둘은 안 열어 봄(N)
    reqs = [("temp-08", "프로필 사진 분위기가 너무 좋아서 연락드려요! 이야기 나눠요", 7, False),
            ("temp-27", "はじめまして！韓国の話を聞かせてください😊", 25, False),
            ("temp-15", "같은 동네네요! 산책 좋아하시면 이야기해요", 180, True),
            ("temp-39", "写真の雰囲気が好きです。仲良くしてください！", 600, True)]
    for i, (uid, msg, minutes, viewed) in enumerate(reqs, 1):
        s.append("INSERT INTO chat_requests (id, from_user, to_user, message, status, luna_cost, created_at, viewed_at) "
                 "SELECT %s, %s, @me, %s, 'PENDING', 0, NOW() - INTERVAL %d MINUTE, %s FROM DUAL WHERE @me IS NOT NULL;"
                 % (q("temp-q%d" % i), q(uid), q(msg), minutes,
                    "NOW() - INTERVAL %d MINUTE" % (minutes // 2) if viewed else "NULL"))
    # 친구 8 — 둘은 어제 친구가 됨(신규 N), 하나는 내가 고정
    friends = [("temp-02", 20, True), ("temp-13", 1, False), ("temp-24", 9, False), ("temp-31", 1, False),
               ("temp-06", 40, False), ("temp-17", 12, False), ("temp-28", 25, False), ("temp-36", 5, False)]
    for i, (uid, days, pinned) in enumerate(friends, 1):
        s.append("INSERT INTO friendships (id, requester_id, addressee_id, status, pair_key, created_at, accepted_at, requester_pinned_at) "
                 "SELECT %s, @me, %s, 'ACCEPTED', %s, NOW() - INTERVAL %d DAY, NOW() - INTERVAL %d DAY, %s FROM DUAL WHERE @me IS NOT NULL;"
                 % (q("temp-fs%d" % i), q(uid), pair("@me", uid), days + 1, days,
                    "NOW() - INTERVAL 1 HOUR" if pinned else "NULL"))
    # 받은 친구 신청 4 — 둘은 안 열어 봄(N)
    freqs = [("temp-09", "대화 즐거웠어요! 친구로 지내요 :)", 12, False),
             ("temp-30", "お話しできて楽しかったです！友達になってください", 50, False),
             ("temp-19", "사진 취향이 비슷해서 친구 신청 보내요", 240, True),
             ("temp-40", "これからもよろしくね！", 900, True)]
    for i, (uid, msg, minutes, viewed) in enumerate(freqs, 1):
        s.append("INSERT INTO friendships (id, requester_id, addressee_id, status, pair_key, message, created_at, viewed_at) "
                 "SELECT %s, %s, @me, 'PENDING', %s, %s, NOW() - INTERVAL %d MINUTE, %s FROM DUAL WHERE @me IS NOT NULL;"
                 % (q("temp-fq%d" % i), q(uid), pair("@me", uid), q(msg), minutes,
                    "NOW() - INTERVAL %d MINUTE" % (minutes // 2) if viewed else "NULL"))
    s.append("SELECT IF(@me IS NULL, 'LINE 목 계정 없음 — 대화방·친구 칸은 건너뜀', CONCAT('관계 연결: ', @me));")
    return "\n".join(s)


def users_sql(users, sdate):
    s = []
    for u in users:
        uid = u["id"]
        s.append("INSERT INTO users (id, provider, provider_uid, nickname, birth_year, gender, country, created_at, last_seen_at) "
                 "VALUES (%s,'GOOGLE',%s,%s,%d,%s,%s, NOW() - INTERVAL 30 DAY, %s);"
                 % (q(uid), q(uid), q(u["nickname"]), u["birth_year"], q(u["gender"]), q(u["country"]), ago(u["seen"])))
        s.append("INSERT INTO user_profiles (user_id, photo_key, main_photo_key, intro, updated_at) VALUES (%s,%s,%s,%s, NOW());"
                 % (q(uid), q("%s/%02d_face.jpg" % (KEY_DIR, u["n"])), q("%s/%02d_main.jpg" % (KEY_DIR, u["n"])), q(u["intro"])))
        for code in u["interests"]:
            s.append("INSERT INTO user_interests (user_id, code) VALUES (%s,%s);" % (q(uid), q(code)))
        if u["region"]:
            s.append("INSERT INTO user_regions (user_id, code) VALUES (%s,%s);" % (q(uid), q(u["region"])))
        pid = "%s-p" % uid
        # 공유 시각을 사람마다 조금씩 어긋나게 — 가든 순서가 한 줄로 몰리지 않게
        s.append("INSERT INTO posts (id, user_id, session_date, published_at, content_updated_at) "
                 "VALUES (%s,%s,%s, NOW() - INTERVAL %d MINUTE, NOW() - INTERVAL %d MINUTE);"
                 % (q(pid), q(uid), q(sdate), u["n"] * 3, u["n"] * 3))
        for i in range(u["photos"]):
            s.append("INSERT INTO post_photos (id, post_id, user_id, storage_key, order_idx) VALUES (%s,%s,%s,%s,%d);"
                     % (q("%s%d" % (pid, i + 1)), q(pid), q(uid), q("%s/%02d_post%d.jpg" % (KEY_DIR, u["n"], i + 1)), i))
        s.append("UPDATE posts SET main_photo_id = %s WHERE id = %s;" % (q(pid + "1"), q(pid)))
    return "\n".join(s)


def run_sql(text):
    p = subprocess.run([MYSQL, *DB, "-N", "-B"], input=text, capture_output=True, text=True, encoding="utf-8")
    if p.returncode != 0:
        sys.exit("SQL 실패:\n" + p.stderr)
    return p.stdout.strip()


def make_photos(users):
    OUT.mkdir(parents=True, exist_ok=True)
    made = 0
    for u in users:
        rnd = random.Random(1000 + u["n"])
        jobs = [("%02d_face.jpg" % u["n"], lambda: face_photo(rnd, u)),
                ("%02d_main.jpg" % u["n"], lambda: main_photo(rnd, u))]
        jobs += [("%02d_post%d.jpg" % (u["n"], i + 1), (lambda i=i: post_photo(rnd, u, i, u["photos"])))
                 for i in range(u["photos"])]
        # 한 사람 몫이 다 있으면 통째로 건너뛴다. 일부만 있으면 그 사람 것을 전부 다시 그린다 —
        # 사람마다 시드가 따로라 다른 사람 그림은 안 바뀌지만, 한 사람 안에서는 그리는 순서가 곧 결과다.
        if all((OUT / name).exists() for name, _ in jobs):
            continue
        for name, fn in jobs:
            fn().save(OUT / name, quality=88)
            made += 1
    return made


def main():
    if "--clean" in sys.argv:
        run_sql(CLEAN)
        print("temp- 유저와 관계를 모두 지웠다(사진 파일은 남겨 둠: %s)" % OUT)
        return
    users = build_users()
    made = make_photos(users)
    sdate = session_date()
    out = run_sql(CLEAN + users_sql(users, sdate) + "\n" + ties_sql())
    print("사진 %d장 새로 만듦 → %s" % (made, OUT))
    print("유저 %d명 · 영업일 %s 포스트 공유(KST 18:05 배치에 지워진다 — 그 뒤엔 다시 돌릴 것)" % (len(users), sdate))
    print(out)


if __name__ == "__main__":
    main()
