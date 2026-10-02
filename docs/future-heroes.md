# Future heroes: player characters by compatibility

Every hero and player-character sprite in the local collection
(`I:\game assets`), ranked by how well it would walk the current map types
of every randomizer and maze scene. Assessed 2026-10-01. Monsters, enemies,
NPCs, and animals are in `docs/creatures-all.md`.

## What a hero has to match

The player is the Painted Lands walker (`assets/pack/character_sprite_sheet.png`,
6 x 4 frames of 16 x 32: four directions, a 15 x 24 px figure, a soft dark
maroon outline, painterly shading). It walks every scene: the Painted Lands
ones (`randomizer-paintedlands`, `-greencaves`, `-paintedlands-farm`,
`-paintedlands-forest-farm`, `maze-forest`, `maze-farm`, `maze-greencaves`:
about 211 map types, all top-down 3/4 on a 16 px grid) and the Pixel
Crawler ones (`randomizer-pixelcrawler`, `maze-pixelcrawler`: 40 map types,
the same view, heavy-outlined art whose creatures stand about 30 px).

A hero is judged as a walker for those maps:

- **Style** (27): outline, shading, palette, and proportions next to the
  family of maps it would walk (Painted Lands: soft outlines, painterly,
  muted; Pixel Crawler: heavy dark outlines, high contrast).
- **Scale** (13): figure height against the 24 px walker and the 16 px grid
  (Painted Lands), or the 30 px creatures (Pixel Crawler).
- **View and directions** (18): top-down with four directions is what the
  maps need (eight scores the same); left and right only (flipped for up and
  down) scores about half; side-view platformer and front-facing battler
  sprites score near nothing.
- **Animations** (17): idle, walk or run, attack, hurt, death, and actions
  (tools, fishing, casting, rolling).
- **Variety** (15): how many heroes, or a paper doll that makes many.
- **Rules** (10): AGENTS.md. Painted Lands and Pixel Crawler are the only
  official packs and never share a map (10 on their own family's maps);
  Cozy Farm is allowed for animals only. Any other pack would need a rule
  change the way Cozy Farm's animals got one (3). Mana Seed (not to be
  used), Time Fantasy (not suitable), and Mystic Woods (deprecated) are
  barred (0).

Each pack was measured (a frame cut from its sheets, the figure's opaque box,
directions and animations from the files) and its figures viewed at 1:1 and
3-4x on Forest lawn and on Pixel Crawler grass beside the walker.

## The ranking

| # | Hero | Pack (path under `I:\game assets`) | Best on | View, directions | Figure (px) | Animations | Variety | Rules | Score |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Cozy People villager (paper doll) | Cozy People, shubibubi (`cozy people art pack/`) | Painted Lands | top-down, 4 | 12-15 x 19-21 (32 x 32 cells) | walk 8 frames, jump, pick up, carry, sword, block, hurt, die, pickaxe, axe, water, hoe, fishing | 8 bodies x 19 clothes x 15 hair x 15 accessories x 14 eye colors | other pack (same artist as the Cozy Farm animals already used) | 89 |
| 2 | Archer, cloaked figure, dark knight, fire knight, healer, mage, samurai | Painted Lands RPG Characters, antarcticbees (`antarcticbees asset packs/RPG Characters by antarcticbees/`) | Painted Lands | top-down, left and right | 16-35 x 25-29 (32 x 32, the knights and samurai 48 x 32) | walk, one or two attacks (with effects), hurt, defeat; dash (samurai), healing (healer), magic arrows (archer) | 7 classes | official | 84 |
| 3 | Farmer | Painted Lands Farm - 4 Seasons (`antarcticbees asset packs/FULL VERSION Farm - 4 Seasons.../farmer/`) | Painted Lands | top-down, 4 | 25 x 26 (32 x 32) | idle, walk, axe, hoe, watering, fishing | 1 | official | 81 |
| 4 | Beastmaster, sorcerer, swashbuckler, and a fox | Fantasy RPG heroes pack (`fanatical bundle packs/RPG Game Builder Assets Kit/Fantasy RPG heroes pack/1x/`) | Painted Lands | top-down, 4 | 15 x 15-20 (48 x 48 cells) | idle, walk, melee, ranged, cast, roll or dash, hit, die | 4 | other pack | 80 |
| 5 | The walker (now) | Painted Lands Forest (`antarcticbees asset packs/The Painted Lands - Forest Tileset/character_sprite_sheet.png`) | Painted Lands | top-down, 4 | 15 x 24 | idle and walk only | 1 | official | 76 |
| 6 | 57 characters (knights, ninjas, villagers, monks...) | Ninja Adventure, Pixel-boy (`NinjaAdventure/Actor/Characters/`) | Pixel Crawler | top-down, 4 | 14-16 x 15-16 (16 x 16) | walk, idle, attack, jump, dead, item, two specials; a faceset each | 57 | other pack | 75 |
| 7 | Angler, doctor, girl 1, girl 2, old man, smith, witch | Painted Lands NPC - Characters (`antarcticbees asset packs/FULL VERSION NPC - Characters by antarcticbees/`) | Painted Lands | top-down, left and right | 14-23 x 23-29 (32 x 32) | idle, walk, one action each (fishing, potion, butterfly, cane, anvil, broom) | 7 | official | 72 |
| 8 | Knight, rogue, wizard | Pixel Crawler FREE (`pixel crawler/Pixel Crawler - FREE - 1.8/Heroes/`) | Pixel Crawler | top-down, left and right | 19-25 x 29-32 (32 and 64 px cells) | idle, run, death; weapons on their own sheets | 3 | official | 71 |
| 9 | Hero | Mystic Woods 2.2 (`mystic_woods_2.2/sprites/characters/player.png`) | Painted Lands | top-down, down, side (flipped), up | 13 x 21 (48 x 48) | idle, move, attack in three directions, death | 1 | barred (deprecated) | 67 |
| 10 | 32 heroes, 24 military, 16 NPCs, 8 bonus | Time Fantasy characters, finalbossblues (`Time Fantasy packs/timefantasy_characters/`; the same art in `RPG Game Builder Assets Kit/80+ RPG Characters with Animations/`) | Painted Lands | top-down, 4 | 15-17 x 28-31 (26 x 36) | walk 3 frames, emotes, one weapon pose | 80 | barred (not suitable) | 67 |
| 11 | About 80 heroes and townsfolk | Fantasy Dreamland Characters, ElvGames (`fanatical bundle packs/Fantasy Dreamland Characters Pocket Pack/Character Sprites 1-2/`, 24 px set) | Pixel Crawler | top-down, 4 | 12 x 17 (24 x 24) | walk 3 frames; side-view battler sheets | 80 | other pack | 63 |
| 12 | Hero in 4 colors (day and night) | Sengoku Adventure, pixeljad (`mega 12 pack - by pixeljad/.../SENGOKU ADVENTURE TILESET/`, farming in `SENGOKU - EXPANSION - FARMING/`) | Painted Lands | top-down, 4 | 17 x 31 (20 x 32) | walk 3 frames, stand; dig, harvest, sow, water (one facing) | 1 | other pack | 62 |
| 13 | 6 elves, 8 human heroes, 12 base bodies | Mini Adventure Heroes (`complete rpg creator bundle/mini adventure heroes elves|humans/`) | Pixel Crawler | top-down, 4 | 15 x 15-16 (16 x 16) | walk 4 frames, hurt, dead | 14 + bases | other pack | 62 |
| 14 | Archer-swordsman | Survival game Godot series art (`survival game godot series art/survivalgame-player-green.png`) | Pixel Crawler | top-down, 8 | 13-14 x 18-19 (32 x 32) | walk, sword and bow attacks (8 directions), hurt, death | 1 | other pack | 59 |
| 15 | Human (paper doll), goblin | Sunnyside World (`sunny side world/Sunnyside_World_ASSET_PACK_V2.1/.../Characters/`) | Painted Lands | left and right | 11-18 x 16 (96 x 64 strips) | 20 actions: idle, walk, run, jump, roll, attack, hurt, death, axe, carry, cast, dig, hammer, mine, reel, swim, water... | 6 hairstyles + tools | other pack | 56 |
| 16 | 17 classes x 2 | Pixelart Medieval Fantasy Characters (`Pixelart_Medieval_Fantasy_Characters_Pack/Characters/`) | Pixel Crawler | side view, faces right | about 34 x 47 (64 x 64) | idle, run, dash, three unarmed and three weapon combos, hit, dead, banner | 34 | other pack | 53 |
| 17 | Player | Harvest Tiny Farm, pixeljad (`mega 12 pack - by pixeljad/.../HARVEST TINY FARM/PLAYER/`) | Pixel Crawler | top-down, 4 | 12-14 x 15-16 (16 x 16) | walk 3 frames, tool swing | 1 | other pack | 50 |
| 18 | 4 classes x 10 costumes | COMPLETE Pixel Character Animations (`fanatical bundle packs/RPG Game Builder Assets Kit/COMPLETE Pixel Character Animations/`) | Pixel Crawler | side view, faces right | 25 x 40 (64 x 48) | a full action set | 40 | other pack | 50 |
| 19 | Blood mage, druid, magic rogue, viking | AfGameAssets RPG Top-Down Characters (`complete rpg creator bundle/pixel art rpg top down characters/`) | Pixel Crawler | top-down, 4 | 25-30 x 34-37 (64 x 64) | idle, walk, attack, death | 4 | other pack | 49 |
| 20 | 18 modern townsfolk, a witch | The Japan Collection: JRPG Characters (`fanatical bundle packs/RPG Game Builder Assets Kit/The Japan Collection- JRPG Characters Asset Pack/`) | Pixel Crawler | top-down, 4 | 14 x 32 (32 x 32) | walk 8 frames | 18 | other pack | 49 |
| 21 | 20 heroines | Girl Power Packs 1 and 2 (`complete rpg creator bundle/girl power pack 1|2/`) | neither | 3/4, 5 drawn directions (8 mirrored) | 55-67 tall | idle, go, attack, death | 20 | other pack | 48 |
| 22 | Main character | Huge Asset Pack, s4m_ur4i (`huge asset pack/`) | neither | side-view platformer | 13 x 22 (20 x 24) | idle, run, dash, jump, swim, dig, fish, sleep, attack, hurt, die, ladder | 1 | other pack | 43 |
| 23 | 6 modern people | Kenney RPG Urban Pack (`kenney game assets all-in-1/.../2D assets/RPG Urban Pack/`) | neither | top-down, 4 | 12 x 13-15 (16 x 16) | walk 3 frames | 6 | other pack | 43 |
| 24 | 5 premade + parts | Pixel Art Modular RPG Characters, Eder Muniz (`fanatical bundle packs/RPG Game Builder Assets Kit/Pixel Art Modular RPG Characters/`) | neither | side view | 18 x 18 (36 x 24) | a side-view set, no outline | 5 + parts | other pack | 41 |
| 25 | Knights, wizard, villagers; a paper doll | Kenney Tiny Dungeon, Roguelike Characters (`kenney game assets all-in-1/.../2D assets/`) | neither | front-facing only | 14-16 x 12-16 | none | 20 + parts | other pack | 31 |
| 26 | Hero, cultists | Mighty Pixel pocket pack (`mighty pixel game asset pocket pack/Hero/`) | neither | side view (shipped 4x) | 10 x 21 native | idle, run, attack, slide, roll | 1 | other pack | 29 |
| 27 | 3 runners | Pixel Art Infinite Runner (`Pixel Art Infinite Runner - Pack/`) | neither | side-view runner | 11-14 x 16-19 | run, jump | 3 | other pack | 29 |

Not scored (no walking hero for these maps):

- **Not pixel art at this scale**: 2D Fantasy Characters V2, Cute RPG Game
  Builder (both copies), Orc Conqueror, the Human Fantasy / Monster Creature /
  Supermix Flash packs, the 2D Top Down Character Bundle (vector, also given
  as anti-aliased 64 px downscales), gdm-2d-heroes, gdm-character-bundle-2023,
  gdm-custom-soldiers, Northfolk Character Creator (94 px painted, 8
  directions).
- **Battle-screen battlers** (no walk directions): Time Fantasy side-view
  battlers (80), Pixel Battlers 1-6, Tyler Warren RPG Battlers, Little
  Monsters and Robots.
- **Sci-fi or modern**: Pixel Art Cyberpunk Characters, Futuristic
  Characters, Robots, Tiny Tales Code Ark, VisuStella Cursed School and Urban
  City (60 px RPG Maker figures).
- **No hero art**: Mana Seed collection (tiles only here), Children
  Characters (voices and portraits), Ultimate RPG pack (portraits),
  HAS Overworld, the gamedevmarket character bundles (voice packs).

## Why the order falls as it does

- **Cozy People leads on fit.** The only paper doll that is top-down, four
  directions, and soft: muted colors and a gentle outline beside the Painted
  Lands art, 20 px figures that stand just under the walker, thirteen actions
  (a sword, a block, hurt and death as well as the farm tools and fishing),
  and thousands of looks. It is shubibubi's, the artist of the Cozy Farm
  animals that already live on the Painted Lands maps, so it matches them
  exactly. Its only cost is the rules: Cozy Farm is allowed for animals only,
  and Cozy People is not allowed at all.
- **The best heroes allowed today are the Painted Lands RPG characters.**
  Drawn by the walker's own artist, with complete combat sets (walk, two
  attacks, hurt, defeat), but they face only left and right, so walking up or
  down plays the side walk. The **farmer** is the one allowed figure with four
  directions besides the walker, and he works tools and fishes, but has no
  combat. The walker itself has only an idle and a walk.
- **Fantasy RPG heroes pack** (and its asset pack's townsfolk) is the closest
  outside art to Painted Lands: warm brown soft outlines and muted chibi
  figures, four directions, a full action set, but only four heroes, and its
  figures stand 15-20 px.
- **For the Pixel Crawler maps**: the Pixel Crawler knight, rogue, and wizard
  are the pack's own (heavy outlines, 30 px, as tall as its enemies) but face
  left and right and have only idle, run, and death. **Ninja Adventure** is
  the strongest four-direction alternative (57 heroes, full actions), but its
  16 px flat-bright chibis are half the height of the Pixel Crawler enemies.
- **Barred packs** score on looks but get nothing for the rules: the Mystic
  Woods hero is close to the walker in style and scale, Time Fantasy's are
  crisp and taller (30 px).
- **The bottom of the list** is the wrong view (side-view fighters,
  platformer heroes, runners, front-facing tiles) or the wrong scale (Girl
  Power's 60 px heroines).

## Recommendations

- **Painted Lands maps, within today's rules**: give the walker the RPG
  characters as alternates (a class choice: archer, mage, healer, samurai,
  fire knight, dark knight, cloaked figure), playing their side walk for up
  and down. The farmer suits the Farm maps and mazes.
- **Painted Lands maps, if a pack is added**: Cozy People, as a paper-doll
  character creator, would give four-direction heroes with combat and tools
  in the Cozy Farm animals' own style; the Fantasy RPG heroes pack is the
  next best.
- **Pixel Crawler maps**: walk the Pixel Crawler knight, rogue, or wizard
  there instead of the Painted Lands walker, so each map stays in one pack's
  style (the creature ranking notes the same). If four directions matter
  more than style, Ninja Adventure's heroes are the option, at a scale cost.
