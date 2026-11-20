import sys
from PIL import Image

SRC = sys.argv[1] if len(sys.argv) > 1 else "assets/witch"
im = Image.open(f"{SRC}/B_witch_attack.png").convert("RGBA")
fw, fh, n, keep_w = 104, 46, 5, 60
out = Image.new("RGBA", (keep_w, fh * n))
for i in range(n):
    fr = im.crop((0, i * fh, keep_w, (i + 1) * fh))
    px = fr.load()
    for y in range(fh):
        for x in range(keep_w):
            if y >= 35 and x > 30:
                px[x, y] = (0, 0, 0, 0)
    out.paste(fr, (0, i * fh))
out.save(f"{SRC}/B_witch_cast.png")
