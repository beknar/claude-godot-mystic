# AI-generated art

Everything under `assets/ai/` is generated art, not from a purchased pack and not hand-painted: the character sheets were generated in Grok Build, the mill kit by a script in this repository.

| File | What it is |
|---|---|
| `characters/wanderer.png` | A woman in the Mystic Woods pixel style, with long yellow hair and a brighter coral tunic. 6 columns by 10 rows of 48×48. Same row order as `player.png`: idle down/side/up, walk down/side/up, attack down/side/up, death. Attack rows use the first four columns. |
| `characters/scout.png` | A woman in the same pixel style, with a short blonde bob and a light cream tunic. Same 6-by-10 grid and the same clips as `player.png`. |
| `characters/warrior-16x16-sheet.png` | A warrior on the same ten-row layout, drawn in 16×16 cells (96×160). Attack rows use the first four columns. The ford scene sets `frame_size` to 16 so those cells are read correctly. |
| `characters/red-fighter-16x16.png` | A red fighter on that same 16×16, ten-row layout. The heath scene uses it with `frame_size` 16. |

| `mill/mill_kit.png` | The windmill interior kit (drawn by `tools/gen_mill_kit.py` in the Farm – 4 Seasons sheet's colors, because no Painted Lands pack has mill machinery): the mill machine in 16 frames of 64×112 (spur wheel, shaft, hopper, runner stone on its hurst, flour spout), sacks, a sack stack, a ladder to a trapdoor, a spare millstone, the hoist hook in 3 frames, two flour spills; and for the cap up the ladder, the brake wheel and wallower in 16 frames of 80×96, the sack trap, and the ladder's top in its hatch. Rects in `FarmTiles.MILL`; used by the farm randomizers' windmill interior (docs/farm.md). |

Hand-painted pack art stays in `assets/pack/`. Do not move AI files into that folder.
