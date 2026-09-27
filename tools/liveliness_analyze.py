#!/usr/bin/env python3
"""Liveliness calibration: measure captured frames and fit the proxy.

  watch <dir>   process views as tools/liveliness_capture.tscn writes them:
                measure each view's frames, save the result, delete the raw
                frames; stop when the capture writes ALL_DONE.
  fit <dir>     fit the proxy weights on the calibration maps, test them on
                the held-back maps, write tools/liveliness_coef.json and
                docs/liveliness-calibration.md.

<dir> is the capture folder (.liveliness). Motion is measured on world
pixels: a pixel "moves" between two frames when any channel changes by more
than THRESHOLD (out of 255). A block's motion is the share of its pixels
that move per frame (8 fps), in percent.
"""
import json
import os
import sys
import time

import numpy as np
from scipy.optimize import nnls
from scipy.stats import spearmanr

THRESHOLD = 8
# Cloud shadows: sheet deep-grass green at alpha 0.16, blended over the
# scene. A pixel their rim crosses moves exactly 16 % toward (or back from)
# that green; those changes are counted apart as cloud motion.
SHADE = np.array([23, 63, 62], np.float32)
SHADE_A = 0.16
SHADE_TOL = 2.6

# The proxy's features, and which observed counts each one stands for.
FEATURES = ["leaves", "water_anim", "rings", "reeds", "sparkles", "flames", "glow", "smoke",
            "butterflies", "dragonflies", "fireflies", "streak", "animals"]  # cloud shadows are a separate background
STATIC = ["water_anim", "reeds", "sparkles", "flames", "glow"]  # deterministic: feature = what is there
OBSERVED = {  # observed count -> feature it is expected from
    "leaves_air": "leaves", "leaves_rest": "leaves", "streak_px": "streak", "rings": "rings",
    "drops": "rings", "butterflies": "butterflies", "dragonflies": "dragonflies",
    "fireflies": "fireflies", "smoke": "smoke", "animals": "animals",
}
# Local motion below this (percent of a block's pixels per frame, about two
# small things moving at once in a 6x6-cell block) counts as quiet.
QUIET = 0.05
COLUMNS = STATIC + list(OBSERVED)


_SHEET = None


def walker_mask(h, w, entry):
    """Opaque pixels of the walker sprite (16x32 cells of the Painted Lands
    character sheet, feet on row 31) at its logged position, grown by one
    pixel, so the walker's own movement is not counted as scene motion."""
    global _SHEET
    if _SHEET is None:
        from PIL import Image
        _SHEET = np.array(Image.open("assets/pack/character_sprite_sheet.png").convert("RGBA"))[:, :, 3] > 0
    x, y, f = entry
    cell = _SHEET[(f // 6) * 32:(f // 6) * 32 + 32, (f % 6) * 16:(f % 6) * 16 + 16]
    m = np.zeros((h, w), bool)
    ox, oy = int(np.floor(x)) - 8, int(np.floor(y)) - 31
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            ys, xs = np.nonzero(cell)
            ys, xs = ys + oy + dy, xs + ox + dx
            ok = (ys >= 0) & (ys < h) & (xs >= 0) & (xs < w)
            m[ys[ok], xs[ok]] = True
    return m


def measure(raw_path, meta):
    w, h = meta["size"]
    n = meta["frames"]
    frames = np.fromfile(raw_path, dtype=np.uint8)
    n = min(n, frames.size // (w * h * 3))
    frames = frames[: n * w * h * 3].reshape(n, h, w, 3)
    bx, by = meta["blocks_xy"]
    b = meta["block_px"]
    motion = np.zeros(bx * by)
    reach = np.zeros(bx * by)
    still = np.zeros(bx * by)
    cloud = np.zeros(bx * by)
    moved = np.zeros((n - 1, bx * by))
    clouded = np.zeros((n - 1, bx * by))
    reached = np.zeros((h, w), bool)
    view_motion = view_cloud = 0.0
    for i in range(n - 1):
        a = frames[i].astype(np.float32)
        c = frames[i + 1].astype(np.float32)
        d = np.abs(c - a).max(axis=2) > THRESHOLD
        enter = (np.abs(c - (a + SHADE_A * (SHADE - a))) <= SHADE_TOL).all(axis=2)
        leave = (np.abs(a - (c + SHADE_A * (SHADE - c))) <= SHADE_TOL).all(axis=2)
        cl = d & (enter | leave)
        d &= ~cl
        if "walker" in meta:
            wm = walker_mask(h, w, meta["walker"][i]) | walker_mask(h, w, meta["walker"][i + 1])
            d &= ~wm
            cl &= ~wm
        reached |= d
        view_motion += d.mean()
        view_cloud += cl.mean()
        for j in range(bx * by):
            x, y = j % bx, j // bx
            moved[i, j] = d[y * b:(y + 1) * b, x * b:(x + 1) * b].mean()
            clouded[i, j] = cl[y * b:(y + 1) * b, x * b:(x + 1) * b].mean()
    dt = 1.0 / meta["fps"]
    for j in range(bx * by):
        x, y = j % bx, j // bx
        motion[j] = moved[:, j].mean() * 100.0
        cloud[j] = clouded[:, j].mean() * 100.0
        reach[j] = reached[y * b:(y + 1) * b, x * b:(x + 1) * b].mean() * 100.0
        # Longest stretch with not one pixel moving.
        run = best = 0
        for m in moved[:, j]:
            run = run + 1 if m == 0 else 0
            best = max(best, run)
        still[j] = best * dt
    # motion, reach, and still count local motion only (not cloud rims).
    return {"motion": motion.tolist(), "cloud": cloud.tolist(), "reach": reach.tolist(), "still": still.tolist(),
            "view_motion": view_motion / max(1, n - 1) * 100.0, "view_cloud": view_cloud / max(1, n - 1) * 100.0,
            "view_reach": reached.mean() * 100.0}


def watch(folder):
    raw = os.path.join(folder, "raw")
    out = os.path.join(folder, "results")
    os.makedirs(out, exist_ok=True)
    while True:
        names = sorted(f for f in os.listdir(raw) if f.endswith(".json"))
        for f in names:
            stem = f[:-5]
            meta = json.load(open(os.path.join(raw, f)))
            t0 = time.time()
            meta["measured"] = measure(os.path.join(raw, stem + ".rgb"), meta)
            json.dump(meta, open(os.path.join(out, f), "w"))
            os.remove(os.path.join(raw, stem + ".rgb"))
            os.remove(os.path.join(raw, f))
            print(f"{stem}: r{meta['recipe']} {meta['recipe_name']}, local motion {meta['measured']['view_motion']:.2f}%, cloud {meta['measured']['view_cloud']:.2f}%, "
                  f"{meta['frames']} frames, {time.time() - t0:.1f}s", flush=True)
        if not names and os.path.exists(os.path.join(raw, "ALL_DONE")):
            print("watch: all done", flush=True)
            return
        time.sleep(2)


def load(folder):
    rows = []
    for f in sorted(os.listdir(os.path.join(folder, "results"))):
        meta = json.load(open(os.path.join(folder, "results", f)))
        for j, blk in enumerate(meta["blocks"]):
            rows.append({"map": meta["map"], "recipe": meta["recipe"], "name": meta["recipe_name"],
                         "holdout": meta["holdout"], "view": meta["view"], "block": j, "cell": blk["cell"],
                         "features": blk["features"], "observed": blk["observed"],
                         "motion": meta["measured"]["motion"][j], "cloud": meta["measured"]["cloud"][j], "reach": meta["measured"]["reach"][j],
                         "still": meta["measured"]["still"][j], "wind": meta["wind"]})
    return rows


def column(r, c):
    return r["features"][c] if c in STATIC else r["observed"].get(c, 0.0)


def fit(folder):
    rows = load(folder)
    cal = [r for r in rows if not r["holdout"]]
    hold = [r for r in rows if r["holdout"]]
    y = np.array([r["motion"] for r in cal])
    # Stage 1: pixel motion per unit of each effect actually on screen.
    X = np.array([[column(r, c) for c in COLUMNS] for r in cal])
    scale = np.maximum(X.max(axis=0), 1e-9)
    a, _ = nnls(X / scale, y)
    a = a / scale
    pred1 = X @ a
    r2_1 = 1 - ((y - pred1) ** 2).sum() / ((y - y.mean()) ** 2).sum()
    # Stage 2: how many of each effect the terrain features predict (ratio
    # of sums over the calibration blocks), then weights on the features.
    ratio = {}
    for c, feat in OBSERVED.items():
        fs = sum(r["features"][feat] for r in cal)
        ratio[c] = sum(r["observed"].get(c, 0.0) for r in cal) / fs if fs > 0 else 0.0
    weights = {f: 0.0 for f in FEATURES}
    for c, coef in zip(COLUMNS, a):
        if c in STATIC:
            weights[c] += coef
        else:
            weights[OBSERVED[c]] += coef * ratio[c]

    def predict(r):
        return sum(weights[f] * r["features"][f] for f in FEATURES)

    def score(rs):
        m = np.array([r["motion"] for r in rs])
        p = np.array([predict(r) for r in rs])
        rho = spearmanr(m, p).correlation
        mae = np.abs(m - p).mean()
        r2 = 1 - ((m - p) ** 2).sum() / ((m - m.mean()) ** 2).sum()
        # Views: the window-level score is the mean of its blocks.
        views = {}
        for r, pp in zip(rs, p):
            views.setdefault((r["map"], r["view"]), []).append((r["motion"], pp))
        vm = np.array([np.mean([x[0] for x in v]) for v in views.values()])
        vp = np.array([np.mean([x[1] for x in v]) for v in views.values()])
        vrel = np.abs(vm - vp) / np.maximum(vm, 1e-9)
        # Does the proxy find the same quiet blocks? Bottom quarter overlap.
        q_m = m < QUIET
        q_p = p < QUIET
        quiet_hit = (q_m & q_p).sum() / max(1, q_m.sum())
        false_quiet = (q_p & ~q_m).sum() / max(1, q_p.sum())
        return {"blocks": len(rs), "spearman": rho, "mae": mae, "r2": r2, "views": len(views),
                "view_spearman": spearmanr(vm, vp).correlation if len(views) > 2 else float("nan"),
                "view_rel_err_median": float(np.median(vrel)), "view_rel_err_max": float(vrel.max()),
                "quiet_overlap": quiet_hit, "false_quiet": false_quiet, "quiet_share": q_m.mean(), "mean_motion": m.mean(), "mean_pred": p.mean()}

    s_cal = score(cal)
    s_hold = score(hold) if hold else None
    # Per-map residuals, to see which kind of map the proxy misjudges.
    per_map = []
    for mid in sorted({r["map"] for r in rows}):
        rs = [r for r in rows if r["map"] == mid]
        m = np.mean([r["motion"] for r in rs])
        p = np.mean([predict(r) for r in rs])
        per_map.append({"map": mid, "recipe": rs[0]["recipe"], "name": rs[0]["name"], "holdout": rs[0]["holdout"],
                        "measured": m, "predicted": p, "cloud": np.mean([r["cloud"] for r in rs]),
                        "quiet": np.mean([r["motion"] < QUIET for r in rs]), "reach": np.mean([r["reach"] for r in rs]),
                        "still_max": max(r["still"] for r in rs)})
    # Contribution of each feature to the measured motion on calibration maps.
    share = {f: float(np.mean([weights[f] * r["features"][f] for r in cal])) for f in FEATURES}
    total = sum(share.values()) or 1.0
    quiet = QUIET
    cloud_bg = float(np.mean([r["cloud"] for r in cal]))
    coef = {"threshold": THRESHOLD, "unit": "percent of world pixels moving per frame at 8 fps",
            "weights": weights, "quiet": quiet, "cloud_background": cloud_bg, "stage1": dict(zip(COLUMNS, a.tolist())), "ratio": ratio,
            "calibration_maps": sorted({r["map"] for r in cal}), "holdout_maps": sorted({r["map"] for r in hold})}
    json.dump(coef, open("tools/liveliness_coef.json", "w"), indent=2)
    report(s_cal, s_hold, r2_1, weights, share, total, per_map, quiet, cloud_bg)
    print(json.dumps({"stage1_r2": r2_1, "calibration": s_cal, "holdout": s_hold}, indent=1, default=float))
    for pm in per_map:
        print(f"{pm['map']} r{pm['recipe']:>2} {pm['name']:<16} {'HOLD' if pm['holdout'] else '    '} "
              f"measured {pm['measured']:.2f}% predicted {pm['predicted']:.2f}% reach {pm['reach']:.1f}% "
              f"quiet blocks {pm['quiet'] * 100:.0f}% cloud {pm['cloud']:.2f}% longest still {pm['still_max']:.1f}s")


def report(s_cal, s_hold, r2_1, weights, share, total, per_map, quiet, cloud_bg):
    def fmt(s):
        return (f"| {s['blocks']} blocks / {s['views']} views | {s['spearman']:.2f} | {s['r2']:.2f} | {s['mae']:.2f} "
                f"| {s['view_spearman']:.2f} | {s['view_rel_err_median'] * 100:.0f} % (max {s['view_rel_err_max'] * 100:.0f} %) "
                f"| {s['quiet_overlap'] * 100:.0f} % ({s['false_quiet'] * 100:.0f} % false) |")
    lines = [
        "# Liveliness calibration",
        "",
        "Generated by `tools/liveliness_analyze.py fit` from the rendered capture",
        "(`tools/liveliness_capture.tscn`). Motion is the share of world pixels",
        f"that change by more than {THRESHOLD}/255 between frames at 8 fps, in",
        "percent, measured per 6x6-cell block (96x96 px). The walker is hidden, so",
        "this is the scene moving on its own. Pixels a cloud shadow's rim crosses",
        "(an exact 16 % step toward the shadow green) are counted apart: clouds go",
        "wherever the wind takes them, so they are a map-wide background, not",
        "something the terrain decides. Motion below means local motion.",
        "",
        f"Stage 1 (motion from the effects actually on screen): R² {r2_1:.2f}.",
        "",
        "| Set | Size | Block Spearman | Block R² | Block MAE (pts) | View Spearman | View error, median | Quiet blocks found |",
        "|---|---|---|---|---|---|---|---|",
        "| Calibration " + fmt(s_cal),
    ]
    if s_hold:
        lines.append("| Held back " + fmt(s_hold))
    lines += ["", "## Weights", "", "| Feature | Weight | Share of motion (calibration maps) |", "|---|---|---|"]
    for f in FEATURES:
        lines.append(f"| {f} | {weights[f]:.4g} | {share[f] / total * 100:.1f} % |")
    lines += ["", f"Quiet: local motion under {quiet:.2f} % of a block's pixels per frame.",
              f"Cloud shadow background: {cloud_bg:.2f} % on average (on top of local motion).", "",
              "## Maps", "", "| Map | Recipe | Set | Measured | Predicted | Quiet blocks | Cloud | Reach | Longest still |",
              "|---|---|---|---|---|---|---|---|---|"]
    for pm in per_map:
        lines.append(f"| {pm['map']} | {pm['recipe']} {pm['name']} | {'held back' if pm['holdout'] else 'calibration'} "
                     f"| {pm['measured']:.2f} % | {pm['predicted']:.2f} % | {pm['quiet'] * 100:.0f} % | {pm['cloud']:.2f} % "
                     f"| {pm['reach']:.1f} % | {pm['still_max']:.1f} s |")
    open("docs/liveliness-calibration.md", "w").write("\n".join(lines) + "\n")


def walkcmp(folder):
    """Walking vs at rest, view by view: .liveliness_walk results against the
    .liveliness capture of the same map and view."""
    rest = {}
    for f in os.listdir(os.path.join(folder, "results")):
        m = json.load(open(os.path.join(folder, "results", f)))
        rest[(m["map"], m["view"])] = m
    walk = os.path.join(".liveliness_walk", "results")
    rows = {}
    for f in sorted(os.listdir(walk)):
        m = json.load(open(os.path.join(walk, f)))
        r = rest.get((m["map"], m["view"]))
        if r is None:
            continue
        e = rows.setdefault(m["map"], {"name": m["recipe_name"], "recipe": m["recipe"], "rest": [], "walk": [], "rest_still": [], "walk_still": []})
        e["rest"].append(r["measured"]["view_motion"])
        e["walk"].append(m["measured"]["view_motion"])
        e["rest_still"].append(np.mean([x < QUIET for x in r["measured"]["motion"]]))
        e["walk_still"].append(np.mean([x < QUIET for x in m["measured"]["motion"]]))
    out = []
    for mid, e in sorted(rows.items()):
        out.append({"map": mid, "recipe": e["recipe"], "name": e["name"], "rest": float(np.mean(e["rest"])),
                    "walk": float(np.mean(e["walk"])), "rest_still": float(np.mean(e["rest_still"]) * 100),
                    "walk_still": float(np.mean(e["walk_still"]) * 100), "views": len(e["rest"])})
        o = out[-1]
        print(f"{mid} r{o['recipe']:>2} {o['name']:<16} at rest {o['rest']:.3f}%  walking {o['walk']:.3f}%  "
              f"x{o['walk'] / max(o['rest'], 1e-9):.1f}  still blocks {o['rest_still']:.0f}% -> {o['walk_still']:.0f}%")
    json.dump(out, open(os.path.join(".liveliness_walk", "compare.json"), "w"), indent=1)


if __name__ == "__main__":
    {"watch": watch, "fit": fit, "walkcmp": walkcmp}[sys.argv[1]](sys.argv[2])
