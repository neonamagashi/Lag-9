import json
import math
import os
import sys

import numpy as np
import pymeshlab
import trimesh
from skimage.measure import marching_cubes

OUT = sys.argv[1] if len(sys.argv) > 1 else "models/levels/canyon"
RES = 0.33
X0, X1, Z0, Z1, Y0, Y1 = -34.0, 34.0, -40.0, 34.0, -2.0, 18.0
CLIFF_Z = -14.0
CLIFF_TOP = 14.0
CHAMBER = np.array([-13.0, 0.0, -24.0])
CHAMBER_R = 5.6

SAND = np.array([0.91, 0.76, 0.63])
SAND_DARK = np.array([0.85, 0.67, 0.55])
SAND_LIGHT = np.array([0.92, 0.80, 0.67])
ROCK = [np.array([0.80, 0.58, 0.50]), np.array([0.72, 0.50, 0.45]), np.array([0.86, 0.67, 0.56]), np.array([0.76, 0.55, 0.49])]
ROCK_TOP = np.array([0.91, 0.77, 0.65])
BASALT = [np.array([0.56, 0.50, 0.58]), np.array([0.50, 0.45, 0.54])]
CAVE_TINT = np.array([0.42, 0.40, 0.58])
BONE = np.array([0.90, 0.85, 0.74])
BONE_SHADE = np.array([0.80, 0.74, 0.64])
STONE = [np.array([0.82, 0.68, 0.58]), np.array([0.74, 0.60, 0.52]), np.array([0.86, 0.74, 0.62])]
ACCENT = np.array([0.82, 0.30, 0.22])
ACCENT_DARK = np.array([0.62, 0.20, 0.18])
SCRUB = [np.array([0.62, 0.60, 0.42]), np.array([0.70, 0.62, 0.40])]
WOOD = np.array([0.52, 0.38, 0.30])

rng = np.random.default_rng(9)
_YUP = trimesh.transformations.rotation_matrix(-math.pi / 2, (1, 0, 0))


def ycyl(radius, height, sections):
    m = trimesh.creation.cylinder(radius=radius, height=height, sections=sections)
    m.apply_transform(_YUP)
    return m


def ycone(radius, height, sections):
    m = trimesh.creation.cone(radius, height, sections=sections)
    m.apply_transform(_YUP)
    return m


# ---------- noise ----------
_perm = np.random.default_rng(3).random((64, 64, 64)).astype(np.float32)


def vnoise(x, y, z):
    xi, yi, zi = np.floor(x).astype(int), np.floor(y).astype(int), np.floor(z).astype(int)
    xf, yf, zf = x - xi, y - yi, z - zi
    u, v, w = xf * xf * (3 - 2 * xf), yf * yf * (3 - 2 * yf), zf * zf * (3 - 2 * zf)
    out = 0.0
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                g = _perm[(xi + dx) & 63, (yi + dy) & 63, (zi + dz) & 63]
                wx = u if dx else 1 - u
                wy = v if dy else 1 - v
                wz = w if dz else 1 - w
                out = out + g * wx * wy * wz
    return out * 2.0 - 1.0


def fbm(x, y, z, octaves=3):
    total, amp, freq, norm = 0.0, 1.0, 1.0, 0.0
    for _ in range(octaves):
        total = total + vnoise(x * freq, y * freq, z * freq) * amp
        norm += amp
        amp *= 0.5
        freq *= 2.0
    return total / norm


# ---------- shape functions ----------
def ground_h(x, z):
    base = fbm(x * 0.06, 0.0, z * 0.06, 2) * 0.45
    south = np.clip((z - 14.0) / 18.0, 0, 1) ** 1.6 * (2.8 + fbm(x * 0.08, 5.0, z * 0.08, 2) * 1.6)
    edge = np.clip((np.abs(x) - 18.0) / 9.0, 0, 1) ** 2 * 2.2
    return base + south + edge


def sd_box(px, py, pz, c, h):
    qx, qy, qz = np.abs(px - c[0]) - h[0], np.abs(py - c[1]) - h[1], np.abs(pz - c[2]) - h[2]
    outside = np.sqrt(np.maximum(qx, 0) ** 2 + np.maximum(qy, 0) ** 2 + np.maximum(qz, 0) ** 2)
    return outside + np.minimum(np.maximum(qx, np.maximum(qy, qz)), 0)


def sd_capsule(px, py, pz, a, b, r):
    pa = np.stack([px - a[0], py - a[1], pz - a[2]])
    ba = np.array(b) - np.array(a)
    h = np.clip((pa[0] * ba[0] + pa[1] * ba[1] + pa[2] * ba[2]) / ba.dot(ba), 0, 1)
    d = pa - ba.reshape((3,) + (1,) * (pa.ndim - 1)) * h
    return np.sqrt((d ** 2).sum(0)) - r


def sd_hex_prism(px, py, pz, c, radius, y0, y1, rot):
    x, z = px - c[0], pz - c[2]
    cr, sr = math.cos(rot), math.sin(rot)
    x, z = x * cr - z * sr, x * sr + z * cr
    k = (-0.8660254, 0.5)
    ax, az = np.abs(x), np.abs(z)
    dotk = np.minimum(k[0] * ax + k[1] * az, 0.0)
    ax, az = ax - 2 * dotk * k[0], az - 2 * dotk * k[1]
    d2 = np.sqrt((ax - np.clip(ax, -0.57735 * radius, 0.57735 * radius)) ** 2 + (az - radius) ** 2) * np.sign(az - radius)
    dy = np.maximum(y0 - py, py - y1)
    return np.maximum(d2, dy)


def smin(a, b, k):
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0, 1)
    return b * (1 - h) + a * h - k * h * (1 - h)


CAVE_PATH_A = [(-6.0, 1.9, -10.5), (-6.8, 1.9, -15.5), (-8.8, 1.9, -20.0), (-11.0, 1.9, -22.5)]
CAVE_PATH_B = [(-15.5, 1.9, -22.0), (-19.0, 1.9, -18.0), (-20.5, 1.9, -13.5), (-21.0, 1.9, -9.5)]
TERRACES = []
for k in range(1, 7):
    top = 2.2 * k
    zf = CLIFF_Z + (6 - k) * 2.5
    xa = 6.0 + math.sin(k * 1.7) * 1.8
    xb = 20.0 + math.cos(k * 1.3) * 2.0
    TERRACES.append(((xa + xb) / 2, top, zf, (xb - xa) / 2))
COLUMNS = []
for k in range(1, 7):
    a = 3.07 + (k - 1) * 0.65
    COLUMNS.append((CHAMBER[0] + math.cos(a) * 4.1, 2.2 * k, CHAMBER[2] + math.sin(a) * 4.1, a))


MOUTHS = [(-6.2, 1.2, -13.2), (-20.8, 1.2, -12.4)]


def cave_sdf(px, py, pz):
    d = np.full(px.shape, 1e9, dtype=np.float32)
    for path in (CAVE_PATH_A, CAVE_PATH_B):
        for a, b in zip(path[:-1], path[1:]):
            d = np.minimum(d, sd_capsule(px, py, pz, a, b, 2.2))
    for m in MOUTHS:
        d = np.minimum(d, np.sqrt(((px - m[0]) / 1.25) ** 2 + ((py - m[1]) / 1.1) ** 2 + (pz - m[2]) ** 2) - 3.0)
    d = np.maximum(d, -py - 0.05)
    cyl = np.sqrt((px - CHAMBER[0]) ** 2 + (pz - CHAMBER[2]) ** 2) - CHAMBER_R - fbm(px * 0.4, py * 0.4, pz * 0.4, 2) * 0.5
    cyl = np.maximum(cyl, -py)
    return np.minimum(d, cyl)


def world_sdf(px, py, pz):
    rough = fbm(px * 0.35, py * 0.35, pz * 0.35, 3)
    ground = py - ground_h(px, pz)
    face_noise = fbm(px * 0.18, py * 0.25, 0.0 * pz, 2) * 1.4
    cliff = np.maximum(pz - (CLIFF_Z + face_noise), py - (CLIFF_TOP + fbm(px * 0.1, 0, pz * 0.1, 2) * 0.4))
    rock = cliff
    for cx, top, zf, hw in TERRACES:
        b = sd_box(px, py, pz, (cx, (top - 3) / 2, (zf + CLIFF_Z - 6) / 2), (hw, (top + 3) / 2, (zf - CLIFF_Z + 6) / 2))
        rock = np.minimum(rock, b)
    rim_h = 8.5 * (1.0 - np.clip((pz - 6.0) / 22.0, 0, 1)) + fbm(px * 0.1, 3.0, pz * 0.1, 2) * 1.5
    rim_x = 27.0 + fbm(0.0, py * 0.2, pz * 0.15, 2) * 1.8
    rim = np.maximum(rim_x - np.abs(px), py - rim_h)
    rock = np.minimum(rock, rim)
    ax, ay, az = px - 19.0, py - 0.3, pz - 10.0
    q = np.sqrt(ax ** 2 + ay ** 2) - 5.2
    arch = np.sqrt(q ** 2 + (az * 0.8) ** 2) - 1.35
    rock = np.minimum(rock, arch)
    rock = rock + rough * 0.28
    solid = smin(ground, rock, 0.6)
    solid = np.maximum(solid, -cave_sdf(px, py, pz))
    for cx, top, cz, a in COLUMNS:
        solid = np.minimum(solid, sd_hex_prism(px, py, pz, (cx, 0, cz), 1.25, -1.0, top, a))
    return solid


def material_at(c, n):
    x, y, z = c[:, 0], c[:, 1], c[:, 2]
    up = n[:, 1]
    cols = np.zeros((len(c), 3))
    mat = np.zeros(len(c))
    gh = ground_h(x, z)
    near_ground = y < gh + 0.45
    patch = fbm(x * 0.12, 1.0, z * 0.12, 2)
    sand = np.where(patch[:, None] > 0.18, SAND_LIGHT, np.where(patch[:, None] < -0.2, SAND_DARK, SAND))
    band = np.floor((y + fbm(x * 0.15, 2.0, z * 0.15, 2) * 0.9) / 0.85).astype(int) % len(ROCK)
    rockc = np.array(ROCK)[band]
    is_top = up > 0.78
    cols[:] = rockc
    mat[:] = 0.5
    cols[is_top] = ROCK_TOP
    mat[is_top] = 0.75
    flat_ground = near_ground & (up > 0.6)
    cols[flat_ground] = sand[flat_ground]
    mat[flat_ground] = 1.0
    dist_col = np.full(len(c), 1e9)
    for cx, top, cz, a in COLUMNS:
        dist_col = np.minimum(dist_col, np.sqrt((x - cx) ** 2 + (z - cz) ** 2) - 1.3)
    on_col = (dist_col < 0.15) & (y > 0.2)
    bcol = np.array(BASALT)[(np.floor(y / 0.6).astype(int)) % 2]
    cols[on_col] = np.where(up[on_col, None] > 0.8, ROCK_TOP * 0.85, bcol[on_col])
    mat[on_col] = 0.25
    cave = cave_sdf(c[:, 0:1].T, c[:, 1:2].T, c[:, 2:3].T).ravel()
    inside = (cave < 0.5) & (z < CLIFF_Z + 1.5)
    depth = np.clip((CLIFF_Z + 1.0 - z) / 5.0, 0, 1) * np.clip((13.0 - y) / 5.0, 0, 1)
    k = (depth * inside)[:, None]
    cols = cols * (1 - k * 0.85) + cols * CAVE_TINT * (k * 0.85)
    return np.clip(cols, 0, 1), mat


# ---------- mesh helpers ----------
def decimate(mesh, faces):
    ms = pymeshlab.MeshSet()
    ms.add_mesh(pymeshlab.Mesh(mesh.vertices, mesh.faces))
    ms.meshing_decimation_quadric_edge_collapse(targetfacenum=faces, preservenormal=True, preservetopology=True, qualitythr=0.4, planarquadric=True)
    m = ms.current_mesh()
    return trimesh.Trimesh(m.vertex_matrix(), m.face_matrix(), process=True)


def flat(mesh, face_rgb, face_mat=None):
    m = mesh.copy()
    m.unmerge_vertices()
    n = len(m.faces)
    rgba = np.ones((n, 4))
    rgba[:, :3] = face_rgb
    rgba[:, 3] = face_mat if face_mat is not None else 0.0
    vc = np.repeat(rgba, 3, axis=0)
    out = trimesh.Trimesh(m.vertices, m.faces, process=False)
    out.visual = trimesh.visual.ColorVisuals(out, vertex_colors=(vc * 255).astype(np.uint8))
    return out


def solid(mesh, rgb, mat=0.0, jitter=0.03):
    n = len(mesh.faces)
    c = np.tile(rgb, (n, 1)) * (1 + rng.uniform(-jitter, jitter, (n, 1)))
    return flat(mesh, np.clip(c, 0, 1), np.full(n, mat))


def place(mesh, pos, rot_y=0.0, scale=1.0, tilt=(0.0, 0.0)):
    m = mesh.copy()
    m.apply_scale(scale)
    m.apply_transform(trimesh.transformations.euler_matrix(tilt[0], rot_y, tilt[1], "sxyz"))
    m.apply_translation(pos)
    return m


def rock_hull(w, h, d, seed, flat_top=True, sides=7):
    r = np.random.default_rng(seed)
    pts = []
    for i in range(sides):
        a = i / sides * math.tau + r.uniform(-0.3, 0.3)
        for yy in (0.0, h * r.uniform(0.35, 0.7), h):
            shrink = 1.0 if yy < h else r.uniform(0.62, 0.85)
            pts.append((math.cos(a) * w * shrink * r.uniform(0.82, 1.1), yy if (yy < h or flat_top) else yy * r.uniform(0.85, 1.0), math.sin(a) * d * shrink * r.uniform(0.82, 1.1)))
    pts.append((0, -0.4, 0))
    hull = trimesh.convex.convex_hull(np.array(pts))
    return hull


def ground_y(x, z):
    return float(ground_h(np.array([x]), np.array([z]))[0])


def band_colors(mesh, palette, scale=0.7, base_y=0.0):
    c = mesh.triangles_center
    n = mesh.face_normals
    idx = (np.floor((c[:, 1] - base_y) / scale + fbm(c[:, 0] * 0.3, 0, c[:, 2] * 0.3, 1) * 0.6).astype(int)) % len(palette)
    cols = np.array(palette)[idx]
    cols[n[:, 1] > 0.8] = ROCK_TOP
    mats = np.where(n[:, 1] > 0.8, 0.75, 0.5)
    return cols, mats


# ---------- terrain ----------
def build_terrain():
    xs = np.arange(X0, X1 + RES, RES, dtype=np.float32)
    ys = np.arange(Y0, Y1 + RES, RES, dtype=np.float32)
    zs = np.arange(Z0, Z1 + RES, RES, dtype=np.float32)
    field = np.empty((len(xs), len(ys), len(zs)), dtype=np.float32)
    for i in range(0, len(xs), 24):
        px, py, pz = np.meshgrid(xs[i:i + 24], ys, zs, indexing="ij")
        field[i:i + 24] = world_sdf(px, py, pz)
    field[:, 0, :] = -1
    field[:, -1, :] = 1
    verts, faces, _, _ = marching_cubes(field, 0.0, spacing=(RES, RES, RES))
    verts += np.array([X0, Y0, Z0])
    m = trimesh.Trimesh(verts, faces, process=True)
    print("terrain raw", len(m.faces))
    m = decimate(m, 70000)
    keep = ~((m.triangles_center[:, 1] < Y0 + 0.5))
    m.update_faces(keep)
    m.remove_unreferenced_vertices()
    cols, mats = material_at(m.triangles_center, m.face_normals)
    print("terrain faces", len(m.faces))
    return flat(m, cols, mats)


# ---------- boulders ----------
BOULDERS = [
    (-2.5, 6.0, 3.2, 2.2, 2.6, 0.3, 11),
    (-0.8, 5.0, 1.6, 1.5, 1.3, 1.1, 12),
    (1.6, 7.6, 2.0, 1.2, 1.6, 2.0, 13),
    (-3.2, 4.5, 1.6, 2.1, 1.4, 0.8, 14, 2.15),
    (6.0, 14.0, 2.6, 2.4, 2.3, 0.9, 15),
    (8.0, 12.6, 1.4, 1.3, 1.2, 0.4, 16),
    (-9.0, 16.0, 3.0, 1.8, 2.4, 2.4, 17),
    (-11.5, 13.5, 1.8, 2.3, 1.6, 0.2, 18),
    (-11.5, 13.5, 1.2, 1.4, 1.0, 1.0, 19, 2.3),
    (12.0, 2.0, 2.2, 1.0, 1.8, 0.6, 20),
    (-17.0, -3.0, 2.8, 2.4, 2.2, 1.7, 21),
    (-16.0, -6.0, 1.6, 1.1, 1.4, 0.3, 22),
    (16.0, -2.0, 1.6, 0.9, 1.3, 2.6, 23),
    (3.0, -6.0, 3.6, 2.0, 2.8, 0.1, 24),
    (5.2, -6.6, 1.8, 2.1, 1.6, 1.2, 25, 2.0),
    (-22.0, 6.0, 2.2, 1.6, 1.8, 2.0, 26),
    (21.0, 20.0, 2.4, 1.7, 2.0, 0.5, 27),
    (-6.0, 24.0, 1.4, 0.8, 1.2, 1.9, 28),
    (9.0, 26.0, 1.8, 1.2, 1.5, 0.7, 29),
    (-24.0, 18.0, 1.6, 1.3, 1.3, 0.9, 30),
]


def build_boulders():
    parts = []
    tops = []
    for b in BOULDERS:
        x, z, w, h, d, rot, seed = b[:7]
        lift = b[7] if len(b) > 7 else 0.0
        rk = rock_hull(w * 0.5 + 0.3, h, d * 0.5 + 0.3, seed)
        y = ground_y(x, z) - 0.25 + lift
        m = place(rk, (x, y, z), rot)
        cols, mats = band_colors(m, ROCK, 0.55, y)
        parts.append(flat(m, cols, mats))
        tops.append([x, y + h, z])
    return trimesh.util.concatenate(parts), tops


# ---------- props ----------
def pillar(height, broken, seed):
    r = np.random.default_rng(seed)
    parts = []
    base = trimesh.creation.box((1.7, 0.45, 1.7))
    base.apply_translation((0, 0.22, 0))
    parts.append(solid(base, STONE[1], 0.5))
    seg_h = 0.9
    y = 0.45
    k = 0
    while y < height:
        hh = min(seg_h, height - y)
        seg = ycyl(0.62 - 0.02 * k, hh, 8)
        seg.apply_transform(trimesh.transformations.rotation_matrix(r.uniform(-0.12, 0.12), (0, 1, 0)))
        seg.apply_translation((r.uniform(-0.03, 0.03), y + hh / 2, r.uniform(-0.03, 0.03)))
        parts.append(solid(seg, STONE[k % 2], 0.5))
        y += hh + 0.02
        k += 1
    if not broken:
        cap = trimesh.creation.box((1.6, 0.4, 1.6))
        cap.apply_translation((0, y + 0.2, 0))
        parts.append(solid(cap, STONE[2], 0.5))
    else:
        chunk = ycyl(0.6, 0.6, 8)
        cut = trimesh.creation.box((3, 3, 3))
        cut.apply_transform(trimesh.transformations.rotation_matrix(0.6, (1, 0, 0.3)))
        cut.apply_translation((0, 1.7, 0))
        try:
            chunk = chunk.difference(cut)
        except Exception:
            pass
        chunk.apply_translation((0, y + 0.3, 0))
        parts.append(solid(chunk, STONE[0], 0.5))
    return trimesh.util.concatenate(parts)


def wall_segment(length, height, seed):
    r = np.random.default_rng(seed)
    parts = []
    bh, bl, depth = 0.55, 1.1, 0.9
    rows = int(height / bh)
    for row in range(rows):
        x = -length / 2 + (bl / 2 if row % 2 else 0)
        row_len = length * (1 - (row / rows) ** 1.5 * r.uniform(0.2, 0.9))
        while x < -length / 2 + row_len:
            w = min(bl * r.uniform(0.8, 1.15), -length / 2 + row_len - x)
            if w > 0.25 and r.random() > 0.06:
                blk = trimesh.creation.box((w - 0.05, bh - 0.04, depth * r.uniform(0.9, 1.0)))
                blk.apply_translation((x + w / 2, row * bh + bh / 2, r.uniform(-0.04, 0.04)))
                parts.append(solid(blk, STONE[r.integers(0, 3)], 0.5, 0.05))
            x += w
    return trimesh.util.concatenate(parts)


def ribcage(seed):
    parts = []
    spine = []
    for i in range(9):
        t = i / 8
        spine.append((t * 9.0 - 4.5, 0.5 + math.sin(t * math.pi) * 1.2, 0.0))
    for a, b in zip(spine[:-1], spine[1:]):
        seg = trimesh.creation.capsule(height=float(np.linalg.norm(np.subtract(b, a))), radius=0.32, count=[6, 4])
        seg.apply_transform(trimesh.geometry.align_vectors((0, 0, 1), np.subtract(b, a)))
        seg.apply_translation(np.add(a, b) / 2)
        parts.append(solid(seg, BONE, 0.0))
    for i in range(1, 8):
        sx, sy, _ = spine[i]
        size = 1.0 + math.sin(i / 8 * math.pi) * 2.6
        for side in (-1, 1):
            pts = []
            for j in range(7):
                t = j / 6
                ang = t * 2.2
                pts.append((sx + 0.25 * t * side * 0, sy + math.cos(ang) * size * 0.9 - size * 0.15 - t * 0.9, side * math.sin(ang) * size))
            if i == 7 and side == 1:
                pts = pts[:4]
            for a, b in zip(pts[:-1], pts[1:]):
                L = float(np.linalg.norm(np.subtract(b, a)))
                seg = trimesh.creation.capsule(height=L, radius=0.16, count=[6, 3])
                seg.apply_transform(trimesh.geometry.align_vectors((0, 0, 1), np.subtract(b, a)))
                seg.apply_translation(np.add(a, b) / 2)
                parts.append(solid(seg, BONE if j % 2 else BONE_SHADE, 0.0))
    skull = trimesh.creation.icosphere(1, 1.3)
    skull.apply_scale((1.6, 0.9, 1.0))
    skull.apply_translation((5.6, 0.4, 0.0))
    parts.append(solid(skull, BONE, 0.0))
    horn = ycone(0.35, 2.4, 6)
    for side in (-1, 1):
        h = horn.copy()
        h.apply_transform(trimesh.transformations.rotation_matrix(0.9 * side, (1, 0, 0)))
        h.apply_translation((5.5, 1.0, 0.7 * side))
        parts.append(solid(h, BONE_SHADE, 0.0))
    return trimesh.util.concatenate(parts)


def banner(height, seed):
    pole = ycyl(0.07, height, 6)
    pole.apply_translation((0, height / 2, 0))
    bar = ycyl(0.05, 1.3, 5)
    bar.apply_transform(trimesh.transformations.rotation_matrix(math.pi / 2, (0, 0, 1)))
    bar.apply_translation((0.6, height - 0.15, 0))
    tip = ycone(0.12, 0.35, 5)
    tip.apply_translation((0, height, 0))
    return trimesh.util.concatenate([solid(pole, WOOD, 0.0), solid(bar, WOOD, 0.0), solid(tip, ACCENT_DARK, 0.0)])


def cloth(height, w=1.1, L=2.4, segs=8):
    verts, faces, cols = [], [], []
    for j in range(segs + 1):
        t = j / segs
        for i in range(3):
            s = i / 2
            x = 0.05 + s * w
            notch = 0.35 if (i == 1 and j == segs) else 0.0
            verts.append((x, height - 0.2 - t * L + notch, 0.0))
    for j in range(segs):
        for i in range(2):
            a = j * 3 + i
            faces.append((a, a + 3, a + 1))
            faces.append((a + 1, a + 3, a + 4))
            faces.append((a, a + 1, a + 3))
            faces.append((a + 1, a + 4, a + 3))
    m = trimesh.Trimesh(np.array(verts), np.array(faces), process=False)
    n = len(m.faces)
    rgb = np.tile(ACCENT, (n, 1))
    stripe = (np.arange(n) // 4) % 4 == 2
    rgb[stripe] = ACCENT_DARK
    return m, rgb


def scrub(seed):
    r = np.random.default_rng(seed)
    parts = []
    for i in range(r.integers(5, 9)):
        c = ycone(0.06, r.uniform(0.4, 0.9), 4)
        c.apply_transform(trimesh.transformations.rotation_matrix(r.uniform(0.2, 0.8), (math.cos(i * 2.1), 0, math.sin(i * 2.1))))
        parts.append(solid(c, SCRUB[i % 2], 0.0))
    return trimesh.util.concatenate(parts)


def pebble(seed):
    return rock_hull(0.18, 0.14, 0.15, seed, True, 5)


def stone_ring():
    ring = trimesh.creation.annulus(r_min=2.4, r_max=3.3, height=0.9, sections=12)
    ring.apply_transform(trimesh.transformations.rotation_matrix(0.25, (0, 0, 1)))
    ring.apply_translation((0, 1.7, 0))
    cols = np.tile(STONE[0], (len(ring.faces), 1))
    c = ring.triangles_center
    ang = np.arctan2(c[:, 1] - 1.7, c[:, 0])
    cols[(np.floor(ang / (math.tau / 12)).astype(int)) % 2 == 0] = STONE[1]
    out = [flat(ring, cols, np.full(len(ring.faces), 0.5))]
    for i in range(12):
        a = i / 12 * math.tau
        rune = trimesh.creation.box((0.5, 0.18, 0.95))
        rune.apply_transform(trimesh.transformations.rotation_matrix(a, (0, 0, 1)))
        rune.apply_translation((math.cos(a) * 3.35, 1.7 + math.sin(a) * 3.35, 0.0))
        rune.apply_transform(trimesh.transformations.rotation_matrix(0.25, (0, 0, 1), (0, 1.7, 0)))
        out.append(solid(rune, ACCENT if i % 3 == 0 else STONE[2], 0.0))
    return trimesh.util.concatenate(out)


def build_props():
    solid_parts, decor_parts, cloth_parts = [], [], []
    pillars = [
        (-6.0, 1.0, 5.5, False), (-2.0, 1.4, 3.2, True), (2.4, 0.4, 4.6, True),
        (-24.0, -18.0, 4.0, True), (-28.0, -22.0, 5.5, False), (8.0, -24.0, 3.5, True), (14.0, -30.0, 5.0, False), (20.0, -22.0, 2.4, True),
    ]
    for i, (x, z, h, broken) in enumerate(pillars):
        y = CLIFF_TOP - 0.3 if z < CLIFF_Z - 2 else ground_y(x, z) - 0.2
        solid_parts.append(place(pillar(h, broken, 40 + i), (x, y, z), i * 0.7))
    walls = [(-3.8, -1.0, 6.0, 2.6, 0.3), (-26.0, -26.0, 7.0, 3.2, 1.2), (11.0, -27.0, 6.0, 2.0, -0.3), (18.0, 16.0, 5.0, 1.8, 2.2)]
    for i, (x, z, L, H, rot) in enumerate(walls):
        y = CLIFF_TOP - 0.3 if z < CLIFF_Z - 2 else ground_y(x, z) - 0.15
        solid_parts.append(place(wall_segment(L, H, 60 + i), (x, y, z), rot))
    solid_parts.append(place(ribcage(1), (-13.0, ground_y(-13, 7) - 0.55, 7.0), 0.5))
    solid_parts.append(place(stone_ring(), (12.0, ground_y(12, 8) - 0.9, 8.0), -0.9, 1.0, (0.0, 0.18)))
    for i, (x, z) in enumerate([(-7.5, 2.5), (4.0, 3.0), (-18.0, -27.0), (0.0, -30.0), (24.0, -8.0)]):
        y = CLIFF_TOP - 0.3 if z < CLIFF_Z - 2 else ground_y(x, z) - 0.2
        h = 4.5
        solid_parts.append(place(banner(h, i), (x, y, z), i * 1.3))
        m, rgb = cloth(h)
        m = place(m, (x, y, z), i * 1.3)
        cloth_parts.append(flat(m, rgb, np.zeros(len(m.faces))))
    r = np.random.default_rng(5)
    for i in range(60):
        x, z = r.uniform(-25, 25), r.uniform(-12, 30)
        decor_parts.append(place(scrub(100 + i), (x, ground_y(x, z) - 0.05, z), r.uniform(0, 6)))
    for i in range(220):
        x, z = r.uniform(-26, 26), r.uniform(-13, 30)
        p = place(pebble(300 + i), (x, ground_y(x, z) - 0.05, z), r.uniform(0, 6), r.uniform(0.6, 2.4))
        decor_parts.append(solid(p, (ROCK[i % 4] * 0.6 + SAND_DARK * 0.4) * r.uniform(0.92, 1.05), 0.0, 0.06))
    for i in range(30):
        a = r.uniform(0, math.tau)
        rad = r.uniform(0, CHAMBER_R - 1.2)
        x, z = CHAMBER[0] + math.cos(a) * rad, CHAMBER[2] + math.sin(a) * rad
        p = place(pebble(600 + i), (x, -0.02, z), r.uniform(0, 6), r.uniform(1.0, 3.0))
        decor_parts.append(solid(p, BASALT[i % 2], 0.0))
    return trimesh.util.concatenate(solid_parts), trimesh.util.concatenate(decor_parts), trimesh.util.concatenate(cloth_parts)


def export(mesh, name, collide):
    scene = trimesh.Scene()
    scene.add_geometry(mesh, node_name=name + ("-col" if collide else ""), geom_name=name)
    scene.export(os.path.join(OUT, name + ".glb"))


def build_far():
    n = 120
    xs = np.linspace(-220, 220, n + 1)
    zs = np.linspace(-220, 220, n + 1)
    gx, gz = np.meshgrid(xs, zs, indexing="ij")
    inside = np.maximum(np.abs(gx) / 32.0, np.maximum((gz + 2.0) / 34.0, -(gz + 4.0) / 38.0))
    big = (np.abs(fbm(gx * 0.012, 7.0, gz * 0.012, 3)) * 22.0 + fbm(gx * 0.04, 2.0, gz * 0.04, 2) * 3.0)
    ramp = np.clip((inside - 1.0) / 0.6, 0, 1)
    h = -4.0 + ramp * (big + 5.0)
    h = np.where(gz < -40, np.maximum(h, CLIFF_TOP - 1.0 + big * 0.4 * ramp), h)
    verts = np.stack([gx.ravel(), h.ravel(), gz.ravel()], 1)
    faces = []
    for i in range(n):
        for j in range(n):
            a = i * (n + 1) + j
            faces.append((a, a + 1, a + n + 2))
            faces.append((a, a + n + 2, a + n + 1))
    m = trimesh.Trimesh(verts, np.array(faces), process=True)
    m.fix_normals()
    if m.face_normals[:, 1].mean() < 0:
        m.invert()
    c = m.triangles_center
    up = m.face_normals[:, 1]
    cols = np.where((up > 0.75)[:, None], np.where((fbm(c[:, 0] * 0.03, 1, c[:, 2] * 0.03, 2) > 0.1)[:, None], SAND_LIGHT, SAND), SAND_DARK)
    rock = (c[:, 2] < -40) & (up < 0.8)
    band = (np.floor(c[:, 1] / 1.6).astype(int)) % len(ROCK)
    cols[rock] = np.array(ROCK)[band[rock]]
    mats = np.where(rock, 0.5, 1.0)
    return flat(m, cols, mats)


def main():
    os.makedirs(OUT, exist_ok=True)
    terrain = build_terrain()
    export(terrain, "terrain", True)
    boulders, tops = build_boulders()
    export(boulders, "boulders", True)
    props, decor, cloth_m = build_props()
    export(props, "props", True)
    export(decor, "decor", False)
    export(cloth_m, "banners", False)
    export(build_far(), "far", False)
    info = {
        "start": [0.0, ground_y(0, 24) + 0.4, 24.0],
        "boulder_tops": tops,
        "terrace_tops": [[cx, top, zf - 1.0] for cx, top, zf, hw in TERRACES],
        "chamber": CHAMBER.tolist(),
        "columns": [[c[0], c[1], c[2]] for c in COLUMNS],
        "cave_a": list(CAVE_PATH_A[0]),
        "cave_b": list(CAVE_PATH_B[-1]),
        "ground_samples": {f"{x},{z}": ground_y(x, z) for x in range(-24, 25, 4) for z in range(-12, 31, 4)},
    }
    with open(os.path.join(OUT, "layout.json"), "w") as f:
        json.dump(info, f, indent=1)
    for n in ["terrain", "boulders", "props", "decor", "banners", "far"]:
        print(n, os.path.getsize(os.path.join(OUT, n + ".glb")) // 1024, "KB")


if __name__ == "__main__":
    main()
