#!/usr/bin/env python3
"""Draws the bridge kits (assets/ai/bridges/): 24 bridge designs for the
Painted Lands maps' streams and rivers, which neither the Forest nor the
Farm sheet draws. Every color comes from the sheet the bridge stands on
(bridges_forest.png from TILESET_brighter.png, bridges_farm.png from
farm_spring_summer.png, bridges_farm_winter.png the farm kit with snow on
every surface that faces up, in farm_winter.png's snow colors); the outline
is each sheet's own dark.

Bridges are built from pieces on the 16 px grid, so any span works:

  across (east-west, over a stream running north-south): pieces 16 x 56,
    the deck two cells tall at rows 12-43, the back rail above it (to row
    2), the deck's front face and what holds it up below (to row 55):
      base  w (west end), m (middle), p (middle with a post, lantern,
            flower box ...), e (east end): drawn under the walker;
      front the same four: the front rail, drawn over the walker (sorted at
            the deck's front edge).
  along (north-south, over a stream running east-west): pieces 36 x 16,
    the deck two cells wide (rails at x 0-4 and 27-31, deck between), its
    shadow on the water at x 32-35: n (north end), m, p, s (south end, the
    deck's end face showing).

Sheet layout, one row of 56 px per design (DESIGNS order): across base at
x 0-63 (w m p e), across front at x 64-127, along pieces at x 128-199 (n m
on the first row of 16, p s on the second).

  python3 tools/gen_bridges.py [preview.png]

The names and order are Bridges.DESIGNS (scripts/bridges.gd); keep them in
step.
"""
import math
import sys

import numpy as np
from PIL import Image

PW, PH = 16, 56
DECK_TOP, DECK_BOT = 12, 44 # deck rows [12, 44)
VW, VH = 36, 16
ROW = 56
SHEET_W = 200


def c(h, a=255):
    return (int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16), a)


# Palettes per sheet: outline, then dark -> light ramps per material.
PALETTES = {
    "forest": {
        "line": c("#400b29"),
        "wood": [c("#481b28"), c("#5d3f38"), c("#6b5849"), c("#82715a"), c("#9a8f7e")],
        "wood_red": [c("#4e2536"), c("#604138"), c("#765849"), c("#907768"), c("#ab9e96")],
        "stone": [c("#533232"), c("#765849"), c("#907768"), c("#ab9e96"), c("#c5beb0")],
        "stone_cool": [c("#4e2536"), c("#846b73"), c("#8b8276"), c("#aca49c"), c("#c5beb0")],
        "sand": [c("#765849"), c("#ae947c"), c("#b9a48c"), c("#c2b5a2"), c("#c9c1b3")],
        "paint": [c("#6b5849"), c("#8b8276"), c("#aca49c"), c("#c5beb0"), c("#e3dac6")],
        "moss": [c("#1b5045"), c("#306750"), c("#53834f"), c("#7a9664")],
        "rope": [c("#6e5c4a"), c("#887661"), c("#9a8f7e")],
        "flame": [c("#c5622c"), c("#dcb760"), c("#e3dac6")],
        "flower": [c("#c5622c"), c("#dcb760"), c("#e3dac6")],
        "iron": [c("#191416"), c("#400b29")],
    },
    "farm": {
        "line": c("#42141b"),
        "wood": [c("#42141b"), c("#59362a"), c("#684a37"), c("#7d6349"), c("#897154")],
        "wood_red": [c("#3d211a"), c("#523228"), c("#603f31"), c("#6c4e3a"), c("#a58666")],
        "stone": [c("#3f2534"), c("#66584d"), c("#80817f"), c("#9e9c9a"), c("#b7b4aa")],
        "stone_cool": [c("#3f2534"), c("#5c4440"), c("#80817f"), c("#9e9c9a"), c("#b7b4aa")],
        "sand": [c("#836b4f"), c("#a58666"), c("#b29f7c"), c("#b8ab8f"), c("#c1b7a2")],
        "paint": [c("#836b4f"), c("#a58666"), c("#b8ab8f"), c("#c1b7a2"), c("#d0ccc7")],
        "moss": [c("#2e4d4f"), c("#3f804e"), c("#699654"), c("#86a962")],
        "rope": [c("#836b4f"), c("#a58666"), c("#b8ab8f")],
        "flame": [c("#a06e39"), c("#c4ac70"), c("#d0ccc7")],
        "flower": [c("#a06e39"), c("#c4ac70"), c("#d6d6e1")],
        "iron": [c("#3d211a"), c("#3f2534")],
    },
}
SNOW = [c("#a8c7eb"), c("#bbd2ee"), c("#d9e1e9")]
SHADOW = (20, 12, 20, 70)
CLEAR = (0, 0, 0, 0)

# Each design: deck kind and material, rail kind and material, what holds it
# up, the feature on `p` pieces, and extras.
DESIGNS = [
    {"name": "plank", "deck": "planks", "mat": "wood", "rail": None, "under": "beams"},
    {"name": "plank_rail", "deck": "planks", "mat": "wood", "rail": "post_rail", "rmat": "wood", "under": "beams", "post": True},
    {"name": "rope_plank", "deck": "planks_gappy", "mat": "wood", "rail": "rope", "rmat": "rope", "under": "thin", "post": True, "post_every": True},
    {"name": "boards", "deck": "boards", "mat": "wood_red", "rail": "curb", "rmat": "wood_red", "under": "beams"},
    {"name": "log_deck", "deck": "logs", "mat": "wood", "rail": None, "under": "log_ends"},
    {"name": "log_rail", "deck": "split_logs", "mat": "wood", "rail": "log", "rmat": "wood", "under": "beams", "post": True},
    {"name": "boardwalk", "deck": "planks_thin", "mat": "wood_red", "rail": None, "under": "stilts"},
    {"name": "clapper", "deck": "slabs", "mat": "stone", "rail": None, "under": "piers"},
    {"name": "stone_arch", "deck": "cobble", "mat": "stone", "rail": "parapet", "rmat": "stone", "under": "arches"},
    {"name": "mossy_arch", "deck": "cobble", "mat": "stone_cool", "rail": "parapet", "rmat": "stone_cool", "under": "arches", "moss": True},
    {"name": "lantern_stone", "deck": "blocks", "mat": "stone", "rail": "parapet_low", "rmat": "stone", "under": "arches", "post": "lantern"},
    {"name": "lattice", "deck": "planks", "mat": "wood_red", "rail": "lattice", "rmat": "wood_red", "under": "beams", "post": True},
    {"name": "flower_rail", "deck": "planks", "mat": "wood", "rail": "post_rail", "rmat": "wood", "under": "beams", "post": "flowers"},
    {"name": "branch_rail", "deck": "planks_gappy", "mat": "wood", "rail": "branch", "rmat": "wood", "under": "thin", "post": True},
    {"name": "trestle", "deck": "planks", "mat": "wood_red", "rail": "post_rail", "rmat": "wood_red", "under": "trestle", "post": True},
    {"name": "stone_pier", "deck": "boards", "mat": "wood", "rail": "curb", "rmat": "wood", "under": "piers"},
    {"name": "sandstone", "deck": "blocks", "mat": "sand", "rail": "parapet", "rmat": "sand", "under": "arches"},
    {"name": "painted", "deck": "planks", "mat": "wood", "rail": "post_rail", "rmat": "paint", "under": "beams", "post": True},
    {"name": "rustic", "deck": "planks_rough", "mat": "wood", "rail": "rope_one", "rmat": "rope", "under": "thin", "post": True, "post_every": True},
    {"name": "gate_posts", "deck": "planks", "mat": "wood_red", "rail": "post_rail", "rmat": "wood_red", "under": "beams", "gates": True},
    {"name": "mossy_slab", "deck": "slabs", "mat": "stone_cool", "rail": None, "under": "piers", "moss": True},
    {"name": "cobble_curb", "deck": "cobble", "mat": "sand", "rail": "curb", "rmat": "stone", "under": "arches", "post": "bollard"},
    {"name": "lantern_wood", "deck": "boards", "mat": "wood", "rail": "post_rail", "rmat": "wood", "under": "stilts", "post": "lantern"},
    {"name": "felled_log", "deck": "felled", "mat": "wood", "rail": None, "under": "log_ends", "moss": True},
]


class Canvas:
    def __init__(self, w, h):
        self.a = np.zeros((h, w, 4), dtype=np.uint8)
        self.top = np.zeros((h, w), dtype=bool) # surfaces facing up (snow lies there)
        self.ox = self.oy = 0
        self.bw = self.bh = 0

    def at(self, ox, oy, bw, bh):
        self.ox, self.oy, self.bw, self.bh = ox, oy, bw, bh
        return self

    def px(self, x, y, col, top=False):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.bw and 0 <= y < self.bh:
            X, Y = x + self.ox, y + self.oy
            if col[3] < 255 and self.a[Y, X, 3] == 255:
                # blend a translucent shade over what is there
                a = col[3] / 255.0
                self.a[Y, X, :3] = (self.a[Y, X, :3] * (1 - a) + np.array(col[:3]) * a).astype(np.uint8)
            else:
                self.a[Y, X] = col
            self.top[Y, X] = top

    def rect(self, x0, y0, x1, y1, col, top=False):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.px(x, y, col, top)

    def outline(self, col):
        """Outline every opaque pixel of the current box that borders a clear
        one (inside the box only)."""
        X0, Y0 = self.ox, self.oy
        src = self.a[Y0:Y0 + self.bh, X0:X0 + self.bw].copy()
        for y in range(self.bh):
            for x in range(self.bw):
                if src[y, x, 3] != 0:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < self.bw and 0 <= ny < self.bh and src[ny, nx, 3] == 255 and tuple(src[ny, nx]) != col:
                        self.a[Y0 + y, X0 + x] = col
                        break


def h(x, y, s=0):
    """A small stable hash in [0, 1)."""
    v = math.sin(x * 12.9898 + y * 78.233 + s * 37.719) * 43758.5453
    return v - math.floor(v)


# ---------------------------------------------------------------- decks

def deck_across(cv, d, P, kind, x0, x1):
    """The deck surface, rows DECK_TOP..DECK_BOT-1, columns x0..x1 (the
    walker crosses east-west)."""
    m = P[d["mat"]]
    deck = d["deck"]
    for y in range(DECK_TOP, DECK_BOT):
        for x in range(x0, x1 + 1):
            col = m[2]
            if deck in ("planks", "planks_gappy", "planks_rough", "planks_thin"):
                # boards laid north-south, three px wide, crossing the walk
                k = x % 4
                if k == 3:
                    col = m[0] if deck == "planks_gappy" and h(x // 4, 0, 1) < 0.5 else m[1]
                elif k == 0:
                    col = m[3]
                if deck == "planks_rough" and (y + int(h(x // 4, 2) * 6)) % 11 == 0:
                    col = m[1]
                if deck == "planks_thin" and y in (DECK_TOP + 15, DECK_TOP + 16):
                    col = m[1] # a joint down the middle
                if h(x, y, 3) < 0.04:
                    col = m[1] # knots
            elif deck == "boards":
                # boards laid along the walk, east-west
                k = (y - DECK_TOP) % 5
                if k == 4:
                    col = m[1]
                elif k == 0:
                    col = m[3]
                if (x + (y - DECK_TOP) // 5 * 7) % 16 == 0:
                    col = m[1] # butt joints
            elif deck in ("logs", "split_logs"):
                k = x % 6
                col = [m[1], m[3], m[3], m[2], m[2], m[1]][k]
                if deck == "split_logs" and k in (1, 2):
                    col = m[4]
                if h(x // 6, y // 3, 4) < 0.15 and k in (2, 3):
                    col = m[1] # bark marks
            elif deck == "felled":
                # two big trunks side by side along the walk, bark on top
                band = (y - DECK_TOP) % 16
                col = [m[1], m[2], m[3], m[3], m[4], m[3], m[3], m[2], m[2], m[2], m[3], m[2], m[2], m[1], m[1], m[0]][band]
                if h(x // 3, y, 5) < 0.18 and 2 < band < 13:
                    col = m[1]
            elif deck == "slabs":
                # big flat stones, joints between them
                sx = (x + (7 if (y - DECK_TOP) // 11 % 2 else 0)) % 14
                sy = (y - DECK_TOP) % 11
                col = m[2]
                if sx == 13 or sy == 10:
                    col = m[0]
                elif sx == 0 or sy == 0:
                    col = m[4]
                elif h(x, y, 6) < 0.1:
                    col = m[1]
                elif h(x, y, 7) < 0.1:
                    col = m[3]
            elif deck == "cobble":
                ry = (y - DECK_TOP) % 5
                cx = (x + (3 if (y - DECK_TOP) // 5 % 2 else 0)) % 6
                col = m[3] if (ry in (1, 2) and cx in (1, 2, 3)) else m[2]
                if ry == 4 or cx == 5:
                    col = m[1]
                if ry == 1 and cx == 1:
                    col = m[4]
            elif deck == "blocks":
                ry = (y - DECK_TOP) % 8
                cx = (x + (5 if (y - DECK_TOP) // 8 % 2 else 0)) % 10
                col = m[3]
                if ry == 7 or cx == 9:
                    col = m[1]
                elif ry == 0 or cx == 0:
                    col = m[4]
                elif h(x, y, 8) < 0.08:
                    col = m[2]
            cv.px(x, y, col, top=True)
    # the deck's edges: a lit back edge, a dark front edge
    for x in range(x0, x1 + 1):
        cv.px(x, DECK_TOP, m[4] if d["deck"] not in ("felled",) else m[2], top=True)
        cv.px(x, DECK_BOT - 1, m[1])


def deck_along(cv, d, P, kind):
    """The deck seen from above for a north-south bridge (pieces 36 x 16):
    boards run across (east-west) now."""
    m = P[d["mat"]]
    deck = d["deck"]
    y0 = 3 if kind == "n" else 0
    y1 = 12 if kind == "s" else 15
    for y in range(y0, y1 + 1):
        for x in range(5, 27):
            col = m[2]
            if deck in ("planks", "planks_gappy", "planks_rough", "planks_thin"):
                k = y % 4
                if k == 3:
                    col = m[0] if deck == "planks_gappy" and h(0, y // 4, 1) < 0.5 else m[1]
                elif k == 0:
                    col = m[3]
                if deck == "planks_thin" and x in (15, 16):
                    col = m[1]
                if deck == "planks_rough" and (x + int(h(y // 4, 2) * 6)) % 11 == 0:
                    col = m[1]
            elif deck == "boards":
                k = (x - 5) % 5
                col = m[1] if k == 4 else (m[3] if k == 0 else m[2])
                if (y + (x - 5) // 5 * 7) % 16 == 0:
                    col = m[1]
            elif deck in ("logs", "split_logs"):
                k = y % 6
                col = [m[1], m[3], m[3], m[2], m[2], m[1]][k]
                if deck == "split_logs" and k in (1, 2):
                    col = m[4]
            elif deck == "felled":
                band = (x - 5) % 11
                col = [m[1], m[2], m[3], m[4], m[3], m[3], m[2], m[2], m[2], m[1], m[0]][band]
                if h(x, y // 3, 5) < 0.18 and 1 < band < 9:
                    col = m[1]
            elif deck == "slabs":
                sx = (x - 5) % 11
                sy = (y + (7 if (x - 5) // 11 % 2 else 0)) % 14
                col = m[2]
                if sx == 10 or sy == 13:
                    col = m[0]
                elif sx == 0 or sy == 0:
                    col = m[4]
                elif h(x, y, 6) < 0.1:
                    col = m[1]
            elif deck == "cobble":
                ry = y % 5
                cx = (x + (3 if y // 5 % 2 else 0)) % 6
                col = m[3] if (ry in (1, 2) and cx in (1, 2, 3)) else m[2]
                if ry == 4 or cx == 5:
                    col = m[1]
            elif deck == "blocks":
                ry = y % 8
                cx = (x + (5 if y // 8 % 2 else 0)) % 10
                col = m[3]
                if ry == 7 or cx == 9:
                    col = m[1]
                elif ry == 0 or cx == 0:
                    col = m[4]
            cv.px(x, y, col, top=True)
    if kind == "n":
        for x in range(5, 27):
            cv.px(x, y0, m[4], top=True)
    if kind == "s":
        # the end face of the deck, toward the viewer
        for y in range(13, 16):
            for x in range(5, 27):
                cv.px(x, y, m[1] if y == 13 else m[0])


# ---------------------------------------------------------------- rails

def rail_mat(d, P):
    """The rails' material (a rope rail's posts are wood; the rope itself is
    drawn from P["rope"])."""
    rm = d.get("rmat", d["mat"])
    return P["wood"] if rm == "rope" else P[rm]


def rail_line(cv, d, P, base_y, x0, x1, post_xs, front):
    """A rail standing on the deck edge at `base_y` (its foot), across x0..x1,
    posts at post_xs."""
    rail = d["rail"]
    m = rail_mat(d, P)
    line = P["line"]
    if rail is None:
        return
    if rail in ("parapet", "parapet_low"):
        hgt = 9 if rail == "parapet" else 5
        for x in range(x0, x1 + 1):
            for y in range(base_y - hgt, base_y + 1):
                k = (y - (base_y - hgt))
                col = m[2]
                if k == 0:
                    col = m[4]
                elif k == 1:
                    col = m[3]
                elif (x + (2 if (k // 3) % 2 else 0)) % 5 == 0 or k % 3 == 0:
                    col = m[1]
                if k == hgt:
                    col = m[1]
                cv.px(x, y, col, top=(k <= 1))
            if d.get("moss") and h(x, base_y, 9) < 0.45:
                cv.px(x, base_y - hgt, P["moss"][2], top=True)
                if h(x, base_y, 10) < 0.5:
                    cv.px(x, base_y - hgt - 1, P["moss"][3])
        return
    if rail == "curb":
        for x in range(x0, x1 + 1):
            cv.px(x, base_y - 3, m[4], top=True)
            cv.px(x, base_y - 2, m[3])
            cv.px(x, base_y - 1, m[2])
            cv.px(x, base_y, m[1])
        return
    # posts
    for px_ in post_xs:
        for y in range(base_y - 10, base_y + 1):
            cv.px(px_, y, m[3] if rail != "branch" else m[2], top=(y == base_y - 10))
            cv.px(px_ + 1, y, m[1])
        cv.px(px_, base_y - 11, m[4], top=True)
        cv.px(px_ + 1, base_y - 11, m[2], top=True)
    if rail == "post_rail":
        for x in range(x0, x1 + 1):
            for ry in (base_y - 9, base_y - 5):
                cv.px(x, ry, m[3], top=True)
                cv.px(x, ry + 1, m[1])
    elif rail == "lattice":
        for x in range(x0, x1 + 1):
            cv.px(x, base_y - 9, m[3], top=True)
            cv.px(x, base_y - 8, m[1])
            for k in range(1, 8):
                if (x + k) % 8 == 0 or (x - k) % 8 == 0:
                    cv.px(x, base_y - 8 + k, m[2])
    elif rail == "log":
        for x in range(x0, x1 + 1):
            cv.px(x, base_y - 9, m[4], top=True)
            cv.px(x, base_y - 8, m[3])
            cv.px(x, base_y - 7, m[2] if h(x, 1, 11) > 0.2 else m[1])
            cv.px(x, base_y - 6, m[1])
    elif rail == "branch":
        for x in range(x0, x1 + 1):
            y = base_y - 8 + round(math.sin(x * 0.7) * 1.2)
            cv.px(x, y, m[3], top=True)
            cv.px(x, y + 1, m[1])
            if h(x, 3, 12) < 0.12:
                cv.px(x, y - 1, m[2]) # a twig
    elif rail in ("rope", "rope_one"):
        r = P["rope"]
        span = max(1, x1 - x0)
        for x in range(x0, x1 + 1):
            t = (x - x0) / span
            sag = math.sin(t * math.pi) * 2.5
            y = round(base_y - 8 + sag)
            cv.px(x, y, r[2] if x % 2 else r[1], top=True)
            if rail == "rope":
                cv.px(x, round(base_y - 4 + sag * 0.6), r[1] if x % 2 else r[0])


def planters(cv, d, P, base_y, x0, x1):
    """Flowers growing along a rail's top (the flower rail): leaves, and a
    bloom every few pixels."""
    mo = P["moss"]
    fl = P["flower"]
    for x in range(x0, x1 + 1):
        cv.px(x, base_y - 10, mo[2] if (x * 3) % 5 else mo[1], top=True)
        cv.px(x, base_y - 11, mo[3] if h(x, base_y, 30) < 0.6 else mo[2], top=True)
        if h(x, base_y, 31) < 0.4:
            cv.px(x, base_y - 12, fl[int(h(x, base_y, 32) * 3) % 3], top=True)
        if h(x, base_y, 33) < 0.25:
            cv.px(x, base_y - 9, mo[1])


def feature(cv, d, P, base_y, x):
    """The `p` piece's feature on a rail at `base_y`, centred on x."""
    f = d.get("post")
    if f == "lantern":
        m = P["iron"]
        fl = P["flame"]
        for y in range(base_y - 15, base_y + 1):
            cv.px(x, y, m[0])
        cv.rect(x - 2, base_y - 19, x + 2, base_y - 15, m[1])
        cv.rect(x - 1, base_y - 18, x + 1, base_y - 16, fl[1])
        cv.px(x, base_y - 17, fl[2])
        cv.px(x, base_y - 20, m[0])
    elif f == "flowers":
        w = P["wood"]
        fl = P["flower"]
        mo = P["moss"]
        cv.rect(x - 4, base_y - 13, x + 4, base_y - 10, w[2])
        cv.rect(x - 4, base_y - 10, x + 4, base_y - 10, w[1])
        for k in range(-4, 5):
            cv.px(x + k, base_y - 14, mo[2] if k % 2 else mo[1], top=True)
            if k % 3 == 0:
                cv.px(x + k, base_y - 15, fl[(k // 3) % 3], top=True)
    elif f == "bollard":
        m = P["stone"]
        cv.rect(x - 1, base_y - 6, x + 1, base_y, m[2])
        cv.rect(x - 1, base_y - 7, x + 1, base_y - 7, m[4], top=True)
        cv.px(x + 1, base_y - 3, m[1])


# ---------------------------------------------------------------- under

def under_across(cv, d, P, kind):
    """The deck's front face (rows 44-47) and what holds it up, to row 55,
    for one across piece; ends stand on the bank."""
    m = P[d["mat"]]
    line = P["line"]
    under = d["under"]
    x0, x1 = (3, 15) if kind == "w" else ((0, 12) if kind == "e" else (0, 15))
    # the front face
    for x in range(x0, x1 + 1):
        if d["deck"] in ("logs",) or under == "log_ends":
            continue
        cv.px(x, DECK_BOT, m[2])
        cv.px(x, DECK_BOT + 1, m[1])
        cv.px(x, DECK_BOT + 2, m[1] if x % 4 else m[0])
        cv.px(x, DECK_BOT + 3, m[0])
    if under == "log_ends":
        # the round ends of the logs (or the trunks' ends at the bridge ends)
        if d["deck"] == "felled":
            for x in range(x0, x1 + 1):
                for y in range(DECK_BOT, DECK_BOT + 3):
                    cv.px(x, y, m[1] if y < DECK_BOT + 2 else m[0])
        else:
            for x in range(x0, x1 + 1):
                k = x % 6
                for y in range(DECK_BOT, DECK_BOT + 5):
                    ring = abs(k - 2.5) + abs(y - DECK_BOT - 2)
                    col = m[3] if ring < 1.5 else (m[2] if ring < 2.6 else m[1])
                    if ring >= 3.4:
                        continue
                    cv.px(x, y, col)
    if kind in ("w", "e"):
        # an abutment on the bank: a sill and a footing
        s = P["stone"] if d["mat"] not in ("stone", "stone_cool", "sand") else m
        bx0, bx1 = (x0, x0 + 4) if kind == "w" else (x1 - 4, x1)
        for x in range(bx0, bx1 + 1):
            for y in range(DECK_BOT + 4, DECK_BOT + 8):
                cv.px(x, y, s[2] if (x + y) % 5 else s[1])
        for x in range(x0, x1 + 1):
            cv.px(x, DECK_BOT + 4, SHADOW)
        return
    # middle pieces: what stands in the water
    if under == "beams":
        for x in (3, 12):
            for y in range(DECK_BOT + 4, PH - 1):
                cv.px(x, y, m[1])
                cv.px(x + 1, y, m[0])
    elif under == "thin":
        for x in (7,):
            for y in range(DECK_BOT + 4, DECK_BOT + 9):
                cv.px(x, y, m[1])
    elif under == "stilts":
        for x in (2, 13):
            for y in range(DECK_BOT + 4, PH):
                cv.px(x, y, m[2] if y < PH - 3 else m[1])
                cv.px(x + 1, y, m[0])
        for y in range(DECK_BOT + 5, PH - 2):
            xx = 2 + (y - DECK_BOT - 5) * 11 // 7
            if xx <= 13:
                cv.px(xx, y, m[1])
    elif under == "trestle":
        for y in range(DECK_BOT + 4, PH):
            t = (y - DECK_BOT - 4) / (PH - DECK_BOT - 5)
            cv.px(round(1 + t * 13), y, m[2])
            cv.px(round(14 - t * 13), y, m[1])
        for x in (0, 15):
            for y in range(DECK_BOT + 4, PH):
                cv.px(x, y, m[1])
    elif under == "piers":
        s = P["stone"] if d["mat"] not in ("stone", "stone_cool", "sand") else m
        for y in range(DECK_BOT + 4, PH):
            for x in range(4, 12):
                k = (y - DECK_BOT - 4)
                col = s[2] if (x + (k // 3) * 2) % 4 else s[1]
                if k % 3 == 0:
                    col = s[1]
                if x == 4:
                    col = s[3]
                if x == 11:
                    col = s[0]
                cv.px(x, y, col)
    elif under == "arches":
        s = m
        for y in range(DECK_BOT + 4, PH):
            for x in range(0, 16):
                # one arch per cell: stone round a dark opening
                ax = (x - 7.5) / 6.5
                ay = (y - (PH + 1)) / 9.0
                inside = ax * ax + ay * ay < 1.0
                if inside:
                    col = (24, 18, 28, 150) # the dark under the arch, over water
                else:
                    k = y - DECK_BOT - 4
                    col = s[2] if (x + (k // 3 % 2) * 2) % 5 else s[1]
                    if k % 3 == 0:
                        col = s[1]
                    ring = ax * ax + ay * ay
                    if ring < 1.35:
                        col = s[3] # the voussoirs, lit
                cv.px(x, y, col)
        if d.get("moss"):
            for x in range(16):
                if h(x, 9, 13) < 0.4:
                    cv.px(x, DECK_BOT + 4, P["moss"][2])
                    if h(x, 9, 14) < 0.4:
                        cv.px(x, DECK_BOT + 5, P["moss"][1])
    # the deck's shadow on the water
    for x in range(0, 16):
        for y in range(PH - 3, PH):
            if cv.a[cv.oy + y, cv.ox + x, 3] == 0:
                cv.px(x, y, SHADOW)


# ---------------------------------------------------------------- pieces

def piece_across(cv, d, P, kind, layer):
    """One across piece (16 x 56) of `layer` ("base" or "front")."""
    x0, x1 = (3, 15) if kind == "w" else ((0, 12) if kind == "e" else (0, 15))
    posts_back = []
    posts_front = []
    if kind == "w":
        posts_back = posts_front = [3]
    elif kind == "e":
        posts_back = posts_front = [11]
    elif kind == "p" and d.get("post") is True:
        posts_back = posts_front = [7]
    elif kind in ("m", "p") and d.get("post_every"):
        posts_back = posts_front = [0]
    if layer == "base":
        under_across(cv, d, P, kind)
        deck_across(cv, d, P, kind, x0, x1)
        if kind == "w":
            for y in range(DECK_TOP, DECK_BOT):
                cv.px(x0, y, P[d["mat"]][1])
        if kind == "e":
            for y in range(DECK_TOP, DECK_BOT):
                cv.px(x1, y, P[d["mat"]][0])
        if d.get("moss") and d["rail"] is None:
            mo = P["moss"]
            for x in range(x0, x1 + 1):
                if h(x, 4, 15) < 0.3:
                    cv.px(x, DECK_TOP + 1, mo[2], top=True)
                if h(x, 5, 16) < 0.3:
                    cv.px(x, DECK_BOT - 2, mo[1])
        rail_line(cv, d, P, DECK_TOP + 1, x0, x1, posts_back, False)
        if d.get("post") == "flowers":
            planters(cv, d, P, DECK_TOP + 1, x0, x1)
        if kind == "p" and d.get("post") not in (None, True):
            feature(cv, d, P, DECK_TOP + 1, 8)
        if d.get("gates") and kind in ("w", "e"):
            gate(cv, d, P, kind, DECK_TOP + 1)
        if d["rail"] in ("rope", "rope_one") and kind in ("w", "e"):
            pass
        cv.outline(P["line"])
    else:
        if d["rail"] == "rope_one":
            return # one rope, on the back
        rail_line(cv, d, P, DECK_BOT - 1, x0, x1, posts_front, True)
        if d.get("post") == "flowers":
            planters(cv, d, P, DECK_BOT - 1, x0, x1)
        if kind == "p" and d.get("post") not in (None, True):
            feature(cv, d, P, DECK_BOT - 1, 8)
        if d.get("gates") and kind in ("w", "e"):
            gate(cv, d, P, kind, DECK_BOT - 1)
        cv.outline(P["line"])


def gate(cv, d, P, kind, base_y):
    # tall end posts with a cap, at the bridge's ends
    m = rail_mat(d, P)
    x = 3 if kind == "w" else 11
    for y in range(base_y - 18, base_y + 1):
        cv.px(x, y, m[3])
        cv.px(x + 1, y, m[1])
    cv.rect(x - 1, base_y - 20, x + 2, base_y - 19, m[4], top=True)
    cv.rect(x - 1, base_y - 18, x + 2, base_y - 18, m[1])


def piece_along(cv, d, P, kind):
    """One along piece (36 x 16)."""
    m = P[d["mat"]]
    deck_along(cv, d, P, kind)
    r = rail_mat(d, P)
    rail = d["rail"]
    y0 = 3 if kind == "n" else 0
    y1 = 12 if kind == "s" else 15
    for side in (0, 27):
        for y in range(y0, y1 + 1):
            if rail is None:
                cv.px(side + (4 if side == 0 else 0), y, m[1])
                continue
            if rail in ("parapet", "parapet_low"):
                for x in range(side, side + 5):
                    k = x - side
                    col = r[3] if k in (1, 2) else (r[4] if k == 0 and side == 0 else r[2])
                    if (y + (2 if k > 2 else 0)) % 5 == 0:
                        col = r[1]
                    cv.px(x, y, col, top=True)
                if d.get("moss") and h(side, y, 17) < 0.35:
                    cv.px(side + 2, y, P["moss"][2], top=True)
            elif rail == "curb":
                cv.px(side + 2, y, r[4], top=True)
                cv.px(side + 3, y, r[2])
                cv.px(side + (1 if side == 0 else 4), y, r[1])
            elif rail in ("rope", "rope_one"):
                if rail == "rope_one" and side == 27:
                    continue
                rr = P["rope"]
                cv.px(side + 2, y, rr[2] if y % 2 else rr[1], top=True)
            else:
                cv.px(side + 1, y, r[3], top=True)
                cv.px(side + 2, y, r[3], top=True)
                cv.px(side + 3, y, r[1])
                if d.get("post") == "flowers":
                    cv.px(side + 2, y, P["moss"][2] if y % 3 else P["moss"][3], top=True)
                    if h(side, y, 34) < 0.4:
                        cv.px(side + 1 + (y % 3), y, P["flower"][int(h(side, y, 35) * 3) % 3], top=True)
                if rail == "lattice" and y % 4 == 0:
                    cv.px(side + 2, y, r[2])
                if rail == "branch" and y % 5 == 2:
                    cv.px(side + (0 if side == 0 else 4), y, r[2])
        # posts at the ends and on p pieces
        post_ys = []
        if kind == "n":
            post_ys = [4]
        elif kind == "s":
            post_ys = [9]
        elif kind == "p" and rail is not None:
            post_ys = [6]
        elif kind == "m" and d.get("post_every") and rail is not None:
            post_ys = [0]
        if rail is None:
            post_ys = []
        for py in post_ys:
            if rail in ("parapet", "parapet_low", "curb"):
                cv.rect(side, py, side + 4, py + 3, r[4], top=True)
                cv.rect(side, py + 3, side + 4, py + 3, r[1])
            else:
                cv.rect(side + 1, py, side + 3, py + 2, r[4], top=True)
                cv.rect(side + 1, py + 3, side + 3, py + 3, r[1])
            if kind == "p" and d.get("post") == "lantern":
                fl = P["flame"]
                cv.rect(side + 1, py - 1, side + 3, py + 1, P["iron"][1])
                cv.px(side + 2, py, fl[1])
            if kind == "p" and d.get("post") == "flowers":
                fl = P["flower"]
                cv.px(side + 2, py + 1, P["moss"][2], top=True)
                cv.px(side + 1, py, fl[0], top=True)
                cv.px(side + 3, py + 2, fl[1], top=True)
        if d.get("gates") and kind in ("n", "s"):
            gy = 3 if kind == "n" else 9
            cv.rect(side, gy - 1, side + 4, gy + 3, r[4], top=True)
            cv.rect(side, gy + 3, side + 4, gy + 3, r[1])
    # the bridge's shadow on the water to its east
    for y in range(y0, 16):
        for x in range(32, 36):
            cv.px(x, y, (20, 12, 20, 60 - (x - 32) * 12))
    if kind == "s":
        for x in range(0, 32):
            if cv.a[cv.oy + 15, cv.ox + x, 3] == 0:
                cv.px(x, 15, SHADOW)
    cv.outline(P["line"])


def sheet(P):
    cv = Canvas(SHEET_W, ROW * len(DESIGNS))
    for i, d in enumerate(DESIGNS):
        y = i * ROW
        for k, kind in enumerate("wmpe"):
            cv.at(k * PW, y, PW, PH)
            piece_across(cv, d, P, kind, "base")
            cv.at(64 + k * PW, y, PW, PH)
            piece_across(cv, d, P, kind, "front")
        for k, kind in enumerate("nmps"):
            cv.at(128 + (k % 2) * VW, y + (k // 2) * VH, VW, VH)
            piece_along(cv, d, P, kind)
    return cv


def snow(cv):
    """Snow on every upward surface: thick at the edges of the deck and on
    the rails, trodden thin down the middle."""
    a = cv.a.copy()
    hgt, wid = cv.top.shape
    for y in range(hgt):
        for x in range(wid):
            if not cv.top[y, x] or a[y, x, 3] != 255:
                continue
            ry = (y % ROW)
            on_deck = DECK_TOP + 3 <= ry < DECK_BOT - 3 and x < 64
            keep = h(x, y, 21)
            if on_deck and 0.3 < (ry - DECK_TOP) / (DECK_BOT - DECK_TOP) < 0.7 and keep < 0.75:
                continue # the trodden middle
            if keep < 0.18:
                continue
            col = SNOW[2] if keep > 0.45 else SNOW[1]
            if y + 1 < hgt and not cv.top[y + 1, x] and a[y + 1, x, 3] == 255:
                col = SNOW[0]
            a[y, x] = col
    out = Canvas(wid, hgt)
    out.a = a
    return out


def preview(path):
    """Every design over a strip of water between banks, across (span 3) and
    along (span 3), on each sheet's ground and water."""
    farm = Image.open("assets/pack/farm/tilesets/farm_spring_summer.png").convert("RGBA")
    kits = {k: Image.open("assets/ai/bridges/bridges_%s.png" % k).convert("RGBA") for k in ("forest", "farm", "farm_winter")}
    cols = 4
    cell_w, cell_h = 7 * 16, 8 * 16
    rows = math.ceil(len(DESIGNS) / cols)
    out = Image.new("RGBA", (cols * cell_w * 2, rows * cell_h), (0, 0, 0, 255))
    grass = (106, 150, 84, 255)
    water = (88, 156, 190, 255)
    for i, d in enumerate(DESIGNS):
        for j, kit_name in enumerate(("forest", "farm")):
            kit = kits[kit_name]
            ox = ((i % cols) * 2 + j) * cell_w
            oy = (i // cols) * cell_h
            tile = Image.new("RGBA", (cell_w, cell_h), grass)
            # water: a north-south strip (x 32..79) and an east-west strip (y 72..111 left part)
            for y in range(0, 64):
                for x in range(32, 80):
                    tile.putpixel((x, y), water)
            y0 = i * ROW
            # across bridge at y 4 (deck rows 16..47), cells x 16..95
            for k, kind in enumerate("wmpme"):
                src = "wmpe".index(kind)
                piece = kit.crop((src * 16, y0, src * 16 + 16, y0 + 56))
                tile.alpha_composite(piece, (16 + k * 16, 4))
            for k, kind in enumerate("wmpme"):
                src = "wmpe".index(kind)
                piece = kit.crop((64 + src * 16, y0, 64 + src * 16 + 16, y0 + 56))
                tile.alpha_composite(piece, (16 + k * 16, 4))
            for y in range(74, 106):
                for x in range(0, 112):
                    tile.putpixel((x, y), water)
            for k, kind in enumerate("nmps"):
                piece = kit.crop((128 + (k % 2) * 36, y0 + (k // 2) * 16, 128 + (k % 2) * 36 + 36, y0 + (k // 2) * 16 + 16))
                tile.alpha_composite(piece, (40, 58 + k * 16))
            out.alpha_composite(tile, (ox, oy))
    out = out.resize((out.size[0] * 2, out.size[1] * 2), Image.NEAREST)
    out.save(path)


def main():
    import os
    os.makedirs("assets/ai/bridges", exist_ok=True)
    for name in ("forest", "farm"):
        cv = sheet(PALETTES[name])
        Image.fromarray(cv.a, "RGBA").save("assets/ai/bridges/bridges_%s.png" % name)
        if name == "farm":
            Image.fromarray(snow(cv).a, "RGBA").save("assets/ai/bridges/bridges_farm_winter.png")
    print("wrote assets/ai/bridges/bridges_{forest,farm,farm_winter}.png,", len(DESIGNS), "designs")
    if len(sys.argv) > 1:
        preview(sys.argv[1])
        print("preview", sys.argv[1])


if __name__ == "__main__":
    main()
