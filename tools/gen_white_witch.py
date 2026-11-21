import math
import sys
from PIL import Image

D = sys.argv[1] if len(sys.argv) > 1 else "assets/witch_white"
HAIR, HAIR_D, CLOAK = (236, 236, 224, 255), (162, 162, 154, 255), (59, 50, 74, 255)
SKIN = (230, 209, 184, 255)
EYE = (212, 117, 100, 255)
FACE = {SKIN, EYE, (146, 81, 69, 255), (158, 144, 127, 255)}
EYE_CORE, EYE_EDGE = (226, 170, 255, 255), (150, 70, 230, 255)
EYE_LIT, EYE_PUPIL = (150, 84, 228, 255), (22, 14, 32, 255)
DARKS = {(59, 50, 74), (41, 35, 51), (64, 81, 98), (51, 70, 82), (54, 46, 67)}
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
    """Purple eyes (iris + the dark pupil beside it) and a white mask of them for tinting (red in Singularity)."""
    fr = fr.copy()
    mask = Image.new("RGBA", fr.size)
    px, mp = fr.load(), mask.load()
    for (x, y) in eye_pixels(fr):
        px[x, y] = EYE_LIT
        mp[x, y] = (255, 255, 255, 255)
        if x + 1 < fr.width and px[x + 1, y][:3] in DARKS:
            px[x + 1, y] = EYE_PUPIL
    return fr, mask



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


def palm_orb(fr, hand, big):
    """A small solid pixel orb in the open palm."""
    if not hand:
        return fr
    fr = fr.copy()
    px = fr.load()
    hx, hy = hand[0] + 1, hand[1]
    pts = {(0, 0): EYE_CORE, (1, 0): EYE_LIT, (-1, 0): EYE_LIT, (0, 1): EYE_LIT, (0, -1): EYE_LIT,
           (1, 1): EYE_EDGE, (-1, 1): EYE_EDGE, (1, -1): EYE_EDGE, (-1, -1): EYE_EDGE}
    if big:
        pts.update({(2, 0): EYE_EDGE, (0, 2): EYE_EDGE, (0, -2): EYE_EDGE})
    for (dx, dy), c in pts.items():
        x, y = hx + dx, hy + dy
        if 0 <= x < fr.width and 0 <= y < fr.height:
            px[x, y] = c
    return fr


def backify(fr, f=0, n=6):
    """Seen from behind: the face is gone under her hair, which falls loose down her back."""
    fr = dewand(fr)
    px = fr.load()
    w, h = fr.size
    box = face_box(fr)
    if not box:
        return fr, Image.new("RGBA", fr.size)
    top = box[1] + 1
    hair = {HAIR[:3], HAIR_D[:3]}
    opaque = lambda x, y: 0 <= x < w and 0 <= y < h and px[x, y][3] == 255
    rows = [y for y in range(h) if any(px[x, y][3] == 255 for x in range(w))]
    bottom = max(rows)
    base_end = top + int((bottom - top) * 0.6)
    # which way the loose hair is already streaming (cast frames blow it sideways)
    left = sum(1 for y in range(h) for x in range(0, box[0] - 4) if px[x, y][:3] in hair)
    right = sum(1 for y in range(h) for x in range(box[2] + 4, w) if px[x, y][:3] in hair)
    blow = -1 if left > right + 6 else (1 if right > left + 6 else 0)
    cx = (box[0] + box[2]) / 2.0
    painted = {}
    for y in range(top, base_end + 4):
        xs = [x for x in range(w) if opaque(x, y) and px[x, y][:3] not in hair]
        near = [x for x in xs if abs(x - cx) < 14]
        if not near:
            continue
        xl, xr = max(min(near), int(cx) - 8), min(max(near), int(cx) + 7)
        if y < top + 3:
            xl, xr = max(xl, box[0] + 1), min(xr, box[2] - 1)
        else:
            xl, xr = xl - (1 if y > top + 4 else 0), xr + (1 if y > top + 4 else 0)
        for x in range(xl, xr + 1):
            drift = blow * max(0, y - top - 6) // 4
            end = base_end + round(1.6 * math.sin((x - drift) * 1.1 + f * 0.9)) + (2 if (x - cx) * (blow or -1) > 2 else 0)
            if y > end:
                continue
            painted[(x, y)] = end
    # the cap over her head stays on the body; the rest is a separate layer that sways
    cap = top + 3
    for (x, y) in painted:
        if y <= cap:
            px[x, y] = HAIR
    layer = Image.new("RGBA", fr.size)
    lp = layer.load()
    length = max(1, base_end - top)
    swing = math.sin(f / n * math.tau)
    moved = {}
    for (x, y), end in painted.items():
        t = max(0.0, (y - top) / length)
        dx = round(2.2 * t ** 1.5 * swing + (0.8 * t * math.sin(f / n * math.tau * 2 + x * 0.7) if t > 0.7 else 0))
        moved[(x + dx, y)] = end + dx * 0
    for (x, y) in moved:
        if 0 <= x < w:
            lp[x, y] = HAIR
    for (x, y), end in moved.items():
        if not 0 <= x < w:
            continue
        edge = (x - 1, y) not in moved or (x + 1, y) not in moved or (x, y + 1) not in moved
        sweep = blow * max(0, y - top - 4) * 0.2 + 2.2 * ((y - top) / length) ** 1.5 * swing
        strand = any(abs(x - (cx + k * (1.2 + (y - top) * 0.2) + sweep)) < 0.5 for k in (-2, -1, 1, 2))
        if edge or (strand and y > top + 3 and (y + int(x)) % 5 != 0):
            lp[x, y] = HAIR_D
    return fr, layer


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
    frs = [dewand(strip_shadow(f, palette_only)) for f in frs]
    rc = [recolor(f) for f in frs]
    stack([r[0] for r in rc]).save(f"{D}/{name}.png")
    stack([r[1] for r in rc]).save(f"{D}/{name}_eyes.png")
    if back:
        bk = [backify(f, i, len(frs)) for i, f in enumerate(frs)]
        stack([b[0] for b in bk]).save(f"{D}/{name}_back.png")
        stack([b[1] for b in bk]).save(f"{D}/{name}_hair.png")
    print(name, len(frs), frs[0].size)


src = lambda n: Image.open(f"{D}/src_{n}.png").convert("RGBA")
for f in frames(src("idle"), 64, 64) + frames(src("run"), 64, 64):
    PALETTE.update(p[:3] for p in f.getdata() if p[3] == 255)
save("idle", frames(src("idle"), 64, 64), True)
save("hurt", frames(src("take_damage"), 64, 64), True)
save("death", frames(src("take_death"), 64, 64))
att = frames(src("attack"), 132, 47)
casts = [hand_cast(strip_shadow(att[i].crop((0, 0, 44, 47)))) for i in [4, 5, 6, 7, 8, 9, 10]]
save("cast", [palm_orb(c[0], c[1], i > 0) for i, c in enumerate(casts)], True)
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


SKINS = {(226, 184, 161), (230, 209, 184), (225, 184, 162), (229, 209, 185), (172, 137, 120)}
PALE = {(217, 217, 206), (191, 191, 182)}
VIOLET = [(110, 60, 180), (150, 90, 230), (190, 130, 255), (232, 200, 255)]


def charge_fx():
    """The red witch's charge: a rune circle gathering into a spark at her palm, and dust swirling at her feet."""
    src = Image.open("assets/witch_red/R_witch_charge.png").convert("RGBA")
    hands, dusts = [], []
    for i in range(src.height // 65):
        fr = src.crop((0, i * 65, 155, (i + 1) * 65))
        px = fr.load()
        hand = Image.new("RGBA", (40, 32))
        dust = Image.new("RGBA", (90, 28))
        hp, dp = hand.load(), dust.load()
        for y in range(65):
            for x in range(155):
                p = px[x, y]
                if p[3] == 0:
                    continue
                if p[:3] in PALE and y >= 34:
                    if 0 <= y - 34 < 28 and x < 90:
                        dp[x, y - 34] = (176, 164, 214, min(255, p[3] if p[3] < 255 else 200))
                elif x >= 52 and 13 <= y < 45 and p[:3] not in SKINS and sum(p[:3]) > 250:
                    lum = sum(p[:3]) / 3.0
                    c = VIOLET[min(3, int((lum - 80) / 45))]
                    if 0 <= x - 48 < 40:
                        hp[x - 48, y - 13] = c + (255,)
        hands.append(hand)
        dusts.append(dust)
    stack(hands).save(f"{D}/charge_hand.png")
    stack(dusts).save(f"{D}/charge_dust.png")
    print("charge fx", len(hands))


charge_fx()
