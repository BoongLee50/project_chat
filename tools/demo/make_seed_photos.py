"""데모 SQL(demo_talk.sql · demo_friend.sql)이 쓰는 프로필 사진 3장을 만든다.

`server/server/uploads/seed/p1.png · p2.jpg · p3.jpg` — 저장소에 없는 폴더라 기기마다 한 번 만들어야 한다.
사진 대신 **밤하늘 그라데이션 + 달**이다(데모 칸이 비지 않게 하는 것이 목적, UI 리소스가 아니다).

    python tools/demo/make_seed_photos.py
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "server" / "server" / "uploads" / "seed"

# (파일, 위 색, 아래 색, 달 위치)
PHOTOS = [
    ("p1.png", (40, 30, 90), (220, 120, 150), (0.70, 0.28)),
    ("p2.jpg", (10, 30, 70), (60, 140, 190), (0.30, 0.25)),
    ("p3.jpg", (30, 20, 50), (240, 170, 90), (0.55, 0.35)),
]
SIZE = 900


def make(top, bottom, moon):
    img = Image.new("RGB", (SIZE, SIZE))
    px = img.load()
    for y in range(SIZE):
        t = y / (SIZE - 1)
        c = tuple(round(a + (b - a) * t) for a, b in zip(top, bottom))
        for x in range(SIZE):
            px[x, y] = c
    glow = Image.new("L", (SIZE, SIZE), 0)
    cx, cy = moon[0] * SIZE, moon[1] * SIZE
    ImageDraw.Draw(glow).ellipse((cx - 140, cy - 140, cx + 140, cy + 140), fill=110)
    glow = glow.filter(ImageFilter.GaussianBlur(60))
    img = Image.composite(Image.new("RGB", img.size, (255, 244, 210)), img, glow)
    ImageDraw.Draw(img).ellipse((cx - 80, cy - 80, cx + 80, cy + 80), fill=(255, 246, 220))
    return img


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, top, bottom, moon in PHOTOS:
        make(top, bottom, moon).save(OUT / name)
        print("wrote", OUT / name)


if __name__ == "__main__":
    main()
