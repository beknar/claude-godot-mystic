# Creatures: monsters, NPCs, and enemies by compatibility

A ranking of every monster, NPC, and enemy in the asset packs this project
is allowed to use, by how well each fits the current map types of every
randomizer and maze scene. Assessed 2026-10-02 from the local collection
(`I:\game assets`).

## Scope

The allowed packs (AGENTS.md):

| Pack | Creatures in it | May be used |
|---|---|---|
| The Painted Lands (antarcticbees): Green Caves | slime green, slime blue | on Painted Lands maps |
| The Painted Lands: NPC - Characters | angler, doctor, dog, girl 1 (and with a basket), girl 2, old man, smith, witch | on Painted Lands maps |
| The Painted Lands: RPG Characters | archer, cloaked figure, dark knight, fire knight, healer, mage, samurai | on Painted Lands maps |
| The Painted Lands: Farm - 4 Seasons | the farmer (the fish are already the fish jumps) | on Painted Lands maps |
| Pixel Crawler (Anokolisa): Cemetery, Desert, Forge, Sewer, FREE | zombies (4), mummies (4), stone golems (4), rats (4), orcs (4), skeletons (4); heroes: knight, rogue, wizard | on Pixel Crawler maps |
| Cozy Farm (shubibubi) | animals (bunny, chicken, turkey, sheep, goat, pig, cow, babies); enemies (bat, ghost, nine slimes) | the **animals only**, on the Painted Lands scenes listed in AGENTS.md; its enemies are not allowed |

The two official packs never share a map, so a creature's compatibility
with the other pack's maps is zero by rule, whatever it looks like. Not
ranked: the walker (it is the player), the Farm's fish (already in use),
the code-drawn wildlife (not from a pack), and every pack not allowed
(Mana Seed, Time Fantasy, Mystic Woods, Cozy People, and the rest).

The scenes and how many map types each has:

| Family | Scene | Map types |
|---|---|---|
| Painted Lands | `randomizer-paintedlands` (Forest) | 36 |
| | `randomizer-greencaves` | 33 |
| | `randomizer-paintedlands-farm` (three seasons) | 52 |
| | `randomizer-paintedlands-forest-farm` (all of the above but caves, plus 12 farmsteads) | 100 |
| | `maze-forest` | 24 |
| | `maze-farm` (three seasons) | 30 |
| | `maze-greencaves` | 24 |
| Pixel Crawler | `randomizer-pixelcrawler` (fairy 6, green 5, cemetery 3, desert 3) | 17 |
| | `maze-pixelcrawler` (fairy 5, green 4, cemetery 4, desert 3, forge 4, sewer 3) | 23 |

About 211 distinct Painted Lands map types, 40 Pixel Crawler ones (fairy
11, green 9, cemetery 7, desert 6, forge 4, sewer 3).

## How they were judged

Each creature's first frame was cut from its sheet and measured (figure
size, colors, saturation, how much of its silhouette is a dark outline, and
the median distance of its colors to each map sheet's palette), then
viewed at 1:1 and 4x on every ground: Forest lawn, cave floor, Farm grass,
and the Pixel Crawler fairy grass, cemetery earth, desert sand, forge floor,
and sewer brick, beside the walker for scale. The score (out of 100):

- **Style** (30): outline weight, shading, detail, palette next to the
  maps it would stand on. The Painted Lands walker is 15 x 24 px, soft
  outlines, painterly shading; the Painted Lands NPCs and RPG characters are
  drawn by the same artist the same way. Pixel Crawler creatures are 16-29 px
  wide and 25-36 px tall, with heavy dark outlines (80-100 % of the
  silhouette) and higher contrast: right on their own sheets, wrong on
  Painted Lands ground.
- **Scale** (15): figure height next to the 24 px walker and the 16 px grid.
- **Animation** (20): what a monster, enemy, or NPC needs: idle, walk,
  attack, hurt, death; directions (the walker has four; almost everything
  else faces left and right and is flipped).
- **Coverage** (25): how many current map types it belongs on (theme and
  biome).
- **Rules** (10): allowed on those maps as they are.

## The ranking

| # | Creature | Pack | Role | Size (px) | Animations | Belongs on | Score |
|---|---|---|---|---|---|---|---|
| 1 | Slime, green | Painted Lands, Green Caves | monster | 15 x 13 (one cell) | idle, walk, attack, hit, death; left and right | every cave map (57 types), and damp Forest and maze spots: ponds, canals, moss | 95 |
| 2 | Slime, blue | Painted Lands, Green Caves | monster | 15 x 13 | the same | caves, springs, pools, lakes; Forest and Farm ponds and canals | 93 |
| 3 | Farmer | Painted Lands, Farm | NPC | 25 x 26 | idle and walk in four directions, tool swings (axe, hoe, watering), fishing | every Farm map, the farmsteads, the Farm mazes (94 types) | 92 |
| 4 | Cloaked figure | Painted Lands, RPG | enemy | 16 x 25 | walk, two attacks (and a standalone effect), hurt, defeat | anywhere at dusk: dark woods, caves, the ossuary, shade and firefly mazes, the crypt-like halls | 90 |
| 5 | Dark knight | Painted Lands, RPG | enemy, boss | 35 x 26 (with its sword) | walk, two attacks and a combo, hurt, defeat | maze guardians at the exit, vaults, treasure mazes, cave depths, stone courts | 89 |
| 6 | Angler | Painted Lands, NPC | NPC | 20 x 27 | idle, walk left and right, fishing left and right | lakes, rivers, ponds, canals: Fishing lake, Duck pond, the river types, Lily and Mill canals, underground springs | 88 |
| 7 | Girl 1 (and with a basket) | Painted Lands, NPC | NPC | 17 x 24 | idle, walk (with and without the basket) | farms, orchards, gardens, markets, villages, homesteads | 88 |
| 8 | Old man | Painted Lands, NPC | NPC | 16 x 24 | idle, walk, cane tap | villages, homes, hermit's nooks, cottage clearings | 87 |
| 9 | Dog | Painted Lands, NPC | animal NPC | 13 x 16 (one cell) | idle, walk, tail wag | every home and homestead, farms, farmsteads, cottage mazes | 87 |
| 10 | Samurai | Painted Lands, RPG | enemy, duelist | 29 x 25 | walk, two attacks and a combo, dash, hurt, defeat | Forest roads and clearings, bridges, the avenue and path mazes | 85 |
| 11 | Fire knight | Painted Lands, RPG | enemy | 33 x 26 | walk, two attacks (with and without fire), hurt, defeat | camps and campfire maps, torch-lit caves, the Lantern and Campfire mazes, the windmill and harvest fires | 85 |
| 12 | Smith | Painted Lands, NPC | NPC | 14 x 24 | idle, walk, anvil | villages, the miners' camp and mines, the cave hamlet, the barn | 84 |
| 13 | Girl 2 | Painted Lands, NPC | NPC | 16 x 24 | idle, walk, chasing a butterfly | meadows, wildflower maps, gardens, the Meadow and Garden mazes | 84 |
| 14 | Witch | Painted Lands, NPC | NPC (or a foe) | 23 x 29 | idle, walk, idle on her broom | deep and dark woods, the Firefly and Shade mazes, mossy hollows, the hermit's home, autumn farms | 83 |
| 15 | Doctor | Painted Lands, NPC | NPC | 15 x 23 | idle, walk, potion | villages, the farm village, the cave hamlet | 82 |
| 16 | Archer | Painted Lands, RPG | ally or enemy | 17 x 26 | walk, attacks (basic, magic, outlined arrows), magic attack, hurt, defeat | Forest edges and watch posts, the Wooded maze, farm fields | 81 |
| 17 | Healer | Painted Lands, RPG | ally | 17 x 28 | walk, attack, healing, hurt, defeat | homes, villages, shrines, springs | 80 |
| 18 | Mage | Painted Lands, RPG | ally or enemy | 27 x 29 (with staff) | walk, two attacks (with and without the spell), hurt, defeat | crystal caves, the crystal shrine, runic and rings mazes | 79 |
| 19 | Orcs (orc, rogue, shaman, warrior) | Pixel Crawler, FREE | enemies | 20-23 x 25-32 | idle, run, death; one facing; weapons as their own sheets | the fairy and green forest maps and mazes (20 of 40 Pixel Crawler types) | 74 |
| 20 | Skeletons (base, mage, rogue, warrior) | Pixel Crawler, FREE | enemies | 16-20 x 30-32 | idle, run, death; weapons separate | crypts and the cemetery (7), the desert's bone fields (6), the forge halls (4) | 73 |
| 21 | Heroes (knight, rogue, wizard) | Pixel Crawler, FREE | NPCs, adventurers (or the player) | 19-25 x 29-32 | idle, run, death | every Pixel Crawler map (40); also the natural walker for those maps (below) | 72 |
| 22 | Zombies (base, muscle, overweight, banshee) | Pixel Crawler, Cemetery | enemies | 16-18 x 30-32 (the banshee 47 tall with its hair) | idle, run, hit, death | the cemetery maps and the crypt mazes (7) | 70 |
| 23 | Mummies (base, mage, rogue, warrior) | Pixel Crawler, Desert | enemies | 16-22 x 31-36 | idle, run, death | the desert maps and mazes (6) | 68 |
| 24 | Stone golems (base, broken, golem, lava) | Pixel Crawler, Forge | enemies | 19-22 x 23-31 | idle, run, death | the forge halls and lava channels (4; the lava golem on the lava) | 66 |
| 25 | Rats (base, mage, rogue, warrior) | Pixel Crawler, Sewer | enemies | 27-29 x 30 | idle, run, death | the sewer mazes (3) | 64 |

Why the order falls as it does:

- **Painted Lands creatures lead**: drawn by the same hand as the walker and
  the tiles (soft outlines, 24 px figures on a 16 px grid, palettes within
  4-25 of the Forest, cave, and Farm sheets), with full combat or NPC sets,
  and they belong on about five times as many map types. The **slimes**
  top it: the Green Caves pack's own monster, one cell big, the full enemy
  set in both facings, at home on 57 cave map types and plausible in every
  damp spot of the Forest and the mazes. The **RPG characters** are the only
  humanoid enemies in the Painted Lands family, so the four that read as
  foes (cloaked figure, dark knight, samurai, fire knight) rank above the
  NPCs who belong on fewer maps; the three that read as friends (archer,
  healer, mage) rank last of the family: the mage's large staff and 25
  colors stand out, the healer's thin outline (12 %) is the weakest match.
- **Pixel Crawler creatures** are as native to their sheets as the slimes are
  to the caves (heavy outlines and contrast match their tiles; palettes
  within 4-20 of their own biome), but each family belongs to one biome and
  Pixel Crawler has 40 map types in all. They are ranked by how many of
  those they cover: the **orcs** fit the fairy and green forests (half of
  all Pixel Crawler maps), the **skeletons** three biomes, the **heroes**
  every map as people; the single-biome families follow by biome size.
  They animate idle, run, and death only (the zombies also a hit), one
  facing, with their weapons on separate sheets to attach, and stand 30 px
  tall next to the 24 px Painted Lands walker the Pixel Crawler scenes use
  now.

## Ambient animals (Cozy Farm, allowed)

Not monsters, NPCs, or enemies, but the only other creatures the rules
allow. All are already in the Painted Lands scenes (wildlife.gd `pack` and
`farmland`). Front-on sprites with no outline and muted colors: close to the
Farm palette (5-13), softer than the Painted Lands figures but at home
beside them; on Pixel Crawler maps they would clash with its heavy outlines
(and the rules keep them off).

| # | Animal | Size (px) | Belongs on |
|---|---|---|---|
| 1 | Sheep (and lamb) | 14 x 14 | farms, pens, pastures, the Pasture maze, homesteads |
| 2 | Cow (white, black, brown, and calves) | 16 x 17 | farms, pens, the Barnyard maze |
| 3 | Chicken (white, brown, chick) | 13 x 12 | yards round every home, farms |
| 4 | Goat (plain, striped, kids) | 14 x 18 | pens, hills, homesteads, cave homes on moss |
| 5 | Bunny (brown, grey, babies) | 11 x 11 | every Painted Lands lawn, moss caves, hedge and grass mazes |
| 6 | Pig (pink, striped, piglets) | 16 x 18 | yards and pens (the pink pig is the furthest from the palettes, 34-43) |
| 7 | Turkey | about 16 x 16 | yards, autumn farms |

## Best picks by scene

In order, for each scene's current map types:

| Scene | Enemies and monsters | NPCs |
|---|---|---|
| `randomizer-paintedlands` | cloaked figure, dark knight, samurai, slime green (ponds, rivers), fire knight (camps) | old man, girl 1, girl 2, angler (rivers, ponds), dog, doctor, smith, witch (dark woods), archer |
| `randomizer-greencaves` | slime green, slime blue, cloaked figure, fire knight (campfires, torches), dark knight (vault, ossuary), mage (crystals) | smith (mines, miners' camp), old man and witch (hermit's homes), angler (springs, lakes), dog and doctor (cave hamlet) |
| `randomizer-paintedlands-farm` | slime blue (ponds, rivers), cloaked figure (autumn, winter nights); a farm is mostly peaceful | farmer, dog, girl 1 with her basket (orchards, markets), old man, angler (lakes, rivers), girl 2 (meadows), smith, doctor (villages), witch (autumn) |
| `randomizer-paintedlands-forest-farm` | the Forest's and the Farm's together; fire knight at the farmsteads' campfires | farmer, dog, girl 1, old man, smith, angler, girl 2, doctor, witch |
| `maze-forest` | dark knight (guarding the exit), samurai (avenues, path mazes), cloaked figure (shade and firefly mazes), slime green (pond court, moss garden, canals), fire knight (campfire and lantern mazes) | witch (firefly maze), old man and dog (cottage mazes), angler (canals) |
| `maze-farm` | slime blue (canals), cloaked figure (corn and wheat mazes at dusk), dark knight (the moated farmhouse) | farmer, dog, girl 1, old man (farmhouse mazes), angler (canals), girl 2 (meadow grass maze), smith (barnyard maze) |
| `maze-greencaves` | slime green, slime blue, cloaked figure, fire knight (torch-lit halls), dark knight (vault, ossuary), mage (crystal maze) | smith (mine mazes, cave hamlet), old man and witch (hermit's maze), angler (spring, flooded mazes) |
| `randomizer-pixelcrawler` | orcs (fairy, green), skeletons and zombies (cemetery), mummies and skeletons (desert) | knight, rogue, wizard |
| `maze-pixelcrawler` | orcs (fairy and green hedges, canals), zombies and skeletons (crypts), mummies and skeletons (desert), stone golems, the lava golem on the lava, skeletons (forge), rats (sewer) | knight, rogue, wizard |

## Not allowed (for the record)

- **Cozy Farm enemies**: a bat (black, purple, red), a ghost, and slimes in
  nine colors, with four-direction attack, move, and death animations. The
  rules allow Cozy Farm's animals only. On looks the bat would rank near the
  top for caves and dungeons (it is the only bat sprite among these packs;
  the caves' bats are drawn effects) and the slimes would sit just below the
  Green Caves slimes; allowing them would take a change to AGENTS.md.
- **Painted Lands creatures on Pixel Crawler maps, and the other way round**:
  never, by the official-pack rule.

## Notes for using them

- **The Pixel Crawler walker.** The Pixel Crawler scenes walk the Painted
  Lands walker (24 px, soft outlines) among 30 px heavy-outlined Pixel
  Crawler creatures. The Pixel Crawler knight, rogue, or wizard as the walker
  on those maps would keep each map in one pack's style.
- **Facings.** Everything but the farmer, the walker, and the Cozy Farm
  enemies faces left and right only; walking up or down plays the side walk
  (flipped as needed), as most top-down games with side sprites do.
- **Pixel Crawler attacks** come from the weapon sheets (`Weapons/`: bone,
  wood, hands, cursed, fire, poison) held over the run and idle frames.
- **Frames.** Painted Lands: 32 x 32 cells (48 x 32 for the knights and the
  samurai), 16 x 16 for the slimes and the dog; Pixel Crawler: 64 x 64 cells
  (idle 4 frames, run 6, death 6-9), the figure in the lower middle.
- **No enemy system yet.** The project draws animals (wildlife.gd) but has
  no enemies or NPC behaviour; the slimes and the NPCs' idle and walk sets
  would drop into a wildlife-style roam-and-react system first.
