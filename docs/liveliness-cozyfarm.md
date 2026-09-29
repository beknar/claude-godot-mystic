# Liveliness: cozy farm animals

The Painted Lands cozy farm randomizer (`cozy_animals = true`) against the
same maps with the drawn animals, measured 2026-09-28/29 with today's code:

- **Slow sampling:** `tools/liveliness_capture.tscn` (rendered, walker
  hidden, 6 views x 25 s at 8 fps per map), measured by
  `tools/liveliness_analyze.py watch`; 18 maps (the calibration plan).
- **Exhaustive walker:** `tools/walker_test.tscn` with a window (the walker
  walks each view past the animals, 6 views x 25 s, frames measured), 13
  maps; plus the headless walker counts on 30 maps (120000-120029).
- **Fast:** `tools/liveliness.gd` (the calibrated proxy) on 30 maps.

Both runs use the tools' new `cozy` and `out=<dir>` options. The results
recorded on 2026-09-27 (`.liveliness`, `.liveliness_walk`) are listed for
reference only: since then every map id builds another recipe (`id % 33`),
and grass waves, drifters, streams, ponds, and the liveliness floor were
added, so they are not the baseline.

Motion is the share of pixels changing per frame (%), local (cloud
shadows apart). Quiet: blocks under 0.05 %.

## Summary

| Measure | Recorded 09-27 (reference) | Drawn animals | Cozy farm animals | Change |
|---|---|---|---|---|
| Slow: local motion, median of maps (%) | 0.21 | 0.49 | 0.59 | +20 % |
| Slow: weakest view, median (%) | 0.06 | 0.28 | 0.35 | +22 % |
| Slow: quiet blocks, mean (%) | 55.69 | 0.71 | 0.75 | +6 % |
| Slow: animal pixels per view, median | 3.09 | 3.68 | 25.88 | +604 % |
| Slow: blocks with animals, mean (%) | 24.12 | 24.38 | 33.73 | +38 % |
| Slow: motion in blocks with animals, median (%) | 0.30 | 0.58 | 1.08 | +87 % |
| Walker (rendered): motion while walking, median (%) | 0.12 | 0.46 | 0.66 | +43 % |
| Walker (rendered): animal reactions, 13 maps | 516 | 777 | 1083 | +39 % |
| Walker (rendered): snags | 44 | 0 | 0 | - |
| Walker (headless, 30 maps): animal reactions | - | 1897 | 2437 | +28 % |
| Fast: scene motion, median (%) | - | 0.60 | 0.75 | +25 % |
| Fast: weakest window, median (%) | - | 0.36 | 0.48 | +35 % |
| Fast: weakest window, worst (%) | - | 0.28 | 0.30 | +7 % |

## Slow sampling, per map

| Map | Recipe | Recorded 09-27 | Drawn | Cozy | Weakest view drawn / cozy | Animal px per view drawn / cozy | Motion in animal blocks drawn / cozy |
|---|---|---|---|---|---|---|---|
| 120000 | 12 Wild lane | 0.39 | 0.69 | 0.70 | 0.44 / 0.40 | 4 / 15 | 1.44 / 1.15 |
| 120001 | 13 Orchard | 0.17 | 0.45 | 0.54 | 0.24 / 0.33 | 4 / 25 | 0.68 / 1.21 |
| 120004 | 16 Below the rim | 0.11 | 0.51 | 0.49 | 0.25 / 0.25 | 7 / 28 | 0.57 / 1.02 |
| 120005 | 17 Gate road | 0.06 | 0.32 | 0.40 | 0.21 / 0.21 | 5 / 29 | 0.43 / 0.85 |
| 120006 | 18 Sparse wild | 0.37 | 0.46 | 0.40 | 0.34 / 0.20 | 2 / 22 | 0.54 / 0.92 |
| 120009 | 21 Terraces | 0.34 | 0.74 | 0.77 | 0.38 / 0.41 | 1 / 21 | 0.74 / 1.29 |
| 120010 | 22 Stone ruins | 0.27 | 0.56 | 0.62 | 0.30 / 0.30 | 3 / 26 | 1.11 / 1.12 |
| 120012 | 24 Rock garden | 0.48 | 0.64 | 0.71 | 0.39 / 0.35 | 3 / 28 | 0.58 / 1.42 |
| 120013 | 25 Deep forest | 0.24 | 0.32 | 0.48 | 0.22 / 0.41 | 4 / 45 | 0.39 / 0.92 |
| 120015 | 27 Hedge garden | 0.27 | 0.71 | 0.83 | 0.26 / 0.45 | 4 / 24 | 1.94 / 1.52 |
| 120020 | 32 Manor green | 0.12 | 0.40 | 0.53 | 0.22 / 0.37 | 3 / 32 | 0.38 / 0.90 |
| 120021 | 0 Pastoral | 0.12 | 0.42 | 0.56 | 0.29 / 0.42 | 3 / 39 | 0.46 / 0.91 |
| 120023 | 2 Pond walk | 0.39 | 0.40 | 0.64 | 0.29 / 0.51 | 5 / 33 | 0.45 / 1.14 |
| 120024 | 3 Garden | 0.27 | 0.63 | 0.65 | 0.28 / 0.31 | 3 / 17 | 0.60 / 0.78 |
| 120025 | 4 Lookout | 0.08 | 0.84 | 0.93 | 0.29 / 0.34 | 4 / 20 | 1.27 / 1.21 |
| 120026 | 5 Open meadow | 0.13 | 0.38 | 0.32 | 0.23 / 0.24 | 6 / 23 | 0.41 / 0.85 |
| 120027 | 6 Twin water | 0.12 | 0.65 | 0.84 | 0.13 / 0.31 | 5 / 28 | 1.54 / 2.08 |
| 120028 | 7 South road | 0.11 | 0.47 | 0.51 | 0.36 / 0.37 | 1 / 26 | 0.29 / 1.04 |

## Exhaustive walker (rendered), per map

| Map | Recipe | Motion drawn / cozy | Reactions drawn / cozy | Snags | Who reacted (cozy) |
|---|---|---|---|---|---|
| 120000 | 12 Wild lane | 0.67 / 0.71 | 49 / 37 | 0 / 0 | vole 19, goat 9, sparrow 4, mouse 3, pig 1, duck 1 |
| 120005 | 17 Gate road | 0.32 / 0.44 | 56 / 112 | 0 / 0 | bunny 36, sheep 19, goat 18, chicken 17, sparrow 12, turkey 10 |
| 120006 | 18 Sparse wild | 0.46 / 0.64 | 35 / 58 | 0 / 0 | goat 20, cow 14, lizard 8, pig 6, mouse 5, duck 3, frog 2 |
| 120010 | 22 Stone ruins | 0.54 / 0.66 | 22 / 58 | 0 / 0 | goat 17, frog 13, bunny 11, sheep 9, lizard 6, sparrow 1, duck 1 |
| 120012 | 24 Rock garden | 0.63 / 0.75 | 54 / 80 | 0 / 0 | frog 27, sparrow 23, sheep 10, lizard 8, duck 5, vole 4, turkey 3 |
| 120020 | 32 Manor green | 0.39 / 0.59 | 21 / 95 | 0 / 0 | chicken 39, goat 28, pig 10, bunny 7, lizard 4, cow 4, vole 2, sparrow 1 |
| 120021 | 0 Pastoral | 0.46 / 0.72 | 218 / 61 | 0 / 0 | goat 45, vole 7, cow 4, bunny 2, sheep 2, pig 1 |
| 120023 | 2 Pond walk | 0.40 / 0.63 | 58 / 127 | 0 / 0 | chicken 31, turkey 21, vole 13, cow 13, goat 13, sparrow 12, bunny 12, mouse 10, frog 2 |
| 120024 | 3 Garden | 0.63 / 0.82 | 40 / 58 | 0 / 0 | goat 33, vole 8, cow 6, frog 5, lizard 5, sparrow 1 |
| 120025 | 4 Lookout | 0.89 / 0.97 | 74 / 102 | 0 / 0 | duck 42, chicken 36, sheep 9, vole 8, lizard 5, goat 2 |
| 120026 | 5 Open meadow | 0.38 / 0.65 | 83 / 120 | 0 / 0 | chicken 49, goat 31, bunny 27, vole 9, mouse 4 |
| 120027 | 6 Twin water | 0.66 / 0.83 | 53 / 104 | 0 / 0 | chicken 34, turkey 25, sheep 19, frog 12, sparrow 10, mouse 2, duck 2 |
| 120028 | 7 South road | 0.43 / 0.58 | 14 / 71 | 0 / 0 | chicken 18, vole 15, bunny 10, pig 10, mouse 9, turkey 4, cow 3, sparrow 2 |

## Walker reactions by species (headless, 30 maps)

| Species | Drawn | Cozy |
|---|---|---|
| bunny | - | 213 |
| chicken | - | 559 |
| cow | - | 150 |
| duck | 46 | 108 |
| fox | 37 | - |
| frog | 156 | 158 |
| goat | - | 316 |
| hedgehog | 66 | - |
| lizard | 66 | 55 |
| mouse | 107 | 84 |
| pig | - | 73 |
| rabbit | 968 | - |
| sheep | - | 225 |
| sparrow | 128 | 110 |
| squirrel | 132 | - |
| turkey | - | 152 |
| vole | 191 | 234 |

## Fast estimate (30 maps)

The proxy's animal weight was calibrated on the drawn animals (small and
quick); the pack animals are larger and slower, so the fast estimate reads
their pixels as more motion than the rendered capture measures (fast
+25 % scene motion against +20 % measured).

- Weakest window rose on 21 of 30 maps (median +0.10 points, range -0.17 to +0.37); no map is under the 0.09 % floor in either mode.

