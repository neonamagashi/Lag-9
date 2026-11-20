import sys
from PIL import Image

D = sys.argv[1] if len(sys.argv) > 1 else "assets/witch_white"
HAIR, HAIR_D, CLOAK = (236, 236, 224, 255), (162, 162, 154, 255), (59, 50, 74, 255)
SKIN = (230, 209, 184, 255)
EYE = (212, 117, 100, 255)
FACE = {SKIN, EYE, (146, 81, 69, 255), (158, 144, 127, 255)}
EYE_CORE, EYE_EDGE = (226, 170, 255, 255), (150, 70, 230, 255)
TEALS = {(79, 164, 165), (55, 113, 114), (43, 84, 96), (37, 68, 84), (98, 196, 191), (159, 214, 210)}


def frames(img, fw, fh, cols=1):
    out = []
    for r in range(img.height // fh):
        for c in range(cols):
            out.append(img.crop((c * fw, r * fh, (c + 1) * fw, (r + 1) * fh)))
    return out


def stack(frs):
    w, h = frs[0].size
    out = Image.new("RGBA", (w, h * len(frs)))
    for i, f in enumerate(frs):
        out.paste(f, (0, i * h))
    return out


def eye_pixels(fr):
    px = fr.load()
    w, h = fr.size
    skin_rows = [y for y in range(h) if any(px[x, y] == SKIN for x in range(w))]
    if not skin_rows:
        return []
    top = min(skin_rows)
    return [(x, y) for y in range(max(0, top - 1), min(h, top + 3)) for x in range(w) if px[x, y] == EYE]


def recolor(fr):
    fr = fr.copy()
    glow = Image.new("RGBA", fr.size)
    px, gp = fr.load(), glow.load()
    eyes = eye_pixels(fr)
    for (x, y) in eyes:
        px[x, y] = EYE_CORE
    for (x, y) in eyes:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                gx, gy = x + dx, y + dy
                if 0 <= gx < fr.width and 0 <= gy < fr.height:
                    a = 255 if (dx, dy) == (0, 0) else 110
                    if gp[gx, gy][3] < a:
                        gp[gx, gy] = (EYE_EDGE[0], EYE_EDGE[1], EYE_EDGE[2], a)
    return fr, glow


def backify(fr):
    fr = fr.copy()
    px = fr.load()
    w, h = fr.size
    skin_rows = [y for y in range(h) if any(px[x, y] in FACE for x in range(w))]
    if not skin_rows:
        return fr
    top = min(skin_rows)
    face_px = sum(1 for y in range(h) for x in range(w) if px[x, y] in FACE)
    if face_px > 60:
        return fr
    xs = [x for y in range(top - 1, top + 5) for x in range(w) if 0 <= y < h and px[x, y] in FACE]
    if not xs:
        return fr
    x0, x1 = min(xs), max(xs)
    for y in range(top - 1, min(h, top + 5)):
        for x in range(x0, x1 + 1):
            if px[x, y] in FACE:
                px[x, y] = HAIR_D if x in (x0, x1) or y == top + 4 else HAIR
    return fr


def clean_charge(fr):
    fr = fr.copy()
    px = fr.load()
    w, h = fr.size
    body_x = min(x for x in range(w) for y in range(h) if px[x, y] == CLOAK and y > h * 0.55)
    for y in range(h):
        for x in range(w):
            p = px[x, y]
            if p[3] == 0:
                continue
            if p[:3] in TEALS or (x < body_x - 2 and p[:3] in {(236, 236, 224), (162, 162, 154), (90, 83, 112), (98, 91, 120)}):
                px[x, y] = (0, 0, 0, 0)
            elif x < body_x - 6:
                px[x, y] = (0, 0, 0, 0)
    return fr.transpose(Image.FLIP_LEFT_RIGHT)


PALETTE = set()


def strip_shadow(fr, palette_only=False):
    fr = fr.copy()
    px = fr.load()
    for y in range(fr.height):
        for x in range(fr.width):
            p = px[x, y]
            if p[3] == 0:
                continue
            if (p[:3] == (0, 0, 0) and p[3] < 200) or (palette_only and p[:3] not in PALETTE):
                px[x, y] = (0, 0, 0, 0)
    return fr


def save(name, frs, back=False, palette_only=False):
    frs = [strip_shadow(f, palette_only) for f in frs]
    rc = [recolor(f) for f in frs]
    stack([r[0] for r in rc]).save(f"{D}/{name}.png")
    stack([r[1] for r in rc]).save(f"{D}/{name}_eyes.png")
    if back:
        stack([backify(f) for f in frs]).save(f"{D}/{name}_back.png")
    print(name, len(frs), frs[0].size)


src = lambda n: Image.open(f"{D}/src_{n}.png").convert("RGBA")
for f in frames(src("idle"), 64, 64) + frames(src("run"), 64, 64):
    PALETTE.update(p[:3] for p in f.getdata() if p[3] == 255)
save("idle", frames(src("idle"), 64, 64), True)
save("run", frames(src("run"), 64, 64), True)
save("hurt", frames(src("take_damage"), 64, 64), True)
save("death", frames(src("take_death"), 64, 64))
att = frames(src("attack"), 132, 47)
save("cast", [f.crop((0, 0, 44, 47)) for f in att], True)
stack([f.crop((44, 0, 132, 47)) for f in att[5:11]]).save(f"{D}/beam.png")
ch = frames(src("charge"), 128, 64)
save("jump", [clean_charge(f.crop((70, 0, 124, 64))) for f in ch], True, True)


def anchor(name, fh):
    im = Image.open(f"{D}/{name}.png").convert("RGBA")
    fr = im.crop((0, 0, im.width, fh))
    px = fr.load()
    rows = [y for y in range(fh) if any(px[x, y][3] == 255 for x in range(fr.width))]
    bottom = max(rows)
    xs = [x for y in range(bottom - 8, bottom + 1) for x in range(fr.width) if px[x, y][:3] in (CLOAK[:3], (41, 35, 51))]
    return round(sum(xs) / len(xs), 1), bottom + 1, fr.width


for n, fh in [("idle", 64), ("run", 64), ("hurt", 64), ("death", 64), ("cast", 47), ("jump", 64)]:
    print("anchor", n, anchor(n, fh))
