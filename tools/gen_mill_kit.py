#!/usr/bin/env python3
"""Draws the windmill interior kit (assets/ai/mill/mill_kit.png): the mill
machinery and mill clutter the Painted Lands packs do not have, in the Farm
– 4 Seasons sheet's own colors and outline weight (every color below is
taken from farm_spring_summer.png), on the 16 px grid.

  machine  16 frames, 64 x 112 (one loop: the wheel a quarter turn, the
           stone a sixth): the great spur wheel turning under the
           ceiling, the upright shaft, the hopper on its frame trickling
           grain into the eye, the runner stone turning on its wooden case
           (the hurst), a spout dribbling flour at the front
  sacks    a sack, a slumped sack, an open sack of flour, a stack of three
  ladder   up the wall to a trapdoor in the floor above
  stone    a spare millstone on its edge, leaning on the wall
  hook     the sack hoist's rope and hook, 3 frames of a slow swing
  flour    two spills of flour for the floor
  brake    the cap, 16 frames, 80 x 96: the brake wheel on the windshaft
           turning between its frame posts (a quarter turn per loop), the
           brake band over it, the wallower it drives turning on the top of
           the upright shaft, which goes down through the floor
  trap     the sack trap in the cap's floor: flaps open, the hoist rope up
  hatch    the ladder's top coming up through its hatch

  python3 tools/gen_mill_kit.py [out.png]

The rects are FarmTiles.MILL (scripts/farm_tiles.gd); keep them in step.
"""
import math
import sys

import numpy as np
from PIL import Image

OUT = sys.argv[1] if len(sys.argv) > 1 else "assets/ai/mill/mill_kit.png"


def c(h):
    return (int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16), 255)


# Farm sheet colors.
LINE = c("#42141b")        # crate and barrel outline
WOOD_D = c("#59362a")
WOOD_M = c("#684a37")
WOOD_L = c("#7d6349")
WOOD_H = c("#897154")
WOOD_X = c("#8b7b63")
TIMBER_D = c("#3d211a")    # the windmill's timbers
TIMBER = c("#523228")
TIMBER_L = c("#6c4e3a")
ST_LINE = c("#3f2534")     # rock outline
ST_D = c("#66584d")
ST_M = c("#80817f")
ST_L = c("#9e9c9a")
ST_H = c("#b7b4aa")
CL_H = c("#c1b7a2")        # plaster: sacking
CL_M = c("#b8ab8f")
CL_S = c("#b29f7c")
CL_D = c("#a58666")
CL_X = c("#836b4f")
FLOUR = c("#d0ccc7")
FLOUR_H = c("#d6d6e1")
GRAIN_H = c("#c4ac70")     # hay and wheat
GRAIN = c("#b99a5d")
GRAIN_S = c("#ad8547")
GRAIN_D = c("#a06e39")
IRON = c("#3f2534")
IRON_L = c("#5f405e")
CLEAR = (0, 0, 0, 0)

FRAMES = 16
MW, MH = 64, 112
W = 1280
H = 320
CAP_Y = 176 # the cap (the floor above): brake wheel frames, then the sack trap and the hatch
BW, BH = 80, 96


class Canvas:
    def __init__(self, w, h):
        self.a = np.zeros((h, w, 4), dtype=np.uint8)
        self.ox = 0
        self.oy = 0

    def at(self, ox, oy):
        self.ox, self.oy = ox, oy
        return self

    def px(self, x, y, col):
        x, y = int(round(x)) + self.ox, int(round(y)) + self.oy
        if 0 <= y < self.a.shape[0] and 0 <= x < self.a.shape[1]:
            self.a[y, x] = col

    def get(self, x, y):
        x, y = int(x) + self.ox, int(y) + self.oy
        return tuple(self.a[y, x])

    def rect(self, x0, y0, x1, y1, col):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.px(x, y, col)

    def hline(self, x0, x1, y, col):
        for x in range(x0, x1 + 1):
            self.px(x, y, col)

    def vline(self, x, y0, y1, col):
        for y in range(y0, y1 + 1):
            self.px(x, y, col)

    def line(self, x0, y0, x1, y1, col):
        n = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
        for i in range(n):
            t = i / max(1, n - 1)
            self.px(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, col)

    def outline(self, x0, y0, x1, y1, col):
        """Outline every opaque pixel in the box that touches a clear one
        (only pixels inside the box count, so a neighbor piece never bleeds
        in)."""
        src = self.a.copy()
        bx0, by0, bx1, by1 = x0 + self.ox, y0 + self.oy, x1 + self.ox, y1 + self.oy
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                X, Y = x + self.ox, y + self.oy
                if src[Y, X, 3] != 0:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = X + dx, Y + dy
                    if bx0 <= nx <= bx1 and by0 <= ny <= by1 and src[ny, nx, 3] != 0 and tuple(src[ny, nx]) != col:
                        self.a[Y, X] = col
                        break


def in_ellipse(x, y, cx, cy, rx, ry):
    return ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0


# ---------------------------------------------------------------- machine

def machine(cv, f):
    phase = f / FRAMES
    cx = 32
    # The great spur wheel under the ceiling, seen from above and the
    # front: an open wheel (rim, four arms, hub), cogs all round the rim,
    # a quarter turn per loop.
    wy, wrx, wry = 16, 26, 8
    turn = phase * math.pi / 2
    def ring(x, y):
        return in_ellipse(x, y, cx, wy, wrx, wry) and not in_ellipse(x, y, cx, wy, wrx - 4, wry - 2.5)
    for y in range(wy - wry - 2, wy + wry + 5):
        for x in range(cx - wrx - 2, cx + wrx + 3):
            # The rim's side under the front half.
            if y > wy and not ring(x, y) and (ring(x, y - 1) or ring(x, y - 2)) and not in_ellipse(x, y, cx, wy, wrx - 4, wry - 2.5):
                cv.px(x, y, TIMBER)
    for y in range(wy - wry - 2, wy + wry + 3):
        for x in range(cx - wrx - 2, cx + wrx + 3):
            if ring(x, y):
                a = math.atan2((y + 0.5 - wy) / wry, (x + 0.5 - cx) / wrx)
                cog = ((a - turn) / (2 * math.pi) * 24) % 1.0
                outer = not in_ellipse(x, y, cx, wy, wrx - 1.6, wry - 0.8)
                col = WOOD_L
                if outer:
                    col = WOOD_X if cog < 0.5 else TIMBER_L
                elif y < wy - wry + 2:
                    col = WOOD_H
                cv.px(x, y, col)
    # Arms: four, from the hub to the rim.
    for k in range(4):
        a = turn + k * math.pi / 2
        for i in range(4, wrx - 2):
            t = i / (wrx - 2)
            ex, ey = cx + math.cos(a) * (wrx - 2) * t, wy + math.sin(a) * (wry - 1) * t
            cv.px(ex, ey, WOOD_H)
            cv.px(ex, ey + 1, TIMBER)
    # The hub: an iron-bound block on the shaft.
    cv.rect(cx - 3, wy - 2, cx + 2, wy + 2, TIMBER_L)
    cv.hline(cx - 3, cx + 2, wy - 2, WOOD_H)
    cv.hline(cx - 3, cx + 2, wy + 2, IRON)
    cv.outline(0, 0, MW - 1, 30, LINE)

    # The upright shaft from the hub down to the stones (behind the
    # hopper): a squared post, its corners turning past.
    top, bottom = wy + 3, 74
    for y in range(top, bottom + 1):
        cols = [TIMBER_D, TIMBER, TIMBER_L, WOOD_L, TIMBER_L]
        shift = (f // 4) % 4
        for i in range(5):
            col = cols[(i + shift) % 5]
            if (i + shift) % 4 == 0:
                col = TIMBER_D
            cv.px(cx - 2 + i, y, col)
    for by in (top + 6, top + 22, bottom - 8):
        cv.hline(cx - 2, cx + 2, by, IRON)
        cv.hline(cx - 2, cx + 2, by + 1, IRON_L)
    cv.vline(cx - 3, top, bottom, LINE)
    cv.vline(cx + 3, top, bottom, LINE)

    # The hurst: the wooden case the stones sit on, its top seen from above
    # and its front face of upright boards.
    hx0, hx1 = 5, 58
    top_y0, face_y0, face_y1 = 78, 94, 110
    cv.rect(hx0, top_y0, hx1, face_y0 - 1, WOOD_M)
    cv.hline(hx0, hx1, top_y0, WOOD_X)
    for x in range(hx0, hx1 + 1, 9):
        cv.vline(x, top_y0 + 1, face_y0 - 1, WOOD_D)
    cv.rect(hx0, face_y0, hx1, face_y1, WOOD_D)
    cv.hline(hx0, hx1, face_y0, WOOD_L)
    for x in range(hx0 + 4, hx1, 6):
        cv.vline(x, face_y0 + 1, face_y1, TIMBER)
        cv.vline(x + 1, face_y0 + 2, face_y1 - 1, WOOD_M)
    cv.hline(hx0, hx1, face_y1 - 2, TIMBER)
    # Corner posts.
    for x in (hx0, hx1 - 2):
        cv.rect(x, face_y0, x + 2, face_y1, TIMBER)
        cv.vline(x + 1, face_y0, face_y1, TIMBER_L)

    # The runner stone: a squat stone disc on the hurst, its dressing
    # (furrows in six harps) turning; the bed stone under it shows as a rim.
    scx, scy, srx, sry, thick = 32, 85, 21, 7, 4
    for y in range(scy - sry - 1, scy + sry + thick + 2):
        for x in range(scx - srx - 2, scx + srx + 3):
            if in_ellipse(x, y - thick - 1, scx, scy, srx + 1, sry) and y > scy:
                cv.px(x, y, ST_D)          # the bed stone's edge
            if in_ellipse(x, y - thick, scx, scy, srx, sry) and y >= scy and not in_ellipse(x, y, scx, scy, srx, sry):
                cv.px(x, y, ST_M if x < scx + srx * 0.5 else ST_D)  # the runner's side
    for y in range(scy - sry - 1, scy + sry + 2):
        for x in range(scx - srx - 1, scx + srx + 2):
            if not in_ellipse(x, y, scx, scy, srx, sry):
                continue
            u, v = (x + 0.5 - scx) / srx, (y + 0.5 - scy) / sry
            r = math.hypot(u, v)
            th = math.atan2(v, u) - phase * 2 * math.pi / 6  # a sixth of a turn per loop
            harp = (th / (2 * math.pi) * 6) % 1.0
            col = ST_L
            if r > 0.28 and (harp < 0.1 or (r > 0.6 and 0.45 < harp < 0.52)):
                col = ST_D
            elif v < -0.55 or u < -0.8:
                col = ST_H
            elif v > 0.6:
                col = ST_M
            cv.px(x, y, col)
    # The eye.
    for y in range(scy - 2, scy + 2):
        for x in range(scx - 3, scx + 4):
            if in_ellipse(x, y, scx + 0.5, scy, 3.5, 2):
                cv.px(x, y, ST_LINE)
    cv.outline(0, 70, MW - 1, 96, ST_LINE)

    # The horse: two legs on the stone's rim holding the hopper.
    for lx, ex in ((14, 21), (50, 43)):
        cv.line(lx, 84, ex, 60, TIMBER)
        cv.line(lx + (1 if lx < 32 else -1), 84, ex + (1 if lx < 32 else -1), 60, TIMBER_L)
    cv.hline(18, 46, 61, TIMBER)
    cv.hline(18, 46, 62, TIMBER_D)
    # The hopper: a wooden funnel full of grain.
    for y in range(48, 70):
        t = (y - 48) / 21
        half = int(round(12 - t * 8))
        for x in range(cx - half, cx + half + 1):
            col = WOOD_M if x < cx + half - 2 else WOOD_D
            if (x - (cx - half)) % 5 == 0:
                col = WOOD_D
            cv.px(x, y, col)
        cv.px(cx - half, y, WOOD_L)
    cv.hline(cx - 12, cx + 12, 48, WOOD_X)
    for x in range(cx - 11, cx + 12):
        g = (x * 7 + f // 4) % 5
        cv.px(x, 49, GRAIN_H if g < 2 else GRAIN)
        cv.px(x, 50, GRAIN if g != 3 else GRAIN_S)
    # The shoe, and grain trickling from it into the eye.
    cv.rect(cx - 2, 70, cx + 4, 72, WOOD_D)
    cv.hline(cx - 2, cx + 4, 70, WOOD_L)
    for k in range(3):
        gy = 73 + (f + k * 3) % 8
        if gy < scy:
            cv.px(cx + 3, gy, GRAIN_H if k % 2 else GRAIN)
    cv.outline(0, 44, MW - 1, 76, LINE)

    # The spout at the front of the hurst, dribbling flour.
    cv.rect(10, 98, 14, 103, TIMBER_D)
    cv.rect(11, 99, 13, 102, LINE)
    for k in range(3):
        fy = 104 + (f + k * 3) % 8
        cv.px(12 - (k == 1), fy, FLOUR if k != 2 else FLOUR_H)
    cv.outline(0, 76, MW - 1, MH - 1, LINE)


# ---------------------------------------------------------------- sacks

def sack_shape(cv, x0, y0, w, h, open_top=False, lean=0):
    """A burlap sack: a bulging body, a gathered neck tied off, a frill."""
    cx = x0 + w / 2
    body_top = y0 + (3 if open_top else 5)
    for y in range(body_top, y0 + h):
        t = (y - body_top) / max(1, (y0 + h - 1 - body_top))
        bulge = math.sin(min(1.0, 0.25 + t * 0.95) * math.pi * 0.62)
        half = (w / 2 - 0.5) * (0.62 + 0.38 * bulge)
        if t > 0.86:
            half -= (t - 0.86) * w * 0.9
        shift = lean * (1 - t)
        for x in range(x0, x0 + w):
            dx = x + 0.5 - (cx + shift)
            if abs(dx) <= half:
                u = dx / max(1.0, half)
                col = CL_M
                if u < -0.45 and t < 0.75:
                    col = CL_H
                if u > 0.5 or t > 0.82:
                    col = CL_S
                if u > 0.78 and t > 0.3:
                    col = CL_D
                cv.px(x, y, col)
    # Seams and creases.
    cv.px(cx - 2 + lean, body_top + 4, CL_S)
    cv.px(cx - 1 + lean, body_top + 5, CL_S)
    cv.px(cx + 2, y0 + h - 4, CL_D)
    if open_top:
        # Rolled-down rim and the flour inside.
        for x in range(int(cx - w / 2 + 2), int(cx + w / 2 - 1)):
            cv.px(x, body_top - 1, CL_S)
            cv.px(x, body_top, FLOUR if x % 3 else FLOUR_H)
            cv.px(x, body_top + 1, FLOUR)
        cv.hline(int(cx - w / 2 + 2), int(cx + w / 2 - 2), body_top + 2, CL_D)
    else:
        # The neck, the tie, the frill above it.
        nx = int(cx + lean)
        cv.rect(nx - 1, y0 + 2, nx + 1, body_top, CL_S)
        cv.hline(nx - 2, nx + 2, y0 + 3, TIMBER_L)
        cv.px(nx + 2, y0 + 4, TIMBER_L)
        cv.hline(nx - 2, nx + 2, y0 + 1, CL_M)
        cv.px(nx - 3, y0 + 1, CL_H)
        cv.px(nx + 3, y0 + 1, CL_S)
        cv.hline(nx - 1, nx + 1, y0, CL_H)


def sacks(cv):
    oy = MH
    # sack (16 x 20), slumped sack (20 x 16), open sack (16 x 20).
    sack_shape(cv.at(0, oy), 1, 1, 14, 18)
    cv.outline(0, 0, 15, 19, CL_X)
    sack_shape(cv.at(16, oy), 1, 3, 18, 13, lean=2)
    cv.outline(0, 0, 19, 19, CL_X)
    sack_shape(cv.at(36, oy), 1, 2, 14, 17, open_top=True)
    cv.outline(0, 0, 15, 19, CL_X)
    # A stack of three (32 x 28): two lying side by side, one on top.
    cv.at(52, oy)
    sack_shape(cv, 1, 11, 15, 16)
    sack_shape(cv, 15, 12, 15, 15, lean=-1)
    cv.outline(0, 0, 31, 27, CL_X)
    sack_shape(cv, 8, 1, 15, 15, lean=1)
    cv.outline(0, 0, 31, 27, CL_X)
    cv.at(0, 0)


# ---------------------------------------------------------------- the rest

def ladder(cv):
    cv.at(88, MH)
    # A trapdoor in the floor above and the ladder up to it (16 x 60).
    cv.rect(1, 0, 14, 4, LINE)
    cv.rect(2, 1, 13, 3, TIMBER_D)
    for x in (1, 12):
        cv.rect(x, 2, x + 2, 59, WOOD_M)
        cv.vline(x, 2, 59, WOOD_L)
        cv.vline(x + 2, 2, 59, TIMBER)
    for y in range(8, 58, 7):
        cv.hline(4, 11, y, WOOD_L)
        cv.hline(4, 11, y + 1, TIMBER)
    cv.outline(0, 0, 15, 61, LINE)
    cv.at(0, 0)


def spare_stone(cv):
    # A millstone on its edge (30 x 30): face, eye, furrows, a thick rim.
    cv.at(106, MH)
    cx, cy, r = 14, 15, 12.5
    for y in range(30):
        for x in range(30):
            if (x + 0.5 - cx - 2.5) ** 2 / (r ** 2) + (y + 0.5 - cy) ** 2 / (r ** 2) <= 1.0:
                cv.px(x, y, ST_D)
    for y in range(30):
        for x in range(30):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            d = math.hypot(dx, dy)
            if d > r:
                continue
            th = math.atan2(dy, dx)
            harp = (th / (2 * math.pi) * 6) % 1.0
            col = ST_L
            if d > 4 and harp < 0.1:
                col = ST_M
            if dx + dy < -12:
                col = ST_H
            if dx + dy > 13:
                col = ST_M
            cv.px(x, y, col)
    for y in range(13, 18):
        for x in range(12, 17):
            cv.px(x, y, ST_LINE)
    cv.outline(0, 0, 31, 29, ST_LINE)
    cv.at(0, 0)


def hook(cv):
    # The sack hoist: a rope down from the ceiling, an iron hook (8 x 44),
    # three frames of a slow swing.
    for f, sway in enumerate((-1, 0, 1)):
        cv.at(140 + f * 8, MH)  # 8 x 44
        for y in range(0, 36):
            t = y / 35
            x = 3.5 + sway * t * t
            cv.px(x, y, CL_D if y % 3 else CL_S)
            cv.px(x + 1, y, TIMBER_L if y % 3 != 1 else CL_X)
        hx = 3.5 + sway
        for y, xs in ((36, (0, 1)), (37, (0, 1)), (38, (-1, 0)), (39, (-2, -1)), (40, (-2,)), (41, (-2, -1)), (42, (-1, 0, 1)), (41, (2,)), (40, (2,)), (39, (2,))):
            for dx in xs:
                cv.px(hx + dx, y, IRON if dx < 1 else IRON_L)
    cv.at(0, 0)


def flour(cv):
    # Two spills (16 x 16): a low heap of flour with a ragged, thinning edge
    # (a lighter top, the sacking tone where it is thinnest).
    bayer = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
    for k, (cx, cy, rx, ry) in enumerate(((8, 9, 6.5, 4.5), (7.5, 8.5, 5.5, 5))):
        cv.at(164 + k * 16, MH)
        for y in range(16):
            for x in range(16):
                a = math.atan2(y + 0.5 - cy, x + 0.5 - cx)
                wob = 1.0 + 0.16 * math.sin(a * 3 + k * 2.1) + 0.08 * math.sin(a * 5 + 1.3)
                d = math.hypot((x + 0.5 - cx) / (rx * wob), (y + 0.5 - cy) / (ry * wob))
                if d <= 0.78:
                    col = FLOUR
                    if d < 0.45 and y + 0.5 < cy:
                        col = FLOUR_H
                    if y + 0.5 > cy + ry * 0.45:
                        col = CL_H
                    cv.px(x, y, col)
                elif d <= 1.05 and bayer[(y % 4) * 4 + x % 4] / 16 < (1.05 - d) * 3.2:
                    cv.px(x, y, CL_H)
    cv.at(0, 0)


# ---------------------------------------------------------------- the cap

def brake(cv, f):
    phase = f / FRAMES
    turn = phase * math.pi / 2
    cx, cy, R = 40, 44, 30
    # The frame: two posts and the beam over the wheel (behind it).
    for x0 in (2, 72):
        cv.rect(x0, 12, x0 + 5, BH - 3, TIMBER)
        cv.vline(x0 + 1, 12, BH - 3, TIMBER_L)
        cv.vline(x0 + 5, 12, BH - 3, TIMBER_D)
    cv.rect(2, 6, 77, 11, TIMBER)
    cv.hline(2, 77, 6, TIMBER_L)
    cv.hline(2, 77, 11, TIMBER_D)
    # The wheel: a rim with cogs all round, four arms, the hub on the
    # windshaft's end.
    for y in range(cy - R - 3, cy + R + 4):
        for x in range(cx - R - 3, cx + R + 4):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if R - 5 <= d <= R:
                a = math.atan2(y + 0.5 - cy, x + 0.5 - cx)
                lit = math.cos(a + 2.4)          # light from the upper left
                col = WOOD_L
                if lit > 0.45:
                    col = WOOD_H
                elif lit < -0.45:
                    col = TIMBER_L
                if d > R - 1.6:
                    cog = ((a - turn) / (2 * math.pi) * 32) % 1.0
                    col = WOOD_X if cog < 0.5 else TIMBER
                cv.px(x, y, col)
    for k in range(32):
        a = turn + (k + 0.25) * 2 * math.pi / 32
        tx_, ty_ = -math.sin(a), math.cos(a)
        for r, col in ((R + 0.8, WOOD_M), (R + 1.8, TIMBER_L)):
            for t in (-0.7, 0.0, 0.7):
                cv.px(cx + math.cos(a) * r + tx_ * t, cy + math.sin(a) * r + ty_ * t, col)
    for k in range(4):
        a = turn + k * math.pi / 2
        for i in range(5, R - 4):
            ex, ey = cx + math.cos(a) * i, cy + math.sin(a) * i
            nx, ny = -math.sin(a), math.cos(a)
            cv.px(ex, ey, WOOD_H)
            cv.px(ex + nx, ey + ny, WOOD_M)
            cv.px(ex - nx, ey - ny, TIMBER_L)
    cv.rect(cx - 4, cy - 4, cx + 4, cy + 4, TIMBER_L)
    cv.hline(cx - 4, cx + 4, cy - 4, IRON)
    cv.hline(cx - 4, cx + 4, cy + 4, IRON)
    cv.vline(cx - 4, cy - 4, cy + 4, IRON)
    cv.vline(cx + 4, cy - 4, cy + 4, IRON)
    cv.rect(cx - 1, cy - 1, cx + 1, cy + 1, TIMBER_D)
    # The brake band hugging the top of the rim.
    for t in range(0, 61):
        a = math.radians(205 + t * 2.15)
        for r, col in ((R + 3, TIMBER_D), (R + 4, TIMBER)):
            cv.px(cx + math.cos(a) * r, cy + math.sin(a) * r, col)
    # The wallower under the wheel, turning on the shaft's top.
    wy = cy + R + 3
    for y in range(wy, wy + 9):
        for x in range(cx - 9, cx + 10):
            top = ((x + 0.5 - cx) / 9.0) ** 2 + ((y + 0.5 - wy - 1.5) / 2.5) ** 2 <= 1
            bot = ((x + 0.5 - cx) / 9.0) ** 2 + ((y + 0.5 - wy - 7) / 2.5) ** 2 <= 1
            if top or bot:
                cv.px(x, y, WOOD_L if top else TIMBER)
            elif wy + 2 <= y <= wy + 7 and abs(x - cx) <= 8:
                stave = (x - cx + 9 + f % 4) % 4 == 0
                cv.px(x, y, TIMBER_D if stave else (TIMBER_L if x < cx + 4 else TIMBER))
    # The upright shaft from the wallower down through the floor.
    for y in range(wy + 9, BH - 2):
        cols = [TIMBER_D, TIMBER, TIMBER_L, WOOD_L, TIMBER_L]
        for i in range(5):
            col = cols[(i + (f // 4) % 4) % 5]
            if (i + (f // 4) % 4) % 4 == 0:
                col = TIMBER_D
            cv.px(cx - 2 + i, y, col)
    for x in range(cx - 6, cx + 7):
        for y in range(BH - 3, BH):
            if ((x + 0.5 - cx) / 6.5) ** 2 + ((y + 0.5 - BH + 1.5) / 1.8) ** 2 <= 1:
                cv.px(x, y, ST_LINE)
    cv.outline(0, 0, BW - 1, BH - 1, LINE)


def trap(cv):
    # The sack trap (40 x 48): its flaps open flat either side of the hole,
    # the hoist rope rising out of it to the ceiling.
    cv.at(0, CAP_Y + BH)
    cv.rect(8, 34, 31, 45, TIMBER_D)
    cv.rect(10, 36, 29, 44, LINE)
    for x0, x1 in ((0, 7), (32, 39)):
        cv.rect(x0, 34, x1, 45, WOOD_M)
        for x in range(x0 + 2, x1, 3):
            cv.vline(x, 35, 44, WOOD_D)
        cv.hline(x0, x1, 34, WOOD_H)
        cv.hline(x0, x1, 39, WOOD_L)
    for y in range(0, 41):
        cv.px(19, y, CL_D if y % 3 else CL_S)
        cv.px(20, y, TIMBER_L if y % 3 != 1 else CL_X)
    cv.outline(0, 0, 39, 47, LINE)
    cv.at(0, 0)


def hatch(cv):
    # The ladder's top coming up through its hatch (16 x 32).
    cv.at(40, CAP_Y + BH)
    cv.rect(0, 20, 15, 31, TIMBER)
    cv.rect(2, 22, 13, 30, LINE)
    cv.hline(0, 15, 20, WOOD_L)
    for x in (3, 11):
        cv.rect(x, 0, x + 1, 27, WOOD_M)
        cv.vline(x, 0, 27, WOOD_L)
    for y in (4, 11, 18):
        cv.hline(5, 10, y, WOOD_L)
        cv.hline(5, 10, y + 1, TIMBER)
    cv.outline(0, 0, 15, 31, LINE)
    cv.at(0, 0)


def main():
    cv = Canvas(W, H)
    for f in range(FRAMES):
        cv.at(f * MW, 0)
        machine(cv, f)
    cv.at(0, 0)
    sacks(cv)
    ladder(cv)
    spare_stone(cv)
    hook(cv)
    flour(cv)
    for f in range(FRAMES):
        cv.at(f * BW, CAP_Y)
        brake(cv, f)
    cv.at(0, 0)
    trap(cv)
    hatch(cv)
    Image.fromarray(cv.a, "RGBA").save(OUT)
    print("wrote", OUT)


if __name__ == "__main__":
    main()
