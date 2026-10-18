# UI assets: 2D game UI in the collection, by fit

Every 2D UI pack in the local collection (`I:\game assets`), and which of
this project's art families each would fit: **The Painted Lands** (PL:
Forest, Green Caves, Farm, Cozy Cottage, `node-gates`) or **Pixel Crawler**
(PC). Assessed 2026-10-17. Paths below are relative to `I:\game assets`.

## What a UI pack has to match

- **Painted Lands**: 16 px tiles, soft dark maroon or plum outlines
  (`#561328`, `(64,11,41)`, `(78,37,54)`; Cozy Cottage `#2C0F15`), painterly
  muted shading, about 140 colors per sheet.
- **Pixel Crawler**: 16 px tiles, near-black outlines (`#141412`,
  `(14,17,19)`, `#151A16`), high contrast, 26 to 72 colors per sheet.
- **Scale**: the camera zooms 5x (each art pixel is 5 screen pixels on the
  3440 x 1440 viewport), so only true low-res pixel art drawn at 1x (to be
  scaled by an integer) sits beside the world. High-res painted or vector
  UI reads as smooth art next to the chunky tiles; at best it serves a
  full-screen menu drawn at screen resolution.
- **Rules** (AGENTS.md): Painted Lands and Pixel Crawler are the only
  official packs and never share a map; Cozy Farm is allowed for its animals
  only; Mana Seed is not to be used, Mystic Woods is deprecated, Time Fantasy
  is not suitable. Any other pack's UI would need a rule change the way Cozy
  Farm's animals got one.

**How each pack was judged.** Sample sheets were measured with PIL: opaque
color count, share of semi-transparent (anti-aliased) edge pixels, whether
the PNG is an exact integer upscale of a smaller native image, outline color
(the most common color on the silhouette edge), and saturation. The
promising packs were then viewed at 3-4x nearest neighbour beside crops of
the Painted Lands and Pixel Crawler sheets and the walker.

## Main findings

- **Neither official pack has any UI art.** No Pixel Crawler sub-pack (FREE
  1.8, Cemetery, Desert, Fairy Forest, Forge, Sewer, Farm 2.0) has a HUD,
  panels, or fonts; Anokolisa's separate Pixel Crawler UI pack is not in the
  collection. The antarcticbees packs have no panels, bars, or fonts either,
  but they do have item icons in their own style.
- **Painted Lands**: item icons from its own Farm and Cozy Cottage sheets;
  the "Fantasy RPG" family (one artist, a plum outline right beside PL's) for
  icons, tiny portraits, bubbles, and animated pickups; Cozy Farm's `ui/`
  for the HUD frame, hotbar, clock, buttons, and an alphabet.
- **Pixel Crawler**: its own weapon sheets for icons; Ninja Adventure's HUD
  (hearts, dialog box, 9-slices, font); Kenney's Pixel Adventure UI
  (thick-outline set); Admurins and Beowulf icons; Mighty Pixel status icons.
- **Both**: Kenney's pixel input prompts and cursors, Tiny Tales' controller
  prompts, and Kenney Fantasy UI Borders (tinted, halved).
- **Gaps**: no bitmap font suits Painted Lands (Cozy Farm has a lowercase
  alphabet and clock digits only), and nothing allowed today gives Painted
  Lands panels or bars: they would be drawn at 1x in the pack's colors (rule
  5), or Cozy Farm's UI allowed the way its animals were.
- Every high-res kit (the RPG creator bundle's GUI kits, the Humble gdm
  kits, painted portraits and icons at 128-512 px) is menus only at best.

## Recommendations

**Painted Lands maps**
- Item icons: antarcticbees Farm `crops.png` and `fishes.png`, Cozy Cottage
  `decoration.png` smalls (official, an exact match).
- Icons beyond those: Fantasy RPG icon pack (389 icons at 16 px).
- HUD frame, inventory, hotbar, clock, buttons, season and weather icons:
  Cozy Farm `ui/` (needs the Cozy Farm rule widened from animals to UI).
- Emotes: Cozy People `emoticons.png` or the Fantasy RPG heroes pack's
  bubbles and talking emote.
- Portraits: Fantasy RPG heroes pack (16-18 px, 4 faces) for HUD heads, SC
  Pixel Portraits 1 (64 px) for dialog.
- Without any rule change: tint Kenney Fantasy UI Borders to PL maroon for
  frames, and draw bars and slots in PL colors.

**Pixel Crawler maps**
- Item icons: Pixel Crawler's weapon sheets (official); Admurins, Beowulf's
  monster loots and runes for more.
- HUD: Ninja Adventure (hearts, dialog box with faceset, 9-slices, font) and
  Kenney Pixel Adventure thick-outline (slots, bars, ribbons).
- Buffs: Mighty Pixel status effects (16 px).
- Dialog portraits: CaptainSkeleto (64 px).
- Window skins: Tiny Tales Code Ark, recolored from neon to PC's steel and
  bone.

**Either family** (menus and tutorials): Kenney Input Prompts Pixel 16,
1-Bit Input Prompts, Cursor Pixel Pack; Tiny Tales keyboard and pad prompts.

**Full-screen menus at screen resolution** (a deliberate style choice, not a
match): Dark Age mobile UI or the MMORPG UI kit's parchment windows for
Painted Lands; RPG and MMO UI 4 or Fantasy UI Bloodline for Pixel Crawler.

## Pixel-art packs (outside the bundles)

Every top-level folder except `complete rpg creator bundle`, `fanatical
bundle packs`, and the two `humble bundle` folders (tables below).

| # | Pack and path | Contents | True pixel? | Native size | Outline and palette | Theme | Verdict | Rule status |
|---|---|---|---|---|---|---|---|---|
| 1 | **antarcticbees Farm 4 Seasons**: `antarcticbees asset packs/FULL VERSION Farm - 4 Seasons…/tilesets/crops.png`, `fishes.png` (and Cozy Cottage `decoration.png`) | About 18 crop harvest icons plus seed-packet icons (126 cells with growth stages), 4 fruits and a sack, 8 fish; small potions and books in decoration. No panels, bars, fonts, or emotes; `farmer/` holds tool animations only | Yes. 66 to 226 colors, about 0 AA (crop shadows are semi-transparent; a no-shadow copy exists) | 16x16 | Soft dark-red or brown outline, muted, painterly | Farm | **Fits PL** (exact match): every inventory and item icon on PL maps | Official |
| 2 | **Cozy Farm UI** (shubibubi): `cozy farm art pack/ui/UI.png`, `UI_all.png`, `inventory.png`, `inventory_chopped.png`, `items.png`, `button maker.png`, `logo maker.png`, `item list.txt` | Wood inventory panel with 8 tab icons (bag, tools, heart, quest, map, star, settings, target), 10-slot hotbar, clock and date plates with a digit font (mon to sun, 0 to 59), 3 bars plus a color stamina gauge, 4 vertical meters (heart and star caps), season banners, weather and status icons, wood buttons (start, exit, new save, back; blank plank), a rounded lowercase pixel alphabet in 2 sizes, a wooden oval logo plate, 98 item icons (crops, fruit, dairy, eggs, wool, gems, flowers, mushrooms, fish bait; names in `item list.txt`), item silhouettes | Yes. UI.png 46 colors, 0 AA; items 884 colors with 0.3 % partial alpha | 16 px slots and icons; panel 300x125; buttons 48x32 | Dark brown outline (`#503e36`, `#5c4435`), warm tan wood, no black | Cozy farm | **Fits PL**: the best HUD frame and menus found; warm wood and brown outlines sit right on PL ground. Items a little brighter than antarcticbees but close. Wrong for PC (too soft, no black line) | Cozy Farm is animals only today: needs a rule change |
| 3 | **Cozy People emoticons** (shubibubi): `cozy people art pack/emoticons.png` | 30 speech-bubble emotes (dots, heart, anger, sweat, tears, sleep, shades, ...) | Yes. 11 colors, 0 AA | 16x16 | Beige bubble, soft maroon or grey outline (`#7d4040`, `#5b5a5c`) | Cozy | **Fits PL** (emotes over NPCs; the maroon line matches). Too soft for PC | Not official (sibling of Cozy Farm) |
| 4 | **Ninja Adventure HUD and items** (CC0): `NinjaAdventure/HUD/` (Dialog/DialogBox, DialogBoxFaceset, ChoiceBox, Yes/No buttons, FacesetBox, DialogInfo; NinePathRect/DialogueBubble and FacesetBox; `Heart.png` in 5 states; LifeBarMini; Font/`font8x8.png`, `font24x30.png`, `NormalFont.ttf`; Tuto key prompts; Arrow), `NinjaAdventure - additional art/` (InventoryRect 9-slice, inventorySlot, healthbar), `NinjaAdventure/Items/` (95 icons: food, potions, scrolls, treasure, keys, weapons), 139 facesets under `Actor/*/Faceset*.png` | A full dialog kit, 9-slice boxes, hearts, a mini life bar, a pixel font (TTF and bitmap), 95 items, 139 portraits | Yes. 2 to 8 colors per element, 0 AA | Hearts 16x16, 9-slice 16 to 19 px, dialog 300x58, faceset 38x38, font 8x8 | Near-black `#141b1b` outline, flat cel shading, warm orange and teal | Ninja | **Fits PC** (heavy black line and contrast match; flatter and simpler than PC's shading). Not PL (black line, flat) | Not official; CC0 |
| 5 | **Kenney UI Pack – Pixel Adventure**: `kenney game assets all-in-1/…/UI assets/UI Pack - Pixel Adventure/Tilesheets/{Small,Large} tiles/{Thick,Thin} outline/tilemap_packed.png` (514 PNGs) | 9-slice panels (brown wood, steel, white), slots, round and square buttons, bar fills and caps (red, blue, green, brown), ribbons and banners, ring frames, arrows, check and cross, compass letters | Yes. 50 colors, 0 AA | 16x16 tiles (32 in Large) | Dark `#242b2c` outline (thick or thin), clean flat shading | Generic adventure | **Fits PC** (thick-outline set); menus only for PL (brown wood with the thin outline passes in menus). Generic but complete | Not official; CC0 |
| 6 | **Mighty Pixel pocket pack**: `mighty pixel game asset pocket pack/Pixel Art - Potions/Pixel Art - Potions.png`, `Pixel Art - Status Effects/Status Effects 16px.png` (also 32 px) | 20 potion icons; 20 status-effect icons (water, ice, fire, rock, lightning, wind, poison, curse, ...) | Yes. 66 to 107 colors, 0 AA | Potions 32x32; status 16x16 (and 32) | Black outline, saturated, glossy | Dark fantasy | **Fits PC** (status icons for a buff bar; potions as large slot icons). Too harsh for PL | Not official |
| 7 | **Sunnyside World UI**: `sunny side world/Sunnyside_World_ASSET_PACK_V2.1/Sunnyside_World_Assets/UI/` (76 files plus `9slice_box_white/`, 27 pieces) | 3 tiny 9-slice boxes, red/green/blue bars with 6 to 7 fill steps, 5 cursors, 4 hand pointers, 8 expression marks, 4 happiness faces, 12 tool icons, select-box corners, label pieces, confirm and cancel, timers, item discs | Yes. 2 to 9 colors, 0 AA | 7 to 19 px (bars 15x7, icons about 13 px) | Navy-black `#181425`/`#262b44` outline, bright Endesga-32 palette | Cozy farm, crisp | **Fits PC**; menus only for PL. Very small; brighter than both | Not official |
| 8 | **Kenney Fantasy UI Borders**: `…/UI assets/Fantasy UI Borders/PNG/{Default,Double}/…` (282 PNGs) | Ornate 9-slice borders, panels, dividers | Yes, but 1-color white and stored at 2x (48 px file = 24 px art) | 24 px art | None: pure white, meant to be tinted | Fantasy | **Both, menus only**: tint to the pack's outline (maroon for PL, near-black for PC) and halve to keep the grid true | Not official; CC0 |
| 9 | **Kenney Tiny Dungeon / Tiny Town**: `…/2D assets/Tiny Dungeon/Tilemap/tilemap_packed.png`, `Tiny Town/…` | About 132 tiles each, with small item icons (potions, swords, axes, keys, coins, hearts, shields, tools) | Yes. 27 to 33 colors, 0 AA | 16x16 | Dark plum `#3f2631` outline, flat, chunky | Micro dungeon and town | Menus only, or a last-resort PC fallback (simpler than PC) | Not official |
| 10 | **Kenney Input Prompts Pixel 16, 1-Bit Input Prompts, Cursor Pixel Pack**: `…/Icons/Input Prompts Pixel 16×/`, `…/Icons/1-Bit Input Prompts Pixel 16×/`, `…/UI assets/Cursor Pixel Pack/` | About 800 key, pad, and mouse prompts; about 800 x 2 (black, white) 1-bit prompts; about 220 cursors | Yes. 3 to 33 colors, 0 AA | 16x16 | Slate grey or 1-bit; black and white cursors | Neutral | **Both**, menus and tutorials | Not official; CC0 |
| 11 | **Kenney Emote Pack** (`pixel_style1`–`8` only): `…/2D assets/Emote Pack/Tilesheets/pixel_style*.png` | About 30 emote bubbles x 8 styles | Yes (the `vector_style` sheets are anti-aliased) | 16x16 | `#312d2d` outline, white bubble, flat glyphs | Generic | Fits PC (emotes); weaker than Cozy People for PL | Not official |
| 12 | **Kenney UI Pixel Pack**: `…/UI assets/UI Pixel Pack/Spritesheet/UIpackSheet_transparent.png` | Flat panels, buttons, arrows, checkboxes, sliders, hand cursors in 6 colors | Yes. 62 colors | 16 px | Light bevel, no dark line, bright | Casual mobile | Menus only (debug or options screens) | Not official |
| 13 | **CaptainSkeleto** (`ultimate rpg pack`): `portraits/Portrait Pack by CaptainSkeleto/` (39), `potions/`, `weapons/` (34), `spells/` (220), zips (Fruit, Ore, Fish, Shield, Magic Book, `books/Magic Books interface.zip`: 8 book-page panels 100x100) | Portraits, big item icons, spell icons, book UI pages | Yes, 0 AA, but 24 to 1,300 colors, heavily rendered | Portraits and icons 64x64 (fruit and ore 16 to 32 px; weapons 128 px) | Black outline, saturated, high detail | Dark RPG | **Fits PC for portraits only**; icons too large and detailed for 16 px slots. Not PL | Not official |
| 14 | **Pixel Crawler weapon sheets**: `pixel crawler/*/Weapons/*/*.png` (Wood, Bone, Hands, Cursed, Desert-Gold, Fire, Poison) | About 15 to 20 weapons, shields, and tools per set | Yes. 11 to 21 colors | Long items 16x32 to 16x48; shields 16x16 | `#141412` black outline (the pack's own) | Dungeon | **Fits PC**: the only in-pack icon source; long blades need a rotated or cropped slot view | Official |
| 15 | Survival-game tutorial art: `survival game godot series art/` | inventory-background, inventory-slot (16 px), 4 icons, randomitems | Yes (randomitems has AA shadows) | 16x16 | Pure black 1 px outline, 2 to 4 flat colors | Placeholder | Does not fit: tutorial-grade placeholders | Not official |
| 16 | Huge Asset Pack UI (s4m_ur4i): `huge asset pack/s4m_ur4i_huge-assetpack-ui.png`, `-ui-portraits.png`, `-ui-portrait-item.png` | Speech bubbles, round icons, portrait busts | **No**: vector (SVG and EPS supplied), 18 % partial-alpha AA, soft glows | About 120 px | Thick dark-navy vector stroke | Cartoon | Does not fit | Not official |
| 17 | Kenney vector UI (UI Pack, UI Adventure Pack, UI Pack – Adventure, Sci-fi, Game Icons, Generic Items, Board Game Icons) and `kenney_space-shooter-redux/PNG/UI` | Panels, buttons, icons | **No**: vector, 5 to 8 % partial alpha | 50 to 256 px | Smooth | Various | Does not fit | Not official |
| 18 | Time Fantasy: `Time Fantasy packs/timefantasy_characters/sheets/emote*.png`, `tf_svbattle/RMMV/system/States.png`, `guide.png` | The "emotes" are character pose sheets, not bubbles; States are battle status animations; guide is a tile guide | Pixel | 26x36 characters | Dark `#354048` outline | JRPG | No UI | Not suitable (project rule) |
| 19 | Mystic Woods 2.2: `mystic_woods_2.2/sprites/objects/objects.png` | Props only (chests, signs, logs) | Pixel | 16 px | Dark brown | Forest | No UI | Deprecated |
| 20 | No UI: `HAS Overworld 2.1` (overworld tiles), `mega 12 pack - by pixeljad` (12 tilesets; only fruit and farm-resource props), `Pixel Art Infinite Runner - Pack`, `Pixelart_Medieval_Fantasy_Characters_Pack` (its "Banners" are in-world standards), `Jewels and Gems` (300 px anti-aliased gems), `Multi_Platformer_Tileset_v2`, `SpaceShooter-Full`, `kenney_tower-defense-top-down`, `gamedevmarket assets` (audio only), `gen AI` (renders), `fonts/` (only `28 Days Later.ttf`, a grunge vector horror font) | — | — | — | — | — | No usable UI | — |

Pixel fonts found anywhere: Ninja Adventure `font8x8.png` and
`NormalFont.ttf` (PC), and Cozy Farm's rounded lowercase alphabet and clock
digits (PL; bitmap only, no punctuation seen). Every "fits" pick is native
1x art except Kenney Fantasy UI Borders (stored at 2x); Mighty Pixel potions
and CaptainSkeleto art are 32 to 64 px, so they suit large slots or
portraits only.

## Fanatical and Humble bundles

F = `fanatical bundle packs/RPG Game Builder Assets Kit/`, H = `humble
bundle - 2d game creation mega bundle/`, C = `humble bundle - asset
compendium/`.

| # | Pack (path) | Contents | True pixel? | Native size | Outline and palette | Theme | Verdict |
|---|---|---|---|---|---|---|---|
| 1 | **Fantasy RPG icon pack** (F) | 220 icons, 95 color variants, a 74-icon fishing set: 389 in all (weapons, tools, armour, rings, potions, coins, gems, food, bags, keys, scrolls, fish), each as 16, 32, and 48 px files and sheets | Yes. The 32 and 48 px files are exact 2x and 3x copies; 0 % semi-alpha; 7 colors per icon, 43 across the set | **16x16** (art about 15x15) | Soft dusty-plum outline `(82,51,63)`, muted warm shading | Fantasy RPG | **Fits PL**: same grid, an outline beside PL's maroon, painterly and muted. The best icon set found |
| 2 | **Fantasy RPG heroes pack** `1x/Character portraits & Emotes` (F) | 4 hero portraits (Fox, Sorcerer, Swashbuckler, Beastmaster), each with outline, no-outline, and framed versions; an empty 18x18 portrait frame; 3 speech bubbles (10x8, 16x14, 20x20); `Emote_talking` (5 frames of 16x14) | Yes. 7 to 13 colors, 0 % semi; the 2x folder is an exact double | 16 to 18 px portraits | Same plum outline and palette as #1 (51 colors across the pack) | Fantasy | **Fits PL**: tiny HUD party faces and a talk emote; the frame and bubbles can be 9-sliced. Only 4 faces |
| 3 | **Dungeon asset pack** `Objects and traps`, **Fantasy RPG asset pack** `Objects` (F) | Coins (bronze, silver, gold), keys, red/blue/green potions, chests: 4-frame 16x16 strips; 12 wooden signs with icons (sword, potion, book, skull, arrows) | Yes. 3 to 11 colors (the asset pack has semi-alpha shadows) | 16x16 | Same artist's plum `(82,51,63)`, deep plum `(41,29,43)` | Fantasy | **Fits PL**: animated pickups and HUD counters (coin, key) matching #1 |
| 4 | **Tiny_Tales_Code_Ark_UI_Assets_1.0** (C), Megatiles | Window skins: 2 frame types x 5 colors x S/M/L, 9-slice parts, 2 textures and a solid fill, RPG Maker windowskins; 3 gauge types (24x48); 31 system icons x 10 colorways (320 files); 2 cursors x 10 colors (24 px); about 2,000 keyboard and gamepad prompts (Xbox, PS, Switch; Dark, Light, Neon keyboards, 16x16 and 20x16); aseprite sources. No font | Yes. 1x, 0 % semi, 4 to 19 colors | Tiles 16 to 32 px; frame a 1 px line on 8 or 16 px corners; icons 16 px | Dark navy fill `(19,17,29)`, 1 px neon or pastel lines with a chromatic fringe | Sci-fi, tech | **Fits PC after a recolor** (neon to steel and bone; aseprite sources included); the Dark and Light key and pad prompts fit either |
| 5 | **Admurins** Potions, General Items, Insect Items, Gem Items A, Armory, Skill Icons, Skill Icons B (F) | Potions 581; General 326 (ores, arrows, tools, food); Insects 100; Gems 100; Armory 1,725 (armour sets and weapons in 20+ metals); Skills 80 + 234 | Yes. 0 % semi, 5 to 18 colors per icon | **32x32 cell**; art fills armory 21x20, potions 15x25, gems 12x13, items and skills 26 to 27 px | Near-black navy outline `(12,6,17)`, clean cel shading, saturated | Fantasy RPG | **Fits PC**: dark outline and contrast match; a huge range. Too crisp and dark beside PL's plum lines; 2-tile icons in a 32 px slot |
| 6 | **RPG WEAPONS - 24PX** (F) | 2 sheets of 10x10: about 200 weapons (swords, axes, staves, wands, daggers) | Yes, indexed, 0 % semi | 24x24 | Darkened-hue outlines, muted steel and wood | Fantasy | **Fits PC (passable in PL)**: muted and well drawn; needs a 24 px slot |
| 7 | **SC Pixel Portraits 1** (C) | 160 busts (64x64; x1, x2, x3 copies plus `Papier` and `xBR` filtered versions, which are not pixel art), 40 x2 facesets (48 px faces), base sheets | `Pixel Art/x1` is true pixel art: 13 to 19 colors, 0 % semi, transparent background (the `RPG Maker 2003` copies have an opaque grey background) | 64x64 bust, 48x48 face | Colored dark outlines; many fantasy skin tones (blue, green, grey), bare-shoulder bases | Fantasy people | **Dialog portraits for either (leans PL)**: real pixel art at a dialog scale; needs a frame; pick carefully |
| 8 | **RPG Inventory Icons v.1 / v.2** (F) | 100 + 100 icons (weapons, armour, rings, bottles, bags, gems, robes, fish) plus PSD | Yes. 10 to 17 colors (v2 up to 185), about 0 % semi | **48x48** (art 42 to 46 px) | Black or very dark outline; v2 saturated and glossy-looking | Fantasy | **Menus only, or a PC inventory screen**: 3 tiles is too big for a 16 px HUD |
| 9 | gdm-solitaire `BONUS pixelated poker cards` (H) | 4 suits x 13, an alt set, covers (112 PNG) plus AI and EPS | **No**: vector "pixel style", blocks about 5.5 px, non-integer, AA edges | 131x183 (about 24x33 logical) | Flat black and red on white | Cards | **Does not fit** unless hand-cleaned down to about 24x33 for a card minigame |
| 10 | gdm-medieval-wooden-gui-pack (H) | Wooden panels, plank bars, parchment, square and round buttons, stars, shop and inventory mockups; PSD | No. 1,000 to 2,000+ colors, about 24 % semi-alpha | 49 to 800 px | Glossy cartoon wood, black outlines | Medieval mobile | **Menus only (barely)**: warm wood could frame a title or pause menu at native resolution |
| 11 | gdm-fairytale-wooden-game-ui-pack (H) | Gold-rimmed wooden buttons, level-complete panel, vines, crowns, volume bars | No. 500 to 8,000 colors, 30 to 38 % semi | 50 to 540 px | Bright glossy cartoon | Fairytale mobile | **Menus only / does not fit** |
| 12 | gdm-stone-cartoon-gui-pack (H) | Stone panels, lime gem buttons, rating, shop, and level screens | No. 1,100 to 3,100 colors, 15 to 30 % semi | 60 to 240 px | Saturated cartoon | Casual | **Does not fit** |
| 13 | gdm-gui-icons-pack-1 (H) | 700 icons x 80, 150, 260 px (potions, keys, scrolls, gear) on dark rounded tiles | No: painted | 80 to 260 px | Painterly, dark tiles | Fantasy RPG | **Menus only** |
| 14 | RPG Avatar Icon Set v.1 (F) | 15 painted busts (dwarves, elves, humans, orcs, undead) plus PSD | No. About 30k colors | 512x512 | Realistic painted | Fantasy | **Menus only** (character select at most) |
| 15 | AD Visual Inventory Containers Vol 2/3, Paper Vol 3/4 (C) | Bags (216), jars (160), books (225), letters and papers (255) in many colorways and grunge versions | No. 10k to 17k colors, AA | 256x256 | Painted, hand-inked | Fantasy and horror props | **Menus only**: a full-screen item inspect or journal |
| 16 | Northfolk_Icons (C) | 104 rendered item icons (barrels, logs, braziers, clothes) | No. Rendered, 7k to 12k colors | 512x512 | Realistic | Viking, rustic | **Does not fit** |
| 17 | SC Crystal Portraiture (C) | 576 pictures x 6 sizes, facesets 48 to 360 px, emotion variants | No: painted anime (the 48 px faces are downsampled paintings) | 48 to 640 px | Soft painted | Anime fantasy | **Menus only / does not fit** |
| 18 | SC Visage 2023 (C) | 99 painted portraits plus ornate frames and backs | No. About 100k colors | 256 to 576 px | Dark painterly | Fantasy | **Menus only** |
| 19 | gdm-5-game-ui-kits, gdm-2-players-multigames, gdm-sweet-pink, gdm-transparent-clear, gdm-space-game-gui, gdm-zombies-attack, gdm-merge-defense, gdm-solitaire (main), gdm-animals-bubble-shooter, gdm-70-progress-bars, gdm-cute-rpg-game-builder (H) | Mobile and casual kits: candy, glass, neon, flat vector, zombie and space HUDs, progress bars, glossy buttons | No. Vector exports, AA (the space and clear kits are 70 to 99 % semi-alpha glow) | 30 to 1,900 px | Flat bright or glossy | Casual mobile, sci-fi | **Does not fit** |

No UI content (checked): Fantasy Dreamland Characters Pocket Pack (character
and battler sheets only, no faces); the Japanese Arcade and Japan
Collection packs (tiles, characters, RPG Maker sheets); Fantasy RPG interior
pack (furniture and townsfolk). Little Monsters and Robots 7-9 have monster
faces, but they are battlers. The EVFX demos contain RPG Maker MZ's default
`IconSet.png` and `ButtonSet.png`, licensed for RPG Maker only: skip them.

## Complete RPG creator bundle

Paths are under `complete rpg creator bundle/`. Only two packs here are true
low-res pixel art, and both are icon sets; there are no pixel-art panels,
9-slices, bars, buttons, cursors, or fonts in the bundle.

| # | Pack (path) | Contents | True pixel? | Native size | Outline and palette | Theme | Verdict |
|---|---|---|---|---|---|---|---|
| 1 | **Beowulf's RPG monster loots**: `beowulfs rpg monster loots/Beowulf_RPG_Monsters_Loot/` | 90 loot icons (wings, claws, meat, eyes, hearts, eggs, honey, pills, ...) as 32, 64, 128 px PNGs plus spritesheets | **Yes**. Median 8 colors, no AA; the 64 and 128 px copies are exact 2x and 4x | **32x32** (twice the tile) | 1 px flat near-black `#131313` outline on 96 % of edge pixels; saturated, clean cel shading | Fantasy monster loot | **Fits PC** (outline and contrast match `#151A16`). For PL, recolor the single outline color to maroon (`#561328` or `#2C0F15`) and desaturate about 20 %: cheap and lossless |
| 2 | **Magic runes pixel art asset pack**: `magic runes pixel art asset pack/Beowulf's_Magic_Runes/` | 70 rune stones and tablets in elemental color sets, 32, 64, 128 px plus spritesheets | **Yes**. 7 to 10 colors, no AA, exact 2x and 4x copies | **32x32** canvas (sprites about 20 to 30 px) | Same `#131313` outline, saturated | Fantasy magic | **Fits PC** (skill, spell, rune icons). PL only after the same recolor |
| 3 | `dark age mobile ui/DarkAge UI/` | 165 PNG + 14 PSD: windows and headers, boxes, buttons (with 57 icons), progress and vertical bars, sliders, toggles, tabs, unit frames, nameplates, spell slots, inventory, store, quests, loading bar, joystick | No. 250 to 1,200 colors, 10 to 78 % AA edges | Icons 68 px, slots 140 px, headers 349x68 (960x660 mockups) | Soft bevelled slate, parchment, wood, warm brown and red ribbons; muted, semi-flat | Medieval fantasy | **Menus only**: the high-res kit closest to PL's warm browns, for pause, inventory, and settings screens at screen resolution |
| 4 | `rpg and mmo ui 4/RPG and MMO UI 4/` (EvilSystem) | 323 PNG + 5 PSD: action, XP, and cast bars, unit and party frames, minimap, spellbook, character window and slots, inventory, chat, dialog, tooltips, quest tracker, toggles, 1 cursor, 30 icons at 128 px | No. Vector, AA | Slots 92 to 104 px | Dark charcoal, orange and red accents, thin bevels | Dark fantasy MMO | **Menus only**: suits PC's dungeon, forge, and cemetery maps |
| 5 | `fantasy ui bloodline/` | 199 sliced PNG + 4 PSD: HUD (action bar, castbar, unit frame, minimap, spells, talents, tooltip, inventory), login, character select | No. AA edges | Parts 13 to 40 px, windows 600 px+ | Dark painterly leather and parchment, red highlights | Dark fantasy | **Menus only** (PC tone) |
| 6 | `mmorpg ui kit_windows/` + `mmrpg ui skills tree/` | 10 PNG windows (chat, hint, inventory, minimap, popup, quests, spells HUD, system menu, user plate) + PSDs; a skill-tree PSD | No. 5k to 34k colors | Windows 200 to 520 px | Dark wood and iron frames round parchment, gold serif titles | Classic fantasy MMO | **Menus only**: the parchment could suit PL quest or dialog screens |
| 7 | `dialogue boxes_windows/` | 301 PNG + PSD: 25 dialog-box styles (Fantasy x5, Cute x5, Simple x6, Grunge, Comic x2, Sci-fi x3, bubbles x2) in 3 colors each; 6 Google display fonts | No. Vector, 4K | Buttons 35 to 60 px, panels 1,000 px+ | Flat vector; Fantasy 01 tan parchment, 04/05 dark brown and gold | Mixed | **Menus only**: Fantasy 01/04 and Simple 01 are plain rectangles, easy to redraw as a pixel 9-slice |
| 8 | `fantasy spellbook/files/` | 162 PNG: book covers (5 elements), Celtic corners, clasps, bookmarks, pages, paging buttons, slots, mana, school emblems, tooltips | No. 5k to 15k colors | Corners 260 px, slots 165 px, pages about 1,700 px | Painted bronze and leather | Fantasy | **Menus only** (a spellbook screen) |
| 9 | `medieval rpg ui kit_windows/` | PSDs only (1280x720 mockup, buttons, shields, stripes, linen) + font zips + help PDF | No; must be sliced from PSD | 1280x720 | Cartoony parchment, blue banners | Medieval strategy | **Menus only, weak** |
| 10 | `rpg and mmo ui 5/RPG and MMO UI 5/` (EvilSystem) | 200 PNG + 3 PSD: action and cast bars, unit frames, minimap, spellbook, character, inventory, chat, dialog, lobby, quest log, XP bar, 46 icons at 128 px | No. Grunge brush textures, AA | Vector at 200 % | Black grunge strokes, red accents | Grim dark MMO | **Menus only, weak** (the grunge clashes with both families) |
| 11 | `fantasy nordic gui/` | 1 PSD, 22 4K banner mockups, Vollkorn font | No; mockups only | 4K | Very dark stone and metal, thin gold | Nordic dark fantasy | **Does not fit** |
| 12 | `game fantasy gui kit/` | 12 PSD + 12 4K previews (slots, health meter, modals, prompts, tab bar, loading) | No | 4K | Dark with glowing neon rims | Fantasy neon | **Does not fit** |
| 13 | `gui pro_fantasy rpg_gamedevmarket/GUI Pro-FantasyRPG_2.0/` (Layer Lab) | 4,488 PNG + 104 PSD: buttons, chests, frames, labels, popups, sliders, 48 equipment and 90 item icons, 361 white picto glyphs, 46 flags | No | 32 to 516 px | Glossy, saturated casual mobile | Casual mobile fantasy | **Does not fit** (the white glyphs serve only as menu symbols) |
| 14 | `cute rpg game builder/PNGs/` | 2,106 PNG + PSD: UI (639: HUD, inventory, map, quest, store, pause, victory), 1,093 buttons, 120 icons, chibi characters, backgrounds | No | Icons 100 and 500 px, buttons 190 to 500 px | Glossy candy colors, thick dark outlines | Cute casual | **Does not fit** |
| 15 | `gui pro survival clean/GUI Pro-SurvivalClean/` (Layer Lab) | 3,293 PNG: buttons, frames, labels, popups, sliders, 2,318 icons | No | 64 to 512 px | Clean modern blue and teal | Modern post-apocalypse | **Does not fit** |
| 16 | `2d minimal stat icons/` | 80 stat icons x 3 sizes (128, 256, 512) | No. 600 to 1,800 colors, AA | 128 px minimum | Flat cartoon, thick black outline, bright | Casual | **Does not fit** |
| 17 | `2d minimal skill icons/` | 30 skill icons, square and round, x 3 sizes | No. 3k to 6k colors | 128 px minimum | Glossy bright painted | Casual | **Does not fit** |
| 18 | `spells and ability icons_windows/` | 72 spell icons x 5 sizes (60 to 512) + PSD | No. About 3k colors even at 60 px | 60 px minimum | Painted, saturated glow | Fantasy spells | **Does not fit** |
| 19 | `mobs avatar icons_windows/` | 143 monster portraits (orc, skeleton, wolf, golem, demon, ...) | No. 3k to 12k colors | 256 px | Painted, stylised | Fantasy | **Menus only** (dialog or bestiary portraits at screen resolution) |
| 20 | `character avatar icons_windows/` | 81 portraits | No. 16k to 32k colors | 512 px | Semi-realistic painted | Fantasy | **Menus only** (realistic faces clash with the chibi walkers) |
| 21 | `fantasy character avatars/` | 24 portraits (12 races and genders, round and square) + PSDs | No | 512 px | Realistic painted | Fantasy | **Menus only / does not fit** |
| 22 | `monsters avatar icons_windows/` | 107 monster portraits with painted backgrounds | No | 512 px | Painted, with background | Fantasy | **Does not fit** (backgrounds baked in) |
| 23 | `all in one pack rpg maker/…/*FACESET*` (Neonpixel) | About 400 RPG Maker MV facesets | Pixel art, but native 144x144 (11 to 43 % AA alpha) | 144 px | Anime pixel art, saturated | Mixed | **Does not fit** (3x the pixel density of 16 px tiles) |
| 24 | `cyberpunk hud elements/` | 25 PNG + AI/EPS: panels, cursors, scrolls | No. 55 to 85 % AA | 300 to 1,400 px | Neon cyan and orange glow | Sci-fi | **Does not fit** |
| 25 | `sci-fi characters icons/` | 60 portraits, with and without background | No | 256 px | Painted sci-fi | Sci-fi | **Does not fit** |
| 26 | `scifi skill icon pack_windows/` | 142 icons in 4 color sets | No | 256 px | Glowing neon on black | Sci-fi | **Does not fit** |

Not UI (checked and skipped): `pixel art mining crafting` (paper-doll parts
and tools), `pixel art rogue-like rpg` (a tilesheet), `beowulfs rpg dungeon
tilesets` (in-world props), and the Mana Seed collection (not to be used).
