import sys
from PIL import Image

SRC = sys.argv[1] if len(sys.argv) > 1 else "assets/witch"
HAIR, HAIR_D = (79, 164, 165, 255), (55, 113, 114, 255)
CLOAK_D = (41, 35, 51, 255)
FACE = {(162, 162, 154, 255), (158, 144, 127, 255), (236, 236, 224, 255), (230, 209, 184, 255)}
SHEETS = [("idle", 32, 48), ("run", 32, 48), ("take_damage", 32, 48), ("charge", 48, 48)]


def backify(fr):
    w, h = fr.size
    px = fr.load()
    face_px = sum(1 for y in range(h) for x in range(w) if px[x, y] in FACE)
    face_rows = [y for y in range(h) if any(px[x, y] in FACE for x in range(w))]
    if not face_rows or face_px > 40:
        return fr
    top, bot = min(face_rows), max(face_rows)
    xs = [x for y in face_rows for x in range(w) if px[x, y] in FACE]
    cx = (min(xs) + max(xs)) // 2
    for y in range(top, bot + 2):
        row = [x for x in range(w) if px[x, y][3] > 0 and (px[x, y] == HAIR or px[x, y] in FACE)]
        if not row:
            continue
        x0, x1 = min(row), max(row)
        if y == bot + 1:
            x0, x1 = max(x0, cx - 4), min(x1, cx + 4)
        for x in range(x0, x1 + 1):
            if px[x, y][3] == 0:
                continue
            edge = x in (x0, x1)
            part = x == cx
            px[x, y] = HAIR_D if (edge or part or y == top) and not (y == top and not edge and not part and x % 3) else HAIR
    for i, half in enumerate([2, 2, 1, 1]):
        y = bot + 2 + i
        if y >= h:
            break
        for x in range(cx - half, cx + half + 1):
            if px[x, y][3] > 0 and px[x, y][:3] != (0, 0, 0):
                px[x, y] = HAIR_D if x in (cx - half, cx + half) or i == 3 else HAIR
    return fr


for name, fw, fh in SHEETS:
    im = Image.open(f"{SRC}/B_witch_{name}.png").convert("RGBA")
    n = im.height // fh
    out = Image.new("RGBA", im.size)
    for i in range(n):
        fr = backify(im.crop((0, i * fh, fw, (i + 1) * fh)))
        out.paste(fr, (0, i * fh))
    out.save(f"{SRC}/B_witch_{name}_back.png")
    print(name, n)
