#!/usr/bin/env python3
"""Pixel coverage of the Mystic Woods pack by the randomizer's maps.

Reads .liveliness/pack_usage.json (from tools/pack_usage.gd) and reports, per
sheet in assets/pack/sprites, how many of its opaque pixels lie in regions the
maps use. Files that repeat art from a used sheet (water1-6.png are the frames
of water-sheet.png; rock_in_water_01-06.png the frames of its sheet) count as
covered when their pixels match. Characters are listed apart.
"""
import json, os, sys
import numpy as np
from PIL import Image

ROOT = "assets/pack/sprites"
used = json.load(open(".liveliness/pack_usage.json"))

def alpha(path):
    return np.array(Image.open(os.path.join(ROOT, path)).convert("RGBA"))

def mask_for(sheet):
    a = alpha(sheet)
    m = np.zeros(a.shape[:2], bool)
    for key in used.get(sheet, []):
        x, y, w, h = map(int, key.split(","))
        m[y:y + h, x:x + w] = True
    return a, m

rows = []
sheets = []
for d, _, files in os.walk(ROOT):
    for f in files:
        if f.endswith(".png"):
            sheets.append(os.path.relpath(os.path.join(d, f), ROOT).replace("\\", "/"))
used_art = {}
for s in sorted(sheets):
    a = alpha(s)
    opaque = a[:, :, 3] > 0
    if s.startswith("characters/"):
        rows.append((s, opaque.sum(), None, "character"))
        continue
    _, m = mask_for(s)
    cov = (opaque & m).sum()
    rows.append((s, opaque.sum(), cov, ""))
    used_art[s] = (a, m)

# Duplicate files: a 16 px cell counts as covered when it is pixel-identical
# to a used cell of another sheet (water1-6.png are water-sheet.png's frames
# laid out one per file; rock_in_water_01-06.png the rock sheet's frames).
def _used_cells():
    cells = set()
    for s, (b, m) in used_art.items():
        for y in range(0, b.shape[0] - 15, 16):
            for x in range(0, b.shape[1] - 15, 16):
                if m[y:y + 16, x:x + 16].all():
                    cells.add(b[y:y + 16, x:x + 16].tobytes())
    return cells


def covered_by_equal(path, cells):
    a = alpha(path)
    tot = cov = 0
    for y in range(0, a.shape[0] - 15, 16):
        for x in range(0, a.shape[1] - 15, 16):
            c = a[y:y + 16, x:x + 16]
            n = int((c[:, :, 3] > 0).sum())
            tot += n
            cov += n if c.tobytes() in cells else 0
    return cov

cells = _used_cells()
out = []
tot = cov_tot = 0
for s, n, c, note in rows:
    if note == "character":
        out.append((s, n, None, "character (not part of the recipes)"))
        continue
    if c == 0 and (("water" in s and s[-5].isdigit()) or "rock_in_water_0" in s):
        c = covered_by_equal(s, cells)
        if c:
            note = "same frames as a used sheet"
    tot += n
    cov_tot += c
    out.append((s, n, c, note))
for s, n, c, note in out:
    if c is None:
        print(f"{s:42s} {'':>9}  {note}")
    else:
        print(f"{s:42s} {c / n * 100:6.1f} %  {note}")
print(f"\nALL tilesets, objects, particles: {cov_tot / tot * 100:.1f} % of opaque pixels")
