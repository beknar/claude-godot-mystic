# Local assets: what fits with Painted Lands

A ranked assessment of the local collection at `I:\game assets` (everything
except `antarcticbees asset packs` and the `mystic_woods_2.1` / `2.2`
folders) against the Painted Lands packs this project uses:

- **Forest** (`TILESET_brighter.png`), **Green Caves**, **Cozy Cottage**, and
  the not-yet-used **Farm – 4 Seasons** (see `docs/painted-lands-art-fit.md`).

What each pack would give the project is in the last column of the ranking.
Assessed 2026-09-28.

## How it was judged

1. **Scan.** About 170,000 PNGs in 35 top-level folders. Bundles were split
   into their packs (301 packs). 179 packs are not map art (audio, UI kits,
   icons, portraits, characters, platformer and space-shooter kits,
   isometric and 3D) and are listed at the end. For the other 122 packs, the
   15 largest tile-like sheets (UI, icons, characters, and animation frames
   left out by name) were measured. The `ultimate rpg pack` zips were
   unpacked to a temporary folder for this, not in the collection.
2. **Color.** For each sheet: the median RGB distance from its pixels to the
   nearest color of each Painted Lands sheet, the share within 24, and mean
   saturation and brightness (the same method as the art-fit reference; our
   Forest sheet has saturation 0.37, Farm 0.47). A pack's number is the mean
   of its five closest sheets.
3. **Style and scale.** The best sheet of every candidate was viewed next to
   Painted Lands art, and at 1:1 next to a Forest tree, a Forest house, and
   the 32 px walker. Upscaled art was detected (every pack but a few sheets
   is native pixel size).

Color alone misleads: dark, few-color packs score close to anything, while
Mana Seed's yellow-greens score far from the Forest palette although its
style is the nearest. **The ranking weighs style and scale first** (painterly
shading, outline weight, detail density, 16 px grid, top-down view), then
color, then how much the pack adds.

Color numbers (median distance, share within 24 in brackets; lower and
higher is closer), for the packs that matter:

| Pack | Forest | Green Caves | Farm | Cozy Cottage | Saturation |
|---|---|---|---|---|---|
| Mana Seed – Winter Forest | 13.3 (97) | 12.6 (96) | 8.5 (98) | 12.0 (94) | 0.26 |
| Mana Seed – Grand Library | 13.1 (90) | 14.1 (95) | 8.2 (99) | 13.3 (92) | 0.26 |
| Mana Seed – Eternal Dungeon | 13.9 (81) | 13.3 (93) | 7.4 (98) | 13.1 (84) | 0.34 |
| Mana Seed – Autumn Forest | 18.7 (79) | 17.1 (74) | 9.3 (96) | 11.9 (89) | 0.43 |
| Mana Seed – Summer Forest | 19.6 (60) | 19.9 (65) | 12.3 (86) | 17.3 (71) | 0.53 |
| Mana Seed – Cozy Furnishings | 18.4 (69) | 19.5 (71) | 10.6 (97) | 14.8 (91) | 0.51 |
| Time Fantasy tiles | 12.8 (83) | 15.8 (82) | 9.5 (98) | 11.8 (85) | 0.39 |
| Cozy Farm (shubibubi) | 16.0 (79) | 23.7 (51) | 8.8 (96) | 10.5 (88) | 0.50 |
| Pixel Crawler – Forge | 13.0 (78) | 16.4 (82) | 5.9 (89) | 12.2 (79) | 0.49 |
| Pixel Crawler – Cemetery | 16.9 (87) | 16.7 (93) | 8.9 (100) | 14.3 (88) | 0.36 |
| Pixel Crawler – Fairy Forest | 18.1 (84) | 16.2 (78) | 12.8 (89) | 19.2 (77) | 0.57 |
| Acasas – Farm Life | 14.4 (88) | 14.7 (86) | 8.3 (100) | 10.4 (92) | 0.42 |
| Acasas – Medieval Interiors | 16.0 (91) | 11.7 (97) | 6.0 (100) | 10.8 (100) | 0.48 |
| RPG Worlds – Deep Cave | 17.4 (81) | 11.8 (90) | 9.8 (92) | 16.4 (87) | 0.20 |
| pixeljad – Village Top Down | 13.3 (91) | 13.7 (80) | 9.0 (92) | 8.2 (88) | 0.44 |
| HAS Overworld | 15.1 (71) | 16.6 (72) | 12.0 (78) | 8.9 (73) | 0.53 |
| Ninja Adventure | 18.5 (64) | 17.4 (69) | 12.7 (71) | 15.0 (84) | 0.38 |
| Sunnyside World | 22.5 (52) | 32.9 (29) | 19.2 (69) | 15.8 (67) | 0.52 |

Nearly everything sits closer to Farm (larger, more saturated palette) than
to Forest.

## Ranking

| # | Pack (location) | Fit | Works with | What the project would get |
|---|---|---|---|---|
| 1 | **Mana Seed tileset collection**, 28 sets (`complete rpg creator bundle/mana seed pixel art tileset collection`) | **Strong.** Hand-shaded 16-bit SNES style, 16 px, native size, the same detail and outline weight as Painted Lands; greens a little yellower. | **Forest** and **Farm** (all four season forests, homes, fences, bridges, garden, village accessories); **Green Caves** (Muddy Cave, Eternal and Castle Dungeon); **Cozy Cottage** (Cozy Furnishings, Grand Library, Castle Interiors, Animated Candles) | Whole seasons (Spring, Summer, Autumn, Winter Forest, with tree walls and animated water) that match Farm – 4 Seasons; new biomes (Arctic Woodland, Desert Sands, Rainforest Jungle, Tropical Shores, The World Tree); four house kits with interiors (Thatch Roof, Timber Roof, Half-Timber, Stonework) plus Steampunk Manor and Airship; dungeons and a cave; more furniture, candles, a library; fences, walls, bridges, a royal garden with fountains, village accessories (banners, barrels, crates, signs). The collection the itch.io search ranked first is already here. |
| 2 | **Time Fantasy tiles** (`Time Fantasy packs/TimeFantasy_TILES_6.24.17`) | **Good.** 16 px, native, shaded and detailed, a little cleaner and lighter than Painted Lands; saturation 0.39 (Forest 0.37). | **Forest** and **Farm** (outside: terrain, cliffs, forests, props); **Cozy Cottage** (house insides, kitchen); **Green Caves** weaker (its caves and mines are warm orange-brown) | Houses, shops, and castles inside and out, deserts, a world map, animated doors, traps and switches for puzzles, kitchen tiles, lots of small props (signs, barrels, pots, rocks, sprouts). Characters in the same style are in `timefantasy_characters`. |
| 3 | **Cozy Farm** by shubibubi (`cozy farm art pack`) | **Good with care.** 16 px, soft and muted olive greens, but no outlines, so it reads flatter. | **Farm** (seasons: spring, summer, fall, winter flowers, trees, gates, streetlights), **Forest**; **Cozy Cottage** for its buildings' insides | Animated animals (turkey, sheep, goat, pig, cow, bunny, chicken, babies; walk and sleep), animated workshop machines (butter churn, cheese press, cloth maker, spindle), market lights, tree shake animations, crops. Its animals could stand in for or join the code-drawn wildlife. |
| 4 | **Pixel Crawler** by Anokolisa: Cemetery, Forge, Sewer, Fairy Forest, Desert, Free, Farm Game Assets 2.0 (`pixel crawler`) | **Fair.** 16 px, native; darker and flatter, heavier dark outlines; Fairy Forest has big painterly trees. | **Green Caves** (cemetery, sewer, forge as underground areas), **Cozy Cottage** (forge and crafting props), **Farm** (Farm Game Assets) | New dungeon kinds (cemetery, sewer, forge with lava), crafting stations (anvil, furnace, workbench), gravestones, a desert. Best as props and as separate map types rather than beside Forest lawn. |
| 5 | **Acasas / The Game Assets Mine** series: Farm Life, Medieval Interiors 1 and 2, Green Temple, Dungeon Level 4, Wasteland, Mining Crafting, Rogue-like RPG (`complete rpg creator bundle/pixel art …`) | **Fair.** Detailed shading and a close palette (Medieval Interiors: 6.0 to Farm, 100 % within 24), but single PNGs per object on a larger grid (64 px floor tiles, 32 px cells). | **Cozy Cottage** (medieval interiors: stone walls, beams, basements), **Farm** (Farm Life crops and trees), **Green Caves** (Green Temple, Dungeon Level 4) | Stone and timber interior walls, basements, a temple, crops. Props can be used at their size; floors and walls need the 16 px grid checked or would be 2×2 cells. |
| 6 | **pixeljad MEGA 12** top-down sets: Village Top Down, Harvest Tiny Farm, Winter Village, Sengoku Adventure and Farming, Ancient Egypt, Plaguevania (`mega 12 pack - by pixeljad`) | **Fair to weak.** Top-down, native size, chunkier shapes, some sets saturated (Tiny Volcano 0.57, Ancient Egypt 0.56). Tiny Forest, Tiny Beach, Snowy Forest, Super Dungeon 16 are side-view (platformer). | **Farm** winter (Winter Village), **Farm** (Harvest Tiny Farm), **Cozy Cottage** (Village Top Down: 8.2 to Cozy) | A Japanese village (Sengoku), an Egyptian set, day and night variants of village pieces. |
| 7 | **RPG Worlds**: Ancient Forest, Deep Cave, Strange Land, Wetland (`fanatical bundle packs/RPG Game Builder Assets Kit`) | **Style strong, scale wrong.** Painterly, dark, moody (Deep Cave is close to Green Caves in color: 11.8, 90 %), but drawn at about twice our scale (32 px tiles; a Deep Cave block is two of our cells). | **Green Caves** and **Forest** only as oversized set pieces | Great material for a separate 32 px project; here only a giant tree or a cave mouth as a landmark. |
| 8 | **HAS Overworld 2.1** by Aleksandr Makarov (`HAS Overworld 2.1`) | **Weak as map art.** 16 px, but world-map scale (tiny trees and towns), bright (value 0.73). Attribution required. | a separate **world map** screen between Painted Lands maps | Grass, dirt, sand, ice, lava, marsh, and cave biomes for an overworld. |
| 9 | **Ninja Adventure**, **Sunnyside World**, **Kenney** Tiny Town, Tiny Dungeon, Roguelike, RPG Urban, **cute rpg game builder**, **mini city**, **Roguelike Dungeon** (mighty pixel) | **Poor.** Flat colors, bright, simple shapes; a different look. | none | Nothing that fits; keep for other projects. |
| 10 | **RPG Maker 32/48 px sets**: all in one pack rpg maker, Beowulf mini dungeons, The Japan Collection (Overgrown Backstreets, Kanagawa), VisuStella worlds (`humble bundle - asset compendium`) | **No.** Different grid (32 or 48 px) and style. | none | — |
| 11 | **Not pixel art at this scale**: Northfolk Tiles (painted, high-res), 2D Buildings Town, Tilemap Top Down Vector, Fantasy RPG asset, interior, and snow packs (3× upscaled flat art), Nature Trees | **No.** | none | — |
| 12 | **ultimate rpg pack** (CaptainSkeleto and others): Forest, Flower, Fruit, Ore, Rock, Desert, Halloween, Tiny World, pumpkins; rocks, dungeon entrance, chests, pots | **Mostly no.** Saturated cartoon icons and small sprites (Flower, Fruit, Tiny World: distance 42+). The `rocks` and `dungeon entrance` sets are closer (15.5 and 12.6 to Forest). | **Green Caves** at most (rocks, dungeon entrance) | A few rocks and a dungeon door. |

## How the best ones pair with each Painted Lands pack

| Painted Lands pack | Use first | Also |
|---|---|---|
| Forest | Mana Seed Summer and Spring Forest, Bridges & More, Fences & Walls, Village Accessories, Royal Garden | Time Fantasy outside props |
| Farm – 4 Seasons | Mana Seed Spring, Summer, Autumn, Winter Forest and Arctic Woodland (seasons that line up), Thatch and Timber Roof Homes | Cozy Farm animals, machines, and seasonal flowers; Acasas Farm Life; pixeljad Winter Village |
| Green Caves | Mana Seed Muddy Cave, Eternal Dungeon, Castle Dungeon | Pixel Crawler Cemetery, Sewer, Forge (as their own map types); Acasas Green Temple |
| Cozy Cottage | Mana Seed Cozy Furnishings, Grand Library, Castle Interiors, Animated Candles, and the home kits' interiors | Time Fantasy inside and kitchen; Acasas Medieval Interiors |

## Before using any of them

- Read each pack's license (several are in the folders: HAS Overworld needs
  attribution to Aleksandr Makarov; the Samvieten license forbids resale and
  easy extraction; Pixel Crawler packs have `Terms.txt`; Mana Seed and Time
  Fantasy have their own terms on their stores).
- Copy only what is used into `assets/pack/<name>/` (git-ignored) and credit
  it in README.md.
- Put a sample on Forest lawn and on the cave floor and compare, as in
  `docs/painted-lands-art-fit.md`; add the results there once a pack joins
  the project.

## Not map art (skipped)

179 packs, by kind; useful for other parts of a game but not for tile fit:

- **Audio:** gamedevmarket music and SFX, mighty game music pack, pixabay
  audio, Fanatical music and SFX bundles, Humble music and SFX packs.
- **UI and icons:** GUI kits, HUD, dialogue boxes, inventory, skill and stat
  icons, progress bars, avatar and portrait sets, fonts.
- **Characters and monsters:** hero, NPC, monster, battler, and character
  creator packs (Time Fantasy, Mana Seed, and Cozy People characters would
  pair with their own tilesets; the project's walker is the Painted Lands one).
- **Other genres:** platformer, infinite runner, space shooter, tower
  defense, racing, match-3, puzzle kits; cyberpunk and sci-fi sets;
  isometric sets; 3D platformer assets and Epic Games media packs.
- **Effects:** Kenney particle pack, VFX and spell sheets.
