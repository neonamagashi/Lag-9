import math
import os
import sys

from PIL import Image, ImageDraw

OUT = sys.argv[1] if len(sys.argv) > 1 else "assets/vfx"
RUNES = [
    [((0, 0), (0, 1)), ((0, 0.2), (0.5, 0)), ((0, 0.45), (0.5, 0.25))],
    [((0, 0), (0, 1)), ((0, 0), (0.5, 0.35)), ((0.5, 0.35), (0.5, 1))],
    [((0, 0), (0, 1)), ((0, 0.15), (0.45, 0.35)), ((0.45, 0.35), (0, 0.55))],
    [((0.25, 0), (0.25, 1)), ((0.25, 0.4), (0, 0)), ((0.25, 0.4), (0.5, 0))],
    [((0, 0), (0, 1)), ((0.5, 0), (0.5, 1)), ((0, 0.25), (0.5, 0.55))],
    [((0.25, 0), (0.25, 1)), ((0, 0.3), (0.5, 0.6))],
    [((0, 0.5), (0.25, 0)), ((0.25, 0), (0.5, 0.5)), ((0, 0.5), (0.25, 1)), ((0.25, 1), (0.5, 0.5))],
    [((0, 0), (0, 1)), ((0, 0), (0.5, 0.3)), ((0.5, 0.3), (0, 0.55)), ((0, 0.55), (0.5, 1))],
    [((0.25, 0), (0.25, 1)), ((0.25, 0), (0, 0.3)), ((0.25, 0), (0.5, 0.3))],
    [((0, 0), (0.5, 1)), ((0.5, 0), (0, 1))],
    [((0, 0), (0, 1)), ((0, 0), (0.45, 0.25)), ((0.45, 0.25), (0, 0.5)), ((0, 0.5), (0.45, 0.75)), ((0.45, 0.75), (0, 1))],
    [((0.25, 0), (0.25, 1)), ((0.25, 0.6), (0, 1)), ((0.25, 0.6), (0.5, 1))],
]


def ring(d, c, r, w, a=255):
    d.ellipse((c - r, c - r, c + r, c + r), outline=(255, 255, 255, a), width=w)


def outer(size=512):
    img = Image.new("RGBA", (size, size))
    d = ImageDraw.Draw(img)
    c = size / 2
    ring(d, c, c - 4, 3)
    ring(d, c, c - 12, 1, 200)
    ring(d, c, c - 46, 2)
    ring(d, c, c - 52, 1, 160)
    n = 24
    for i in range(n):
        a = i / n * math.tau
        rune = RUNES[i % len(RUNES)]
        rr = c - 29
        cx, cy = c + math.cos(a) * rr, c + math.sin(a) * rr
        rot = a + math.pi / 2
        for (x0, y0), (x1, y1) in rune:
            pts = []
            for x, y in ((x0, y0), (x1, y1)):
                lx, ly = (x - 0.25) * 22, (y - 0.5) * 22
                pts.append((cx + lx * math.cos(rot) - ly * math.sin(rot), cy + lx * math.sin(rot) + ly * math.cos(rot)))
            d.line(pts, fill=(255, 255, 255, 235), width=3)
    for i in range(n):
        a = (i + 0.5) / n * math.tau
        p0 = (c + math.cos(a) * (c - 12), c + math.sin(a) * (c - 12))
        p1 = (c + math.cos(a) * (c - 20), c + math.sin(a) * (c - 20))
        d.line((p0, p1), fill=(255, 255, 255, 200), width=2)
    return img


def mid(size=256):
    img = Image.new("RGBA", (size, size))
    d = ImageDraw.Draw(img)
    c = size / 2
    ring(d, c, c - 3, 3)
    ring(d, c, c - 10, 1, 180)
    pts = [(c + math.cos(i / 7 * math.tau - math.pi / 2) * (c - 10), c + math.sin(i / 7 * math.tau - math.pi / 2) * (c - 10)) for i in range(7)]
    for i in range(7):
        d.line((pts[i], pts[(i + 3) % 7]), fill=(255, 255, 255, 220), width=2)
    ring(d, c, c * 0.42, 2, 220)
    for i in range(7):
        a = i / 7 * math.tau - math.pi / 2 + math.pi / 7
        x, y = c + math.cos(a) * c * 0.6, c + math.sin(a) * c * 0.6
        d.ellipse((x - 4, y - 4, x + 4, y + 4), fill=(255, 255, 255, 230))
    return img


os.makedirs(OUT, exist_ok=True)
outer().save(os.path.join(OUT, "sigil_outer.png"))
mid().save(os.path.join(OUT, "sigil_mid.png"))
