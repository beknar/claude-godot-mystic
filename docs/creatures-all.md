# Creatures: monsters, NPCs, and enemies by compatibility

A ranking of every monster, enemy, NPC, and animal sprite in the local
collection (`I:\game assets`), by how well each fits the current map types
of every randomizer and maze scene. It covers the packs this project is
allowed to use and every other pack with creature art, so it is a superset
of the first ranking (allowed packs only, 2026-10-01); the allowed entries
keep their scores. Heroes and player characters are ranked in
`docs/future-heroes.md`. Assessed 2026-10-01.

## Scope

The packs with creatures, and what the rules (AGENTS.md) say about them.
Paths are under `I:\game assets`.

| Pack | Path | Creatures in it | Rules |
|---|---|---|---|
| The Painted Lands (antarcticbees): Green Caves | `antarcticbees asset packs/The Painted Lands - Green Caves Tileset/` | slime green, slime blue | allowed on Painted Lands maps |
| The Painted Lands: NPC - Characters | `antarcticbees asset packs/FULL VERSION NPC - Characters by antarcticbees/` | angler, doctor, dog, girl 1 (and with a basket), girl 2, old man, smith, witch | allowed on Painted Lands maps |
| The Painted Lands: RPG Characters | `antarcticbees asset packs/RPG Characters by antarcticbees/` | archer, cloaked figure, dark knight, fire knight, healer, mage, samurai | allowed on Painted Lands maps |
| The Painted Lands: Farm - 4 Seasons | `antarcticbees asset packs/FULL VERSION Farm - 4 Seasons 16x16 Tileset by antarcticbees/` | the farmer (the fish are already the fish jumps) | allowed on Painted Lands maps |
| Pixel Crawler (Anokolisa): FREE, Cemetery, Desert, Forge, Sewer | `pixel crawler/Pixel Crawler - FREE - 1.8/`, `- Cemetery/`, `- Desert 1.2/`, `- Forge/`, `- Sewer/` | orcs (4), skeletons (4), zombies (4), mummies (4), stone golems (4), rats (4); heroes: knight, rogue, wizard | allowed on Pixel Crawler maps |
| Cozy Farm (shubibubi) | `cozy farm art pack/` | animals (bunny, chicken, turkey, sheep, goat, pig, cow, babies); enemies (bat, ghost, nine slimes) | the **animals only**, on the Painted Lands scenes listed in AGENTS.md |
| Cozy People (shubibubi) | `cozy people art pack/` | villagers (paper doll) | not allowed |
| Fantasy RPG asset pack, heroes pack, Snow expansion, Dungeon pack | `fanatical bundle packs/RPG Game Builder Assets Kit/` | NPCs, townsfolk, monsters and animals; skeletons; Christmas folk; a tiny dungeon set | not allowed |
| Fantasy Dreamland Characters | `fanatical bundle packs/Fantasy Dreamland Characters Pocket Pack/` | townsfolk, enemies, bosses | not allowed |
| Ninja Adventure (Pixel-boy) | `NinjaAdventure/Actor/` | 57 characters, 50 monsters, 8 bosses, 13 animals | not allowed |
| Complete RPG Creator Bundle | `complete rpg creator bundle/` | Beowulf's Dungeons Monsters and Mini Animals, 2D Pixel RPG Monsters, the Rogue-like RPG, AfGameAssets NPCs and enemies | not allowed |
| Sunnyside World | `sunny side world/` | goblin, skeleton, farm animals | not allowed |
| Survival game art | `survival game godot series art/` | a slime | not allowed |
| Mega 12 (pixeljad) | `mega 12 pack - by pixeljad/MEGA BUNDLE 12 ASSET PACKS/` | Harvest Tiny Farm animals, the Sengoku seller, a Tiny Beach crab | not allowed |
| Kenney | `kenney game assets all-in-1/` | Tiny Dungeon heroes and monsters, RPG Urban people | not allowed |
| Pixelart Medieval Fantasy Characters, Huge Asset Pack, Mighty Pixel | `Pixelart_Medieval_Fantasy_Characters_Pack/`, `huge asset pack/`, `mighty pixel game asset pocket pack/` | side-view enemies | not allowed |
| The Japan Collection: JRPG Characters | `fanatical bundle packs/RPG Game Builder Assets Kit/The Japan Collection- JRPG Characters Asset Pack/` | modern townsfolk, a witch, a Shiba Inu | not allowed |
| Mystic Woods 2.2 | `mystic_woods_2.2/sprites/characters/` | skeleton (and swordless), slime | barred (deprecated) |
| Time Fantasy | `Time Fantasy packs/timefantasy_characters/` (also in the RPG Game Builder kit as "80+ RPG Characters") | NPCs, military, cats, dogs | barred (not suitable) |
| Mana Seed collection | `complete rpg creator bundle/mana seed pixel art tileset collection/` | none (tiles only) | barred (not to be used) |

The two official packs never share a map, so a creature's compatibility
with the other pack's maps is zero by rule, whatever it looks like. Not
ranked: the walker (it is the player), the Farm's fish (already in use),
the code-drawn wildlife (not from a pack), and the art listed under "Not
ranked" below.

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
viewed at 1:1 and 3-4x on the grounds (Forest lawn, cave floor, Farm grass,
and the Pixel Crawler grass, cemetery earth, desert sand, forge floor, and
sewer brick) beside the walker for scale. The score (out of 100):

- **Style** (30): outline weight, shading, detail, palette next to the
  maps it would stand on. The Painted Lands walker is 15 x 24 px, soft
  outlines, painterly shading; the Painted Lands NPCs and RPG characters are
  drawn by the same artist the same way. Pixel Crawler creatures are 16-29 px
  wide and 25-36 px tall, with heavy dark outlines (80-100 % of the
  silhouette) and higher contrast: right on their own sheets, wrong on
  Painted Lands ground. A pack from outside is scored against whichever
  family it suits better.
- **Scale** (15): figure height next to the 24 px walker and the 16 px grid
  (or the 30 px Pixel Crawler creatures).
- **Animation** (20): what a monster, enemy, or NPC needs: idle, walk,
  attack, hurt, death; directions (the walker has four; most of the allowed
  creatures face left and right and are flipped). Front-facing sprites with
  no walk score near nothing.
- **Coverage** (25): how many current map types it belongs on (theme and
  biome).
- **Rules** (10): allowed on those maps as they are (10); another pack that
  would need a rule change, as Cozy Farm's animals got (3); Mana Seed, Time
  Fantasy, and Mystic Woods, barred by AGENTS.md (0).

## The ranking

Rules: **A** allowed, **O** other pack (needs a rule change), **B** barred.

| # | Creature | Pack | Role | Size (px) | Animations | Belongs on | Rules | Score |
|---|---|---|---|---|---|---|---|---|
| 1 | Slime, green | Painted Lands, Green Caves | monster | 15 x 13 (one cell) | idle, walk, attack, hit, death; left and right | every cave map (57 types), and damp Forest and maze spots: ponds, canals, moss | A | 95 |
| 2 | Slime, blue | Painted Lands, Green Caves | monster | 15 x 13 | the same | caves, springs, pools, lakes; Forest and Farm ponds and canals | A | 93 |
| 3 | Farmer | Painted Lands, Farm | NPC | 25 x 26 | idle and walk in four directions, tool swings (axe, hoe, watering), fishing | every Farm map, the farmsteads, the Farm mazes (94 types) | A | 92 |
| 4 | Cloaked figure | Painted Lands, RPG | enemy | 16 x 25 | walk, two attacks (and a standalone effect), hurt, defeat | anywhere at dusk: dark woods, caves, the ossuary, shade and firefly mazes, the crypt-like halls | A | 90 |
| 5 | Dark knight | Painted Lands, RPG | enemy, boss | 35 x 26 (with its sword) | walk, two attacks and a combo, hurt, defeat | maze guardians at the exit, vaults, treasure mazes, cave depths, stone courts | A | 89 |
| 6 | Angler | Painted Lands, NPC | NPC | 20 x 27 | idle, walk left and right, fishing left and right | lakes, rivers, ponds, canals: Fishing lake, Duck pond, the river types, Lily and Mill canals, underground springs | A | 88 |
| 7 | Girl 1 (and with a basket) | Painted Lands, NPC | NPC | 17 x 24 | idle, walk (with and without the basket) | farms, orchards, gardens, markets, villages, homesteads | A | 88 |
| 8 | Old man | Painted Lands, NPC | NPC | 16 x 24 | idle, walk, cane tap | villages, homes, hermit's nooks, cottage clearings | A | 87 |
| 9 | Dog | Painted Lands, NPC | animal NPC | 13 x 16 (one cell) | idle, walk, tail wag | every home and homestead, farms, farmsteads, cottage mazes | A | 87 |
| 10 | Samurai | Painted Lands, RPG | enemy, duelist | 29 x 25 | walk, two attacks and a combo, dash, hurt, defeat | Forest roads and clearings, bridges, the avenue and path mazes | A | 85 |
| 11 | Fire knight | Painted Lands, RPG | enemy | 33 x 26 | walk, two attacks (with and without fire), hurt, defeat | camps and campfire maps, torch-lit caves, the Lantern and Campfire mazes, the windmill and harvest fires | A | 85 |
| 12 | Smith | Painted Lands, NPC | NPC | 14 x 24 | idle, walk, anvil | villages, the miners' camp and mines, the cave hamlet, the barn | A | 84 |
| 13 | Girl 2 | Painted Lands, NPC | NPC | 16 x 24 | idle, walk, chasing a butterfly | meadows, wildflower maps, gardens, the Meadow and Garden mazes | A | 84 |
| 14 | Witch | Painted Lands, NPC | NPC (or a foe) | 23 x 29 | idle, walk, idle on her broom | deep and dark woods, the Firefly and Shade mazes, mossy hollows, the hermit's home, autumn farms | A | 83 |
| 15 | Doctor | Painted Lands, NPC | NPC | 15 x 23 | idle, walk, potion | villages, the farm village, the cave hamlet | A | 82 |
| 16 | Archer | Painted Lands, RPG | ally or enemy | 17 x 26 | walk, attacks (basic, magic, outlined arrows), magic attack, hurt, defeat | Forest edges and watch posts, the Wooded maze, farm fields | A | 81 |
| 17 | Healer | Painted Lands, RPG | ally | 17 x 28 | walk, attack, healing, hurt, defeat | homes, villages, shrines, springs | A | 80 |
| 18 | Mage | Painted Lands, RPG | ally or enemy | 27 x 29 (with staff) | walk, two attacks (with and without the spell), hurt, defeat | crystal caves, the crystal shrine, runic and rings mazes | A | 79 |
| 19 | Villagers (paper doll) | Cozy People | NPCs | 12-15 x 19-21 (32 x 32 cells) | four directions: walk, jump, pick up, carry, sword, block, hurt, die, pickaxe, axe, water, hoe, fishing | every Painted Lands home, farm, village, market, camp, and mine; farmhouse and cottage mazes | O | 78 |
| 20 | Bat (black, purple, red), ghost, slimes (nine colors) | Cozy Farm enemies | monsters | bat 16 x 8, slime 12 x 10, ghost about 15 x 15 (16 px cells) | four directions: move, attack, death | the bat in every cave and cave maze (the only bat sprite among the allowed artists; the caves' bats are drawn effects); the ghost in the ossuary and dark woods; the slimes by water | O | 76 |
| 21 | Monsters and animals (bats, mushys, ogres, skeletons, slimes, wolves; cow, hen, pig) | Fantasy RPG asset pack | monsters, animals | 10-14 tall (wolf 16, ogre 24 x 23) | four directions: idle, walk (bats fly) | Painted Lands: the forest (wolves, mushys), caves (bats, slimes, ogres), crypt-like halls (skeletons), farms (the animals) | O | 76 |
| 22 | Orcs (orc, rogue, shaman, warrior) | Pixel Crawler, FREE | enemies | 20-23 x 25-32 | idle, run, death; one facing; weapons as their own sheets | the fairy and green forest maps and mazes (20 of 40 Pixel Crawler types) | A | 74 |
| 23 | NPCs and Medieval Townsfolk (15 + 9: alchemist, barmaid, blacksmith, farmer, fisherman, merchant, kids...) | Fantasy RPG asset pack | NPCs | 12-16 x 14-22 (16 x 24 cells) | four directions: idle, walk | villages, farms, markets, homes, mines (the blacksmith), rivers (the fisherman) | O | 74 |
| 24 | Skeletons (base, mage, rogue, warrior) | Pixel Crawler, FREE | enemies | 16-20 x 30-32 | idle, run, death; weapons separate | crypts and the cemetery (7), the desert's bone fields (6), the forge halls (4) | A | 73 |
| 25 | Heroes (knight, rogue, wizard) | Pixel Crawler, FREE | NPCs, adventurers (or the player) | 19-25 x 29-32 | idle, run, death | every Pixel Crawler map (40); also the natural walker for those maps (below) | A | 72 |
| 26 | Zombies (base, muscle, overweight, banshee) | Pixel Crawler, Cemetery | enemies | 16-18 x 30-32 (the banshee 47 tall with its hair) | idle, run, hit, death | the cemetery maps and the crypt mazes (7) | A | 70 |
| 27 | Mummies (base, mage, rogue, warrior) | Pixel Crawler, Desert | enemies | 16-22 x 31-36 | idle, run, death | the desert maps and mazes (6) | A | 68 |
| 28 | Skeleton (and swordless), slime | Mystic Woods 2.2 | enemies | skeleton 16 x 18, slime 16 x 12 | down, side, up: idle, move, attack, damaged, death | Painted Lands caves, ossuary, dark woods (close in style to the walker) | B | 67 |
| 29 | Stone golems (base, broken, golem, lava) | Pixel Crawler, Forge | enemies | 19-22 x 23-31 | idle, run, death | the forge halls and lava channels (4; the lava golem on the lava) | A | 66 |
| 30 | Skeletons (3) | Fantasy RPG heroes pack | enemies | 12 x 14 | four directions: idle, walk, die | Painted Lands caves, the ossuary, vault mazes | O | 65 |
| 31 | Rats (base, mage, rogue, warrior) | Pixel Crawler, Sewer | enemies | 27-29 x 30 | idle, run, death | the sewer mazes (3) | A | 64 |
| 32 | Enemies (about 16 designs x 4 colors) and bosses (about 44) | Fantasy Dreamland | monsters, bosses | enemies 8-18 tall, bosses 27-47 | four directions: walk 3 frames; dead sprites | Pixel Crawler: every biome has a fit (slimes, bats, skeletons, plants, golems) | O | 58 |
| 33 | NPCs: villagers, knights, ninjas, monks, merchants | Ninja Adventure | NPCs | 14-16 x 15-16 | four directions: walk, idle, attack, jump, dead, item, two specials; a faceset each | Pixel Crawler: every map as townsfolk and rivals | O | 57 |
| 34 | Dungeon monsters (117, bosses at 32 and 64) | Pixel RPG Dungeons Monsters (Beowulf) | monsters | 15-16 (bosses 32) | front-facing, 2-frame idle only | Pixel Crawler crypts, forge, sewer | O | 57 |
| 35 | Christmas folk (elves, gnomes, Santa, Krampus, Rudolph, snowman; 18) | Fantasy RPG Snow expansion | NPCs, a boss (Krampus) | 10-15 x 13-18 small, 21-28 x 22-30 large | four directions: idle, walk | Painted Lands winter farms and winter mazes | O | 57 |
| 36 | Monsters (50: slimes, bats, skeletons, spirits, beasts...) | Ninja Adventure | monsters | 13-16 x 8-15 | four directions: walk 4 frames only | Pixel Crawler: every biome | O | 56 |
| 37 | Animals (13 species: rabbit, cat, dog, snake, mouse, bird, turtle, capybara, snail, cow, frog, bugs) | Mini Animals (Beowulf) | animals | 8-16 (cow 29) | four directions: walk 4 frames; birds fly | Pixel Crawler: fairy and green forests, pens | O | 54 |
| 38 | Slime | Survival game art | monster | 12 x 9 | idle and hop, hit, burst death | Pixel Crawler forests and sewers | O | 54 |
| 39 | NPCs, military, cats, dogs | Time Fantasy | NPCs, animals | 15-17 x 28-31 (animals 15 x 16-20) | four directions: walk 3 frames, emotes | Painted Lands villages and homes on looks (taller than the walker) | B | 52 |
| 40 | Bosses (8) | Ninja Adventure | bosses | 32-55 x 26-49 | idle, walk, hit, attack, jump, charge; one facing | Pixel Crawler maze exits and vaults | O | 52 |
| 41 | Goblin, skeleton | Sunnyside World | enemies | 18 x 16, 13 x 16 | left and right: the goblin 20 actions (attack, hurt, death...); the skeleton idle, walk, attack, hurt, death, jump | Painted Lands forests and caves (too small, brighter) | O | 50 |
| 42 | Townsfolk and heroes as NPCs (80) | Fantasy Dreamland | NPCs | 12 x 17 | four directions: walk 3 frames | Pixel Crawler: every map | O | 49 |
| 43 | Monsters (96, eight biomes) | 2D Pixel RPG Monsters | monsters | 9-24 | none (static, front-facing) | Pixel Crawler: one biome each (undead, cave, forest, field) | O | 48 |
| 44 | Monsters (13) | Pixel Art Rogue-like RPG | monsters | 12-29 | front-facing: idle 2 frames, attack, dead | Pixel Crawler crypts and caves | O | 47 |
| 45 | Animals (13) | Ninja Adventure | animals | 13 x 11 | 2-frame idle (some side walks) | Pixel Crawler forests | O | 46 |
| 46 | Farm animals (chicken, cow, pig, sheep, duck, bird) | Sunnyside World | animals | chicken 16 x 19, cow 23 x 26 | 4-frame idle | Painted Lands farms (the Cozy Farm animals already fill this) | O | 42 |
| 47 | Chicken, pig, cow | Harvest Tiny Farm (Mega 12) | animals | chicken 13 x 13, cow 37 x 20 | one side facing, 5-frame idle and walk | farms (the Cozy Farm animals already fill this) | O | 42 |
| 48 | Knight, skeleton, bat, slimes (3) | Fantasy RPG Dungeon pack | monsters | 11-12 x 10-16 | front-facing, one 4-frame loop | Painted Lands caves (too small, front only) | O | 38 |
| 49 | Heroes and monsters (20: ghost, bat, crab, spider, orc...) | Kenney Tiny Dungeon | monsters, NPCs | 14-16 x 12-16 | none (static, front-facing) | Pixel Crawler crypts | O | 37 |
| 50 | NPCs and enemies (barman, librarian, monk, butcher; beaver-beast, ghost, mage, necromancer, salamander) | AfGameAssets RPG NPC and Top-Down Enemies | NPCs, enemies | 25-46 | one facing: idle, walk, attack, hit, dead; NPC idles and a "surprised" | Pixel Crawler cemetery and crypts on tone (too tall, no outline) | O | 35 |
| 51 | Enemies (11: archer, bandit, barbarian, bomber, dark knight, hound, mage, shieldbearer) | Pixelart Medieval Fantasy Characters | enemies | 41-55 tall | side view: idle, run, two attacks, hit | neither (side view, twice the walker) | O | 35 |
| 52 | Modern townsfolk (16), witch, Shiba Inu | Japan Collection JRPG Characters | NPCs | 14 x 32 | four directions: walk 8 frames | neither (a modern cast) | O | 30 |
| 53 | Seller in a stall | Sengoku Adventure (Mega 12) | NPC | 32 x 32 with the stall | 3 frames | Painted Lands markets (baked into its own stall) | O | 30 |
| 54 | Enemies (18) | Huge Asset Pack | enemies | 8-24 | side-view platformer animations | neither | O | 30 |
| 55 | Modern people (6) | Kenney RPG Urban Pack | NPCs | 12 x 13-15 | four directions: walk 3 frames | neither (modern) | O | 30 |
| 56 | Cultists (2 colors) | Mighty Pixel pocket pack | enemies | 9-11 x 22 (shipped 4x) | side view: idle, walk, two attacks | neither | O | 25 |
| 57 | Crab | Tiny Beach (Mega 12) | monster | 27 x 13 | idle, attack; one facing | Painted Lands lakesides at most | O | 25 |

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
- **The best outside art is soft and top-down.** Cozy People and the Cozy
  Farm enemies are shubibubi's, the artist of the Cozy Farm animals already
  on the Painted Lands maps, and the Fantasy RPG asset pack is drawn with
  warm brown outlines and muted chibi figures; all three walk in four
  directions, more than most allowed creatures do. They sit just under the
  Painted Lands family because they need a rule change (7 points) and stand
  a little shorter than the walker. Cozy People has no monsters; the Cozy
  Farm bat would be the caves' first walking bat.
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
- **The heavy-outlined chibi packs** (Fantasy Dreamland, Ninja Adventure,
  Beowulf's monsters and animals) suit Pixel Crawler's outlines better than
  Painted Lands, and are large and four-directional, but their 8-17 px
  figures stand half as tall as the Pixel Crawler creatures and their colors
  are flat and bright. Beowulf's 117 monsters face front with a 2-frame idle,
  so they would only stand and bob.
- **Barred packs** score on looks only: Mystic Woods' skeleton and slime are
  close to the walker in style; Time Fantasy's NPCs are crisp but 30 px.
- **The bottom of the list** is the wrong view (front-facing statics,
  side-view fighters and platformer enemies), the wrong era (modern
  townsfolk), or art the allowed packs already cover (farm animals).

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

In order, for each scene's current map types. The last column is what an
added pack would bring, if the rules were changed for it.

| Scene | Enemies and monsters (allowed) | NPCs (allowed) | If a pack is added |
|---|---|---|---|
| `randomizer-paintedlands` | cloaked figure, dark knight, samurai, slime green (ponds, rivers), fire knight (camps) | old man, girl 1, girl 2, angler (rivers, ponds), dog, doctor, smith, witch (dark woods), archer | Cozy People villagers; Fantasy RPG asset wolves and mushys |
| `randomizer-greencaves` | slime green, slime blue, cloaked figure, fire knight (campfires, torches), dark knight (vault, ossuary), mage (crystals) | smith (mines, miners' camp), old man and witch (hermit's homes), angler (springs, lakes), dog and doctor (cave hamlet) | Cozy Farm bats and ghost; Fantasy RPG asset bats, slimes, ogres |
| `randomizer-paintedlands-farm` | slime blue (ponds, rivers), cloaked figure (autumn, winter nights); a farm is mostly peaceful | farmer, dog, girl 1 with her basket (orchards, markets), old man, angler (lakes, rivers), girl 2 (meadows), smith, doctor (villages), witch (autumn) | Cozy People farmers; Fantasy RPG Medieval Townsfolk; the Snow expansion's folk in winter |
| `randomizer-paintedlands-forest-farm` | the Forest's and the Farm's together; fire knight at the farmsteads' campfires | farmer, dog, girl 1, old man, smith, angler, girl 2, doctor, witch | Cozy People villagers |
| `maze-forest` | dark knight (guarding the exit), samurai (avenues, path mazes), cloaked figure (shade and firefly mazes), slime green (pond court, moss garden, canals), fire knight (campfire and lantern mazes) | witch (firefly maze), old man and dog (cottage mazes), angler (canals) | Fantasy RPG asset wolves and mushys |
| `maze-farm` | slime blue (canals), cloaked figure (corn and wheat mazes at dusk), dark knight (the moated farmhouse) | farmer, dog, girl 1, old man (farmhouse mazes), angler (canals), girl 2 (meadow grass maze), smith (barnyard maze) | Cozy People farmers; Snow expansion folk in winter |
| `maze-greencaves` | slime green, slime blue, cloaked figure, fire knight (torch-lit halls), dark knight (vault, ossuary), mage (crystal maze) | smith (mine mazes, cave hamlet), old man and witch (hermit's maze), angler (spring, flooded mazes) | Cozy Farm bats and ghost; Fantasy RPG heroes-pack skeletons in the ossuary |
| `randomizer-pixelcrawler` | orcs (fairy, green), skeletons and zombies (cemetery), mummies and skeletons (desert) | knight, rogue, wizard | Fantasy Dreamland enemies; Ninja Adventure NPCs and monsters |
| `maze-pixelcrawler` | orcs (fairy and green hedges, canals), zombies and skeletons (crypts), mummies and skeletons (desert), stone golems, the lava golem on the lava, skeletons (forge), rats (sewer) | knight, rogue, wizard | Fantasy Dreamland and Ninja Adventure bosses at the exits; Beowulf's dungeon monsters in the crypts, forge, and sewer |

## Not ranked (for the record)

- **Battle-screen battlers** with no walk: Pixel Battlers 1-6 (288),
  Little Monsters and Robots 7-9, Tyler Warren RPG Battlers (hand-painted),
  Time Fantasy side-view battlers (80). They suit a turn-based battle
  screen, which the project does not have.
- **Not pixel art at this scale**: the vector and Spine packs (2D Fantasy
  Characters V2's crow, orc, and spider, Cute RPG Game Builder's skeletons,
  Orc Conqueror, the Monster Creature and Supermix Flash packs, the 2D Top
  Down Character Bundle, the gdm zombies and character bundles).
- **Sci-fi or modern**: Pixel Art Cyberpunk, Futuristic Characters, Robots,
  Tiny Tales Code Ark, VisuStella Cursed School and Urban City, Little
  Monsters and Robots 8's robots.
- **Painted Lands creatures on Pixel Crawler maps, and the other way round**:
  never, by the official-pack rule.

## Notes for using them

- **The Pixel Crawler walker.** The Pixel Crawler scenes walk the Painted
  Lands walker (24 px, soft outlines) among 30 px heavy-outlined Pixel
  Crawler creatures. The Pixel Crawler knight, rogue, or wizard as the walker
  on those maps would keep each map in one pack's style (see
  `docs/future-heroes.md`).
- **Facings.** Of the allowed creatures, everything but the farmer and the
  walker faces left and right only; walking up or down plays the side walk
  (flipped as needed), as most top-down games with side sprites do. Most of
  the outside packs ranked above 50 walk in four directions.
- **Pixel Crawler attacks** come from the weapon sheets (`Weapons/`: bone,
  wood, hands, cursed, fire, poison) held over the run and idle frames.
- **Frames.** Painted Lands: 32 x 32 cells (48 x 32 for the knights and the
  samurai), 16 x 16 for the slimes and the dog; Pixel Crawler: 64 x 64 cells
  (idle 4 frames, run 6, death 6-9), the figure in the lower middle. Cozy
  People: 32 x 32 cells, layered (body, eyes, clothes, hair, accessory).
  Fantasy RPG asset pack: 16 x 24 NPCs, 16 x 16 monsters, 32 x 32 ogres.
- **No enemy system yet.** The project draws animals (wildlife.gd) but has
  no enemies or NPC behaviour; the slimes and the NPCs' idle and walk sets
  would drop into a wildlife-style roam-and-react system first.
