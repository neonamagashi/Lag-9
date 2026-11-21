import math
import random
import sys

from PIL import Image, ImageDraw

D = sys.argv[1] if len(sys.argv) > 1 else "assets/limbo"
OUTLINE, SHADE, SKIN, MOUTH, BLUSH = (47, 37, 34), (185, 179, 161), (250, 243, 232), (231, 213, 198), (209, 157, 167)
TONES = [((241, 214, 190), (212, 178, 152)), ((224, 178, 138), (188, 142, 104)), ((196, 140, 98), (160, 106, 72)),
         ((152, 100, 68), (120, 76, 52)), ((112, 72, 50), (86, 54, 38)), ((84, 56, 42), (64, 42, 32))]
CLOTH = [((156, 140, 112), (124, 110, 88)), ((122, 116, 108), (96, 90, 84)), ((170, 160, 142), (138, 128, 112)),
         ((132, 112, 96), (104, 88, 74)), ((146, 146, 136), (116, 116, 108)), ((118, 104, 90), (92, 80, 70))]
VARIANTS = [(0, 0, "loin"), (3, 1, "tunic"), (5, 2, "loin"), (2, 3, "tunic"), (4, 4, "loin"), (1, 5, "tunic")]


def vagrant(src, tone, cloth, style):
    img = src.copy()
    px = img.load()
    skin, shade = tone
    c, cs = cloth
    for fy in range(0, img.height, 32):
        for fx in range(0, img.width, 32):
            for y in range(32):
                for x in range(32):
                    p = px[fx + x, fy + y]
                    if p[3] == 0:
                        continue
                    rgb = p[:3]
                    side = fy // 32 in (1, 2, 3)
                    loin = (y in (27, 28) and 12 <= x <= 19) or (y == 26 and 12 <= x <= (16 if side else 19))
                    covered = (style == "loin" and loin) or (style == "tunic" and 19 <= y <= 27 and 12 <= x <= 19)
                    flap = style == "loin" and y in (28, 29) and x in (15, 16)
                    if (covered and rgb in (SKIN, SHADE)) or (flap and rgb == OUTLINE):
                        px[fx + x, fy + y] = (c if rgb == SKIN else cs) + (255,)
                    elif rgb == SKIN:
                        px[fx + x, fy + y] = skin + (255,)
                    elif rgb == SHADE:
                        px[fx + x, fy + y] = shade + (255,)
                    elif rgb == MOUTH:
                        px[fx + x, fy + y] = tuple(int(v * 0.92) for v in skin) + (255,)
                    elif rgb == BLUSH:
                        px[fx + x, fy + y] = tuple(int(a * 0.8 + b * 0.2) for a, b in zip(skin, BLUSH)) + (255,)
    return img


def warden(frames=4):
    w, h = 56, 104
    out = Image.new("RGBA", (w * frames, h))
    rnd = random.Random(3)
    for f in range(frames):
        img = Image.new("RGBA", (w, h))
        d = ImageDraw.Draw(img)
        cx = w // 2
        sway = math.sin(f / frames * math.tau) * 2.0
        body = [(cx - 7, 10), (cx + 7, 10), (cx + 12, 24), (cx + 15, 50), (cx + 18 + sway, 80), (cx + 22 + sway, 100),
                (cx - 22 + sway, 100), (cx - 18 + sway, 80), (cx - 15, 50), (cx - 12, 24)]
        d.polygon(body, fill=(14, 12, 18, 255))
        cape = [(cx - 12, 22), (cx - 24 + sway, 60), (cx - 27 + sway * 1.5, 100), (cx - 14, 100), (cx - 10, 40)]
        d.polygon(cape, fill=(10, 8, 14, 255))
        cape2 = [(cx + 12, 22), (cx + 24 + sway, 60), (cx + 27 + sway * 1.5, 100), (cx + 14, 100), (cx + 10, 40)]
        d.polygon(cape2, fill=(10, 8, 14, 255))
        d.polygon([(cx - 9, 4), (cx, 0), (cx + 9, 4), (cx + 11, 18), (cx - 11, 18)], fill=(18, 15, 24, 255))
        d.polygon([(cx - 6, 8), (cx + 6, 8), (cx + 7, 18), (cx - 7, 18)], fill=(4, 3, 6, 255))
        for ex in (cx - 3, cx + 2):
            d.rectangle((ex, 13, ex + 1, 13), fill=(200, 190, 255, 255))
        for k in range(4):
            x = cx - 6 + k * 4
            d.line((x, 30 + k % 2 * 6, x + sway * 0.5, 96), fill=(26, 22, 34, 255))
        d.line((cx - 15, 50, cx - 22 + sway, 99), fill=(34, 30, 44, 255))
        d.line((cx + 15, 50, cx + 22 + sway, 99), fill=(34, 30, 44, 255))
        px = img.load()
        for x in range(w):
            for y in range(88, h):
                if px[x, y][3]:
                    fade = (y - 88) / (h - 88)
                    px[x, y] = (px[x, y][0], px[x, y][1], px[x, y][2], int(255 * (1.0 - fade * 0.85)))
        out.paste(img, (f * w, 0))
    return out


W_W, W_H, W_FLOOR, W_FRAMES = 280, 200, 176, 8
INK, DEEP, BASE, FOLD, RIM = (6, 5, 9), (11, 9, 15), (16, 13, 22), (28, 24, 38), (46, 40, 62)


def _blob(cx, cy, rx, ry, t, wind, n=120, ragged=1.0):
    pts = []
    for i in range(n):
        a = i / n * math.tau
        r = 1.0 + 0.05 * math.sin(5 * a - t * 2) + 0.035 * math.sin(11 * a + t * 3) * ragged
        lee = max(0.0, math.cos(a))  # wind blows toward +x
        r += 0.16 * lee * (0.6 + 0.4 * math.sin(t + a * 3))
        pts.append((cx + math.cos(a) * rx * r, cy + math.sin(a) * ry * r))
    return pts


def warden2():
    body_sheet = Image.new("RGBA", (W_W * W_FRAMES, W_H))
    pool_sheet = Image.new("RGBA", (W_W * W_FRAMES, W_H))
    rnd = random.Random(7)
    tips = [(rnd.uniform(-0.9, 0.9), rnd.uniform(10, 26), rnd.uniform(0, math.tau)) for _ in range(14)]
    for f in range(W_FRAMES):
        t = f / W_FRAMES * math.tau
        cx = W_W // 2
        bob = round(math.sin(t) * 2.0)
        # ---------- floor train ----------
        pool = Image.new("RGBA", (W_W, W_H))
        d = ImageDraw.Draw(pool)
        pcx, pcy = cx + 6, W_FLOOR - 14
        d.polygon(_blob(pcx, pcy, 118, 24, t, 1.0), fill=RIM + (255,))
        d.polygon(_blob(pcx, pcy, 116, 22.5, t, 1.0), fill=DEEP + (255,))
        # tattered streamers on the lee side, rippling in the wind
        for (a0, ln, ph) in tips:
            a = a0 * 0.9
            bx = pcx + math.cos(a) * 112
            by = pcy + math.sin(a) * 21
            sway = math.sin(t * 2 + ph) * 5
            tip = (bx + ln + abs(sway) * 0.5, by + sway * 0.35)
            d.polygon([(bx, by - 3), tip, (bx - 2, by + 3)], fill=DEEP + (255,))
            d.line([(bx, by - 3), tip], fill=RIM + (255,))
        # radial folds across the cloth
        for k in range(18):
            a = k / 18 * math.tau + math.sin(t + k) * 0.05
            r0, r1 = 0.32, 0.9 + 0.06 * math.sin(t * 2 + k)
            p0 = (pcx + math.cos(a) * 116 * r0, pcy + math.sin(a) * 22 * r0)
            p1 = (pcx + math.cos(a) * 116 * r1, pcy + math.sin(a) * 22 * r1)
            d.line([p0, p1], fill=FOLD + (255,))
        # travelling ripple rings
        for k in range(2):
            ph = ((t / math.tau) + k * 0.5) % 1.0
            pts = _blob(pcx, pcy, 40 + 70 * ph, 8 + 13 * ph, t, 1.0, 90, 0.3)
            for i in range(0, len(pts) - 1, 2):
                if (i // 2) % 3:
                    d.line([pts[i], pts[i + 1]], fill=FOLD + (255,))
        pool_sheet.paste(pool, (f * W_W, 0))
        # ---------- body ----------
        img = Image.new("RGBA", (W_W, W_H))
        d = ImageDraw.Draw(img)
        top = 10 + bob
        sh = top + 34
        fl = W_FLOOR - 8
        ROBE, ROBE_F, CLOAK_IN = (24, 20, 32), (40, 34, 54), (8, 7, 11)
        wv = lambda k: math.sin(t * 2 + k) * 3

        y0 = top + 18

        def edge(side, v):
            wind = 1.0 if side > 0 else 0.35
            # starts at the hood, wraps out over the shoulders, then billows to the floor
            shoulder = min(1.0, v / 0.14)
            x = 14 + 13 * (1 - (1 - shoulder) ** 2) + 8 * v + 76 * v ** 3 * (1.0 + 0.18 * wind)
            x += math.sin(v * 9 - t * 2 + side) * 3.5 * v * (0.5 + wind)
            return cx + side * x

        for side in (-1, 1):
            n = 40
            outer = [(edge(side, i / n), y0 + (fl - y0) * i / n) for i in range(n + 1)]
            # scalloped, lifting hem on the lee side
            hem = []
            for i in range(9):
                hx = edge(side, 1.0) + (cx - edge(side, 1.0)) * i / 9.0
                lift = (math.sin(t * 2 + i * 1.3) * 2.5 + 3) * (1.0 if side > 0 else 0.4) * (1 - i / 9.0)
                hem.append((hx, fl - lift))
            poly = [(cx, y0)] + outer + hem + [(cx, fl)]
            d.polygon(poly, fill=CLOAK_IN + (255,))
            d.line(outer, fill=RIM + (255,))
            # billowing folds following the bell
            for k in range(1, 6):
                fk = k / 6.0
                fold = []
                for i in range(n + 1):
                    v = i / n
                    if v < 0.25:
                        continue
                    ex = edge(side, v)
                    fold.append((cx + (ex - cx) * (0.35 + 0.6 * fk), y0 + (fl - y0) * v))
                d.line(fold, fill=FOLD + (255,))
        # robe in front: shoulders, sleeves, long column into the floor
        robe = [(cx - 12, sh - 6), (cx + 12, sh - 6), (cx + 18, sh + 4), (cx + 20, sh + 40), (cx + 18, sh + 60),
                (cx + 22 + wv(1) * 0.5, fl - 2), (cx - 22 + wv(1) * 0.5, fl - 2), (cx - 18, sh + 60), (cx - 20, sh + 40), (cx - 18, sh + 4)]
        d.polygon(robe, fill=ROBE + (255,))
        d.line(robe[1:6], fill=ROBE_F + (255,))
        # sleeves meeting at the front, hands hidden
        d.polygon([(cx - 18, sh + 8), (cx - 3, sh + 34), (cx + 3, sh + 34), (cx + 18, sh + 8), (cx + 16, sh + 40), (cx - 16, sh + 40)], fill=BASE + (255,))
        d.line([(cx - 18, sh + 8), (cx - 3, sh + 34)], fill=ROBE_F + (255,))
        d.line([(cx + 18, sh + 8), (cx + 3, sh + 34)], fill=ROBE_F + (255,))
        for k in range(5):
            x = cx - 12 + k * 6
            d.line([(x, sh + 44), (x + (k - 2) * 2 + wv(k) * 0.5, fl - 4)], fill=ROBE_F + (255,))
        # mantle over the shoulders
        d.polygon([(cx - 15, sh - 8), (cx + 15, sh - 8), (cx + 20, sh + 7), (cx + 7, sh + 13), (cx - 7, sh + 13), (cx - 20, sh + 7)], fill=BASE + (255,))
        d.line([(cx - 20, sh + 7), (cx - 7, sh + 13), (cx + 7, sh + 13), (cx + 20, sh + 7)], fill=FOLD + (255,))
        # deep hood
        hood = [(cx - 15, sh - 4), (cx - 15, top + 14), (cx - 8, top + 2), (cx + 1, top - 3), (cx + 9, top + 3), (cx + 15, top + 14), (cx + 15, sh - 4)]
        d.polygon(hood, fill=BASE + (255,))
        d.line(hood[1:6], fill=RIM + (255,))
        d.polygon([(cx - 9, top + 10), (cx + 9, top + 10), (cx + 10, top + 30), (cx - 10, top + 30)], fill=INK + (255,))
        for ex in (cx - 5, cx + 3):
            d.rectangle((ex, top + 18, ex + 1, top + 18), fill=(205, 195, 255, 255))
        img.putalpha(img.getchannel("A"))
        body_sheet.paste(img, (f * W_W, 0))
    return body_sheet, pool_sheet


src = {n: Image.open(f"{D}/template/{n}.png").convert("RGBA") for n in ("idle", "walk")}
for i, (t, c, style) in enumerate(VARIANTS):
    for n in src:
        vagrant(src[n], TONES[t], CLOTH[c], style).save(f"{D}/vagrant_{i}_{n}.png")
b, p = warden2()
b.save(f"{D}/warden.png")
p.save(f"{D}/warden_train.png")
print("ok")
