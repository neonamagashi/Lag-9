import math
import os
import random
import sys

from PIL import Image, ImageDraw

OUT = sys.argv[1] if len(sys.argv) > 1 else "assets/env"
os.makedirs(OUT, exist_ok=True)
R = random.Random(4)

D0, D1, D2, D3, D4, D5 = (22, 18, 30), (34, 29, 44), (46, 40, 58), (58, 51, 72), (72, 64, 88), (90, 81, 108)
T1, T2, T3 = (55, 113, 114), (79, 164, 165), (150, 222, 210)
CREAM, BONE, BONE_S, BONE_D = (230, 209, 184), (214, 203, 180), (160, 150, 135), (110, 100, 92)
F1, F2, F3, F4 = (255, 236, 160), (255, 184, 86), (232, 110, 50), (160, 52, 40)
IRON, IRON_L = (40, 36, 44), (82, 76, 88)


def px(img, x, y, c):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), c + (255,) if len(c) == 3 else c)


def floor_tiles():
    img = Image.new("RGBA", (64, 64))
    for ty in range(4):
        for tx in range(4):
            ox, oy = tx * 16, ty * 16
            base = R.choice([D2, D2, D2, D3])
            for y in range(16):
                for x in range(16):
                    c = base
                    if R.random() < 0.08:
                        c = D3 if base == D2 else D4
                    if R.random() < 0.03:
                        c = D1
                    px(img, ox + x, oy + y, c)
            split = R.choice([None, "h", "v", "q"])
            for i in range(16):
                px(img, ox + i, oy + 15, D1)
                px(img, ox + 15, oy + i, D1)
                px(img, ox + i, oy, D4 if i < 15 else D1)
                px(img, ox, oy + i, D4 if i < 15 else D1)
            if split in ("h", "q"):
                for i in range(1, 15):
                    px(img, ox + i, oy + 7, D1)
                    px(img, ox + i, oy + 8, D4)
            if split in ("v", "q"):
                for i in range(1, 15):
                    px(img, ox + 7, oy + i, D1)
                    px(img, ox + 8, oy + i, D4)
            if R.random() < 0.35:
                x, y = ox + R.randint(3, 12), oy + R.randint(3, 12)
                for _ in range(R.randint(3, 7)):
                    px(img, x, y, D1)
                    x += R.choice([-1, 0, 1])
                    y += R.choice([0, 1])
            if tx == 3 and ty == 3:
                for (x, y) in [(5, 5), (6, 5), (7, 6), (8, 7), (9, 8), (10, 8), (6, 9), (7, 10), (8, 10)]:
                    px(img, ox + x, oy + y, T1)
                px(img, ox + 7, oy + 7, T2)
    img.save(os.path.join(OUT, "floor.png"))


def wall_face():
    w, h = 64, 40
    img = Image.new("RGBA", (w, h))
    for y in range(h):
        for x in range(w):
            px(img, x, y, D1)
    row_h = 8
    for r in range(1, 5):
        y0 = r * row_h
        off = 0 if r % 2 else 8
        x = -off
        while x < w:
            bw = R.choice([14, 16, 16, 18])
            col = R.choice([D2, D2, D3])
            for yy in range(y0 + 1, min(y0 + row_h, h)):
                for xx in range(max(x + 1, 0), min(x + bw, w)):
                    c = col
                    if yy == y0 + 1:
                        c = D4 if col == D3 else D3
                    if R.random() < 0.06:
                        c = D1
                    px(img, xx, yy, c)
            x += bw
    for x in range(w):
        for y in range(0, 6):
            px(img, x, y, D4 if y == 0 else (D3 if y < 3 else D2))
        px(img, x, 6, D0)
        px(img, x, 7, D0)
        px(img, x, h - 1, D0)
    for _ in range(5):
        x, y = R.randint(2, w - 3), R.randint(10, h - 6)
        for _ in range(R.randint(2, 5)):
            px(img, x, y, D0)
            y += 1
            x += R.choice([-1, 0, 1])
    img.save(os.path.join(OUT, "wall.png"))


def wall_top():
    img = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            c = D1 if R.random() > 0.1 else D0
            px(img, x, y, c)
    for i in range(16):
        px(img, i, 0, D3)
        px(img, 0, i, D2)
    img.save(os.path.join(OUT, "wall_top.png"))


def pillar():
    w, h = 24, 60
    img = Image.new("RGBA", (w, h))
    for y in range(h):
        for x in range(4, 20):
            t = (x - 4) / 15
            c = D4 if t < 0.25 else (D3 if t < 0.6 else D2)
            if (y // 7) % 2 == 0 and x in (9, 15):
                c = D1
            if y % 14 == 0:
                c = D1
            px(img, x, y, c)
        px(img, 4, y, D1)
        px(img, 19, y, D0)
    for y in range(0, 7):
        for x in range(1, 23):
            px(img, x, y, D5 if y == 0 else (D4 if y < 3 else D3))
        px(img, 0, y, D1)
        px(img, 23, y, D0)
    for y in range(h - 7, h):
        for x in range(1, 23):
            px(img, x, y, D4 if y == h - 7 else D2)
        px(img, 0, y, D1)
        px(img, 23, y, D0)
    for y in range(18, 30):
        px(img, 11, y, T1)
    px(img, 10, 21, T1)
    px(img, 12, 26, T1)
    px(img, 11, 23, T2)
    img.save(os.path.join(OUT, "pillar.png"))


def brazier():
    fw, fh, n = 16, 30, 6
    img = Image.new("RGBA", (fw * n, fh))
    for f in range(n):
        ox = f * fw
        for y in range(18, 30):
            px(img, ox + 7, y, IRON)
            px(img, ox + 8, y, IRON_L if y < 26 else IRON)
        for x in range(4, 12):
            px(img, ox + x, 29, IRON)
        for y in range(14, 19):
            for x in range(2 + (y - 14) // 2, 14 - (y - 14) // 2):
                px(img, ox + x, y, IRON_L if y == 14 else IRON)
        rr = random.Random(f * 7 + 1)
        cols = [F4, F3, F2, F1]
        for layer, c in enumerate(cols):
            width = 5 - layer
            top = 13 - (4 - layer) * 2 - rr.randint(0, 2)
            for y in range(top, 14):
                span = max(1, int(width * (y - top + 1) / (14 - top + 1)))
                cx = 8 + rr.choice([-1, 0, 0, 1]) * (1 if y < 10 else 0)
                for x in range(cx - span, cx + span):
                    px(img, ox + x, y, c)
        if f % 2 == 0:
            px(img, ox + 8 + rr.choice([-2, 2]), rr.randint(1, 4), F2)
    img.save(os.path.join(OUT, "brazier.png"))


def rune_circle():
    w, h = 112, 64
    img = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(img)
    cx, cy = w / 2, h / 2
    for r, c in [(54, T1), (50, T1), (34, T1)]:
        d.ellipse((cx - r, cy - r * 0.55, cx + r, cy + r * 0.55), outline=c + (150,))
    for i in range(8):
        a = i / 8 * math.tau
        x, y = cx + math.cos(a) * 42, cy + math.sin(a) * 42 * 0.55
        d.rectangle((x - 1, y - 1, x + 1, y + 1), fill=T2 + (190,))
        x2, y2 = cx + math.cos(a + 0.4) * 34, cy + math.sin(a + 0.4) * 34 * 0.55
        d.line((x, y, x2, y2), fill=T1 + (130,))
    for i in range(3):
        a = i / 3 * math.tau + 0.3
        pts = [(cx + math.cos(a + k * math.tau / 3) * 30, cy + math.sin(a + k * math.tau / 3) * 30 * 0.55) for k in range(3)]
    img.save(os.path.join(OUT, "rune_circle.png"))


def bones():
    img = Image.new("RGBA", (48, 16))
    d = ImageDraw.Draw(img)
    d.ellipse((2, 4, 10, 11), fill=BONE + (255,))
    px(img, 4, 7, D0)
    px(img, 7, 7, D0)
    for x in range(4, 9):
        px(img, x, 11, BONE_S)
    d.line((12, 12, 22, 8), fill=BONE + (255,))
    d.line((12, 13, 22, 9), fill=BONE_S + (255,))
    for (x, y) in [(11, 11), (11, 13), (23, 7), (23, 9)]:
        d.rectangle((x - 1, y - 1, x, y), fill=BONE + (255,))
    for i in range(4):
        x = 28 + i * 4
        d.rectangle((x, 6 + (i % 2), x + 2, 12), fill=(BONE if i % 2 else BONE_S) + (255,))
    d.ellipse((40, 5, 46, 12), fill=BONE_S + (255,))
    px(img, 42, 8, D0)
    img.save(os.path.join(OUT, "bones.png"))


def rubble():
    img = Image.new("RGBA", (32, 12))
    for _ in range(9):
        x, y = R.randint(1, 26), R.randint(3, 8)
        w, h = R.randint(2, 5), R.randint(2, 3)
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                px(img, xx, yy, D4 if yy == y else D3)
        for xx in range(x, x + w):
            px(img, xx, y + h, D1)
    img.save(os.path.join(OUT, "rubble.png"))


def banner():
    w, h = 14, 30
    img = Image.new("RGBA", (w, h))
    for y in range(h - 4):
        for x in range(1, 13):
            c = (92, 34, 52) if 3 < x < 10 else (70, 26, 42)
            px(img, x, y, c)
    for i, x in enumerate(range(1, 13)):
        for y in range(h - 4, h - 4 + (2 if i % 3 == 1 else 4 - (i % 2) * 2)):
            px(img, x, y, (70, 26, 42))
    for y in range(9, 19):
        px(img, 6, y, T2)
    for i in range(4):
        px(img, 5 - i, 12 - i, T2)
        px(img, 7 + i, 12 - i, T2)
    for x in range(0, 14):
        px(img, x, 0, IRON_L)
    img.save(os.path.join(OUT, "banner.png"))


def chains():
    img = Image.new("RGBA", (6, 28))
    for y in range(0, 28, 4):
        px(img, 2, y, IRON_L)
        px(img, 3, y + 1, IRON_L)
        px(img, 2, y + 2, IRON)
        px(img, 3, y + 3, IRON)
    img.save(os.path.join(OUT, "chains.png"))


def pickups():
    img = Image.new("RGBA", (40, 12))
    for f in range(4):
        ox = f * 8
        r = 2.5 + (0.5 if f in (1, 2) else 0)
        for y in range(8):
            for x in range(8):
                d = math.hypot(x - 3.5, y - 5.5)
                if d < r:
                    px(img, ox + x, y + 2, T3 if d < 1.2 else T2 if d < r - 0.8 else T1)
    bx = 32
    for y in range(4, 12):
        for x in range(1, 7):
            px(img, bx + x, y, (150, 90, 40) if y > 5 else (120, 70, 30))
    for y in range(1, 4):
        px(img, bx + 3, y, (120, 70, 30))
        px(img, bx + 4, y, (120, 70, 30))
    px(img, bx + 3, 0, CREAM)
    px(img, bx + 4, 0, CREAM)
    for y in range(7, 10):
        for x in range(2, 6):
            px(img, bx + x, y, CREAM)
    img.save(os.path.join(OUT, "pickups.png"))


def light():
    s = 128
    img = Image.new("RGBA", (s, s))
    for y in range(s):
        for x in range(s):
            d = math.hypot(x - s / 2 + 0.5, y - s / 2 + 0.5) / (s / 2)
            a = max(0.0, 1.0 - d) ** 1.6
            img.putpixel((x, y), (255, 255, 255, int(a * 255)))
    img.save(os.path.join(OUT, "light.png"))


def orb():
    img = Image.new("RGBA", (36, 9))
    for f in range(4):
        ox = f * 9
        for y in range(9):
            for x in range(9):
                d = math.hypot(x - 4, y - 4)
                r = 3.6 + (0.4 if f % 2 else 0)
                if d < r:
                    c = T3 if d < 1.4 else (T2 if d < r - 1 else T1)
                    px(img, ox + x, y, c)
    img.save(os.path.join(OUT, "orb.png"))


for fn in [floor_tiles, wall_face, wall_top, pillar, brazier, rune_circle, bones, rubble, banner, chains, pickups, light, orb]:
    fn()
print(sorted(os.listdir(OUT)))
