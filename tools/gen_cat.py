"""Whiskey from the black cat pack: yellow eyes, and a half-size version that keeps clean pixels."""
from collections import Counter

from PIL import Image

D = "assets/cat"
F = 64
BLACK, GLINT = (18, 14, 20), (211, 223, 225)
EYE, EYE_HI = (236, 196, 52, 255), (255, 240, 160, 255)
ROWS = {"walk_down": (2, 6), "walk_up": (3, 6), "walk_right": (4, 6), "walk_left": (5, 6), "meow": (16, 3)}


def yellow_eyes(fr):
    fr = fr.copy()
    px = fr.load()
    glints = [(x, y) for y in range(F) for x in range(F) if px[x, y][:3] == GLINT and px[x, y][3]]
    for gx, gy in glints:
        for dy in range(0, 3):
            for dx in range(-2, 2):
                x, y = gx + dx, gy + dy
                if 0 <= x < F and 0 <= y < F and px[x, y][:3] == BLACK and px[x, y][3]:
                    px[x, y] = EYE
        px[gx, gy] = EYE_HI
    return fr


def half(fr):
    """2x2 blocks -> the most common opaque colour, if at least two of the four are opaque."""
    out = Image.new("RGBA", (F // 2, F // 2))
    src, dst = fr.load(), out.load()
    for y in range(0, F, 2):
        for x in range(0, F, 2):
            block = [src[x + i, y + j] for j in (0, 1) for i in (0, 1)]
            solid = [p for p in block if p[3] > 0]
            if len(solid) >= 2:
                # eyes win over fur so they survive the shrink
                eyes = [p for p in solid if p in (EYE, EYE_HI)]
                dst[x // 2, y // 2] = eyes[0] if eyes else Counter(solid).most_common(1)[0][0]
    return out


sheet = Image.open(f"{D}/src_black_cat.png").convert("RGBA")
for name, (row, n) in ROWS.items():
    frames = [yellow_eyes(sheet.crop((c * F, row * F, (c + 1) * F, (row + 1) * F))) for c in range(n)]
    full = Image.new("RGBA", (F * n, F))
    small = Image.new("RGBA", (F // 2 * n, F // 2))
    for i, fr in enumerate(frames):
        full.paste(fr, (i * F, 0))
        small.paste(half(fr), (i * F // 2, 0))
    full.save(f"{D}/whiskey_{name}.png")
    small.save(f"{D}/whiskey_{name}_s.png")
    print(name, n)
