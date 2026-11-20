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
                    covered = (style == "loin" and 25 <= y <= 27) or (style == "tunic" and 19 <= y <= 27 and 12 <= x <= 19)
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


src = {n: Image.open(f"{D}/template/{n}.png").convert("RGBA") for n in ("idle", "walk")}
for i, (t, c, style) in enumerate(VARIANTS):
    for n in src:
        vagrant(src[n], TONES[t], CLOTH[c], style).save(f"{D}/vagrant_{i}_{n}.png")
warden().save(f"{D}/warden.png")
print("ok")
