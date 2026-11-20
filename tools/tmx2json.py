import json
import os
import sys
import xml.etree.ElementTree as ET

from PIL import Image

SOLID_LAYERS = {"wall-8", "Animated water"}
PASSABLE_LAYERS = {"stairs"}
WALKABLE_TILES = {"wall-8": {22}}


def convert(tmx, out, res_root):
    base = os.path.dirname(tmx)
    root = ET.parse(tmx).getroot()
    W, H = int(root.get("width")), int(root.get("height"))
    tsize = int(root.get("tilewidth"))
    sets = []
    for ts in root.findall("tileset"):
        tsx_path = os.path.join(base, ts.get("source"))
        tsx = ET.parse(tsx_path).getroot()
        img = tsx.find("image")
        path = os.path.normpath(os.path.join(os.path.dirname(tsx_path), img.get("source")))
        anims = {}
        for t in tsx.findall("tile"):
            a = t.find("animation")
            if a is not None:
                frames = [int(f.get("tileid")) for f in a.findall("frame")]
                anims[int(t.get("id"))] = {"frames": frames, "ms": int(a.find("frame").get("duration"))}
        sets.append({
            "firstgid": int(ts.get("firstgid")), "name": tsx.get("name"), "columns": int(tsx.get("columns")),
            "image": "res://" + os.path.relpath(path, res_root).replace(os.sep, "/"), "anims": anims,
        })
    sets.sort(key=lambda s: s["firstgid"])
    strips = {}
    for si, s in enumerate(list(sets)):
        if not s["anims"]:
            continue
        src = Image.open(os.path.join(res_root, s["image"][6:])).convert("RGBA")
        bases = sorted(s["anims"])
        n = max(len(s["anims"][b]["frames"]) for b in bases)
        strip = Image.new("RGBA", (n * tsize, len(bases) * tsize))
        for row, b in enumerate(bases):
            for k, f in enumerate(s["anims"][b]["frames"]):
                sx, sy = (f % s["columns"]) * tsize, (f // s["columns"]) * tsize
                strip.paste(src.crop((sx, sy, sx + tsize, sy + tsize)), (k * tsize, row * tsize))
        name = os.path.splitext(os.path.basename(out))[0] + "_anim%d.png" % si
        strip_path = os.path.join(os.path.dirname(out), name)
        strip.save(strip_path)
        frame_of = {}
        for row, b in enumerate(bases):
            for f in s["anims"][b]["frames"]:
                frame_of.setdefault(f, row)
        sets.append({
            "firstgid": -1, "name": s["name"] + " (anim)", "columns": n,
            "image": "res://" + os.path.relpath(strip_path, res_root).replace(os.sep, "/"),
            "anims": {str(row * n): {"frames": list(range(row * n, row * n + len(s["anims"][b]["frames"]))), "ms": s["anims"][b]["ms"]} for row, b in enumerate(bases)},
        })
        strips[si] = (len(sets) - 1, frame_of, n)
        s["anims"] = {}
    layers = []
    passable = set()
    for layer in root.findall("layer"):
        name = layer.get("name")
        data = [int(v) for v in layer.find("data").text.replace("\n", "").split(",") if v.strip()]
        cells = []
        for i, gid in enumerate(data):
            g = gid & 0x0FFFFFFF
            if g == 0:
                continue
            si = max(k for k, s in enumerate(sets) if 0 < s["firstgid"] <= g)
            lid = g - sets[si]["firstgid"]
            if si in strips and lid in strips[si][1]:
                si, lid = strips[si][0], strips[si][1][lid] * strips[si][2]
            flags = (1 if gid & 0x80000000 else 0) | (2 if gid & 0x40000000 else 0)
            cells.append([i % W, i // W, si, lid, flags])
            if name in WALKABLE_TILES and lid in WALKABLE_TILES[name]:
                cells[-1].append(1)
            if name in PASSABLE_LAYERS:
                passable.add(i)
        layers.append({"name": name, "solid": name in SOLID_LAYERS, "cells": cells})
    solid = sorted({c[1] * W + c[0] for l in layers if l["solid"] for c in l["cells"] if len(c) < 6} - passable)
    json.dump({"width": W, "height": H, "tile": tsize, "tilesets": sets, "layers": layers, "solid": solid}, open(out, "w"))
    print(out, W, H, len(layers), "layers", len(solid), "solid cells")


if __name__ == "__main__":
    convert(sys.argv[1], sys.argv[2], sys.argv[3])
