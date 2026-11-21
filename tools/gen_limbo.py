import math
import random
import sys

from PIL import Image, ImageDraw

D = sys.argv[1] if len(sys.argv) > 1 else "assets/limbo"
OUTLINE, SHADE, SKIN, MOUTH, BLUSH = (47, 37, 34), (185, 179, 161), (250, 243, 232), (231, 213, 198), (209, 157, 167)
TONES = [((241, 214, 190), (212, 178, 152)), ((224, 178, 138), (188, 142, 104)), ((196, 140, 98), (160, 106, 72)),
         ((152, 100, 68), (120, 76, 52)), ((112, 72, 50), (86, 54, 38)), ((84, 56, 42), (64, 42, 32))]
CLOTH = [((156, 140, 112), (124, 110, 88)), ((122, 116, 108), (96, 90, 84)), ((170, 160, 142), (138, 128, 112)),
         ((132, 112, 96), (104, 88, 74)), ((146, 146, 136), (116, 116, 108)), ((118, 104, 90), (92, 80, 70)),
         ((84, 78, 76), (64, 58, 58)), ((150, 98, 80), (118, 74, 60)), ((204, 198, 184), (170, 164, 150)),
         ((108, 116, 130), (84, 90, 104)), ((114, 126, 104), (88, 98, 80)), ((116, 92, 108), (90, 70, 84))]
VARIANTS = [(0, 0, "loin"), (3, 1, "tunic"), (5, 2, "loin"), (2, 3, "tunic"), (4, 4, "loin"), (1, 5, "tunic"),
            (2, 6, "robe"), (0, 7, "robe"), (4, 8, "robe"), (5, 9, "tunic"), (1, 10, "robe"), (3, 11, "robe"),
            (4, 7, "tunic"), (0, 9, "loin")]


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
                    robe = 19 <= y <= 30 and 12 <= x <= 19
                    covered = (style == "loin" and loin) or (style == "tunic" and 19 <= y <= 27 and 12 <= x <= 19) or (style == "robe" and robe)
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
    if style == "robe":
        for fy in range(0, img.height, 32):
            for fx in range(0, img.width, 32):
                for y in range(27, 31):
                    row = [x for x in range(11, 21) if px[fx + x, fy + y][3]]
                    if not row:
                        continue
                    for x in range(min(row), max(row) + 1):
                        edge = x in (min(row), max(row))
                        px[fx + x, fy + y] = (OUTLINE if edge else (cs if y == 30 else c)) + (255,)
    return img


def sit(src):
    """Seated, legs crossed: the body drops 4px onto a lap drawn in the hip colour."""
    out = Image.new("RGBA", (128, 32))
    for f in range(4):
        fr = src.crop((f * 32, 0, f * 32 + 32, 32))
        hip = fr.getpixel((15, 26))
        body = fr.crop((0, 0, 32, 27))
        frame = Image.new("RGBA", (32, 32))
        frame.paste(body, (0, 4), body)
        px = frame.load()
        for y, (a, b) in {29: (9, 22), 30: (9, 22), 31: (10, 21)}.items():
            for x in range(a, b + 1):
                edge = x in (a, b) or y == 31
                px[x, y] = OUTLINE + (255,) if edge else hip[:3] + (255,)
        out.paste(frame, (f * 32, 0))
    return out


def bubble(kind):
    """Thought bubble with a '?' or a plate of pancakes."""
    O, W = (60, 50, 80, 255), (255, 255, 255, 255)
    im = Image.new("RGBA", (40, 32))
    d = ImageDraw.Draw(im)
    d.ellipse((4, 0, 39, 23), fill=W, outline=O)
    d.ellipse((5, 23, 9, 27), fill=W, outline=O)
    d.ellipse((1, 28, 3, 30), fill=W, outline=O)
    if kind == "q":
        P = (110, 60, 190, 255)
        for x, y in [(19, 5), (20, 4), (21, 4), (22, 4), (23, 5), (24, 6), (24, 7), (23, 8), (22, 9), (21, 10), (21, 11), (21, 12), (21, 15), (21, 16)]:
            d.rectangle((x, y, x, y), fill=P)
            d.rectangle((x + 1, y, x + 1, y), fill=P)
    else:
        PL, PLD = (232, 232, 240, 255), (180, 180, 196, 255)
        CAKE, CAKED = (224, 168, 88, 255), (166, 108, 48, 255)
        SYR, BUT = (128, 58, 20, 255), (252, 232, 120, 255)
        d.ellipse((10, 14, 33, 20), fill=PL, outline=PLD)
        for i in range(3):
            y = 13 - i * 3
            d.ellipse((13, y - 2, 30, y + 3), fill=CAKE, outline=CAKED)
        d.ellipse((15, 5, 28, 9), fill=SYR)
        for x, ln in ((15, 5), (19, 3), (26, 6), (28, 3)):
            d.line((x, 8, x, 8 + ln), fill=SYR)
        d.rectangle((20, 5, 23, 7), fill=BUT)
    return im


MO, MD, MM, ML, MH = (92, 88, 104, 255), (160, 156, 172, 255), (200, 197, 210, 255), (228, 226, 234, 255), (246, 245, 250, 255)


def _jag(rnd, x0, x1, y, depth):
    pts = []
    for x in range(x0, x1 + 1, 2):
        pts.append((x, y + rnd.randint(0, depth)))
    return pts


def column(h, seed):
    """A fluted marble column, snapped off at the top."""
    rnd = random.Random(seed)
    w = 26
    im = Image.new("RGBA", (w, h + 4))
    d = ImageDraw.Draw(im)
    base = h - 5
    top = _jag(rnd, 5, 20, 4, 6)
    shaft = [(5, base)] + [(5, top[0][1])] + top + [(20, top[-1][1]), (20, base)]
    d.polygon(shaft, fill=MM, outline=MO)
    for fx in (8, 11, 14, 17):
        d.line([(fx, max(p[1] for p in top) + 1), (fx, base - 1)], fill=MD)
    d.line([(6, top[0][1] + 1), (6, base - 1)], fill=ML)
    d.rectangle((2, base, 23, base + 4), fill=ML, outline=MO)
    d.line((3, base + 3, 22, base + 3), fill=MD)
    for c in range(rnd.randint(1, 2)):
        cx = rnd.randint(8, 16)
        cy = rnd.randint(top[0][1] + 6, base - 6)
        d.line([(cx, cy), (cx + rnd.choice((-2, 2)), cy + 3), (cx + rnd.choice((-1, 1)), cy + 6)], fill=MO)
    return im


def drum():
    """A toppled column section lying on its side."""
    im = Image.new("RGBA", (34, 18))
    d = ImageDraw.Draw(im)
    d.rectangle((6, 3, 30, 15), fill=MM, outline=MO)
    for y in (6, 9, 12):
        d.line((7, y, 29, y), fill=MD)
    d.line((7, 4, 29, 4), fill=ML)
    d.ellipse((1, 3, 11, 15), fill=ML, outline=MO)
    d.ellipse((4, 6, 8, 12), outline=MD)
    return im


def capital():
    """A fallen capital with its scrolls."""
    im = Image.new("RGBA", (34, 16))
    d = ImageDraw.Draw(im)
    d.rectangle((2, 3, 31, 8), fill=ML, outline=MO)
    d.polygon([(7, 8), (26, 8), (23, 14), (10, 14)], fill=MM, outline=MO)
    for cx in (5, 28):
        d.ellipse((cx - 4, 2, cx + 4, 10), fill=ML, outline=MO)
        d.ellipse((cx - 2, 4, cx + 2, 8), outline=MD)
    return im


def slab(w, h, seed):
    """A flat stone block: lit top, shaded front, a chipped corner."""
    rnd = random.Random(seed)
    im = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(im)
    top = h // 2
    d.rectangle((0, 0, w - 1, top), fill=ML, outline=MO)
    d.rectangle((0, top, w - 1, h - 1), fill=MD, outline=MO)
    d.line((1, 1, w - 2, 1), fill=MH)
    c = rnd.randint(3, 6)
    d.polygon([(w - 1 - c, 0), (w - 1, 0), (w - 1, c)], fill=(0, 0, 0, 0))
    d.line([(w - 1 - c, 0), (w - 1, c)], fill=MO)
    for k in range(rnd.randint(1, 3)):
        x = rnd.randint(4, w - 6)
        d.line([(x, top + 1), (x + 1, top + 3)], fill=MO)
    return im


def ruins():
    pieces = {"column_tall": column(56, 1), "column_mid": column(38, 2), "column_short": column(24, 3),
              "drum": drum(), "capital": capital(), "slab": slab(40, 16, 4), "slab_small": slab(26, 12, 5)}
    for k, im in pieces.items():
        im.save(f"{D}/ruin_{k}.png")


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
        im = vagrant(src[n], TONES[t], CLOTH[c], style)
        im.save(f"{D}/vagrant_{i}_{n}.png")
        if n == "idle":
            sit(im).save(f"{D}/vagrant_{i}_sit.png")
ruins()
bubble("q").save(f"{D}/think_q.png")
bubble("pancakes").save(f"{D}/think_pancakes.png")
b, p = warden2()
b.save(f"{D}/warden.png")
p.save(f"{D}/warden_train.png")
print("ok")
