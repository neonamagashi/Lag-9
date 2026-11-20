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


LIT_HAND = (189, 197, 179)
SLEEVE = (64, 81, 98)


def reddish(p):
    return p[0] > p[1] + 40 and p[0] > p[2] + 40


def face_box(fr):
    px = fr.load()
    w, h = fr.size
    pts = [(x, y) for y in range(h) for x in range(w) if px[x, y][:3] == SKIN[:3]]
    if not pts:
        return None
    top = min(y for _, y in pts)
    pts = [(x, y) for x, y in pts if y <= top + 4]
    xs = [x for x, _ in pts]
    return (min(xs) - 2, top - 2, max(xs) + 2, top + 5)


def dewand(fr):
    """Remove the wand (and any teal magic) everywhere except the face."""
    fr = fr.copy()
    px = fr.load()
    box = face_box(fr)
    for y in range(fr.height):
        for x in range(fr.width):
            p = px[x, y]
            if p[3] == 0:
                continue
            in_face = box and box[0] <= x <= box[2] and box[1] <= y <= box[3]
            if (reddish(p) and not in_face) or p[:3] in TEALS or p[:3] in {(162, 210, 210), (166, 210, 210), (90, 168, 168), (176, 129, 117)}:
                px[x, y] = (0, 0, 0, 0)
    return fr


def hand_cast(fr):
    """Attack frame facing right: keep the open hand, drop the wand and beam beyond it."""
    fr = fr.copy()
    px = fr.load()
    w, h = fr.size
    hand = None
    for y in range(20, 34):
        for x in range(w - 1, 0, -1):
            if px[x, y][3] == 255 and px[x, y][:3] in (SKIN[:3], LIT_HAND, SLEEVE) and x > 24:
                if hand is None or x > hand[0]:
                    hand = (x, y)
                break
    for y in range(h):
        for x in range(w):
            p = px[x, y]
            if p[3] == 0:
                continue
            beyond = hand and x > hand[0] and 18 <= y <= 36
            if beyond or (p[3] < 255 and p[:3] != (0, 0, 0)):
                px[x, y] = (0, 0, 0, 0)
            elif p[:3] == LIT_HAND:
                px[x, y] = SKIN
    fr = dewand(fr)
    return fr, hand


def palm_glow(size, hand, k):
    """Additive purple glow layered on the open palm."""
    g = Image.new("RGBA", size)
    if not hand:
        return g
    gp = g.load()
    hx, hy = hand[0] + 1, hand[1]
    r = 2.6 + k
    for y in range(int(hy - r - 2), int(hy + r + 3)):
        for x in range(int(hx - r - 2), int(hx + r + 3)):
            if not (0 <= x < size[0] and 0 <= y < size[1]):
                continue
            d = ((x - hx) ** 2 + (y - hy) ** 2) ** 0.5
            if d <= 1.0:
                c = (EYE_CORE[0], EYE_CORE[1], EYE_CORE[2], 255)
            elif d <= r:
                c = (EYE_EDGE[0], EYE_EDGE[1], EYE_EDGE[2], int(200 * (1 - d / (r + 1))))
            else:
                continue
            if gp[x, y][3] < c[3]:
                gp[x, y] = c
    return g


def backify(fr):
    """Seen from behind: face hidden and a sheet of white hair down her back."""
    fr = dewand(fr)
    px = fr.load()
    w, h = fr.size
    box = face_box(fr)
    if not box:
        return fr
    top = box[1] + 2
    for y in range(top - 1, min(h, top + 5)):
        for x in range(w):
            if px[x, y][3] and (px[x, y][:3] in {c[:3] for c in FACE} or reddish(px[x, y])):
                px[x, y] = HAIR
    body = {(59, 50, 74), (41, 35, 51), (64, 81, 98), (51, 70, 82), (230, 209, 184), (236, 236, 224), (162, 162, 154)}
    cloak = {(59, 50, 74), (41, 35, 51), (64, 81, 98), (51, 70, 82)}
    rows = [y for y in range(h) if any(px[x, y][3] == 255 for x in range(w))]
    bottom = max(rows)
    length = int((bottom - top) * 0.62)
    end = top + 5 + length
    for y in range(top + 3, min(h, end)):
        xs = [x for x in range(w) if px[x, y][3] == 255 and px[x, y][:3] in body]
        if not xs:
            continue
        # contiguous run nearest the face centre
        cx = (box[0] + box[2]) // 2
        xl = xr = min(xs, key=lambda x: abs(x - cx))
        while xl - 1 in xs:
            xl -= 1
        while xr + 1 in xs:
            xr += 1
        cl = [x for x in range(xl, xr + 1) if px[x, y][:3] in cloak]
        if not cl:
            continue
        xl, xr = min(cl), max(cl)
        taper = max(0, y - (end - 4))
        a, b = xl + 1 + taper // 2, xr - 1 - (taper + 1) // 2
        mid = (a + b) / 2.0
        for x in range(a, b + 1):
            if px[x, y][:3] in (HAIR[:3], HAIR_D[:3]):
                continue
            strand = y > top + 8 and abs(x - mid) > 0.6 and ((x * 7 + y // 4 * 3) % 5 == 0)
            px[x, y] = HAIR_D if x in (a, b) or strand or (y == end - 1 and taper) else HAIR
    return fr


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


def save(name, frs, back=False, palette_only=False, glows=None):
    frs = [dewand(strip_shadow(f, palette_only)) for f in frs]
    rc = [recolor(f) for f in frs]
    stack([r[0] for r in rc]).save(f"{D}/{name}.png")
    gl = [r[1] for r in rc]
    if glows:
        gl = [Image.alpha_composite(a, b) for a, b in zip(gl, glows)]
    stack(gl).save(f"{D}/{name}_eyes.png")
    if back:
        stack([backify(f) for f in frs]).save(f"{D}/{name}_back.png")
    print(name, len(frs), frs[0].size)


src = lambda n: Image.open(f"{D}/src_{n}.png").convert("RGBA")
for f in frames(src("idle"), 64, 64) + frames(src("run"), 64, 64):
    PALETTE.update(p[:3] for p in f.getdata() if p[3] == 255)
save("idle", frames(src("idle"), 64, 64), True)
save("hurt", frames(src("take_damage"), 64, 64), True)
save("death", frames(src("take_death"), 64, 64))
att = frames(src("attack"), 132, 47)
casts = [hand_cast(strip_shadow(att[i].crop((0, 0, 44, 47)))) for i in [4, 5, 6, 7, 8, 9, 10]]
save("cast", [c[0] for c in casts], True, glows=[palm_glow((44, 47), c[1], 0.6 if i else 0.0) for i, c in enumerate(casts)])
print("hands", [c[1] for c in casts])
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


for n, fh in [("idle", 64), ("hurt", 64), ("death", 64), ("cast", 47), ("jump", 64)]:
    print("anchor", n, anchor(n, fh))
