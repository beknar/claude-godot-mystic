# Interiors (Cozy Cottage)

Read this before touching `scripts/interior_*.gd` or `house_interiors.gd`.

**Never break (the looks):**
- Wallpaper group and trim match the wall-top frame of the same group.
- Tall wall furniture never stands in front of a hanging; something sits
  on every table and cabinet top.
- Every door, the way out, and some floor of every room stay reachable;
  every home has a fire.

**Coordinates:** `interior_art.gd` (`ART`, `COUNTERS`, `RUGS`) is
authoritative.

**Front doors** (`scripts/door_leaf.gd`, driven by `house_interiors.gd`):
a door given a `leaf` (DoorLeaf, a child of the building's sprite, so it
sorts and fades with the building) swings open while the walker is on or
just before its doorstep and shuts once it has walked off; the walker
steps out of a house through its open door (`snap_open`). The leaf turns
inward in three steps of 55 ms: it narrows toward its hinge, darkens as it
turns from the light, shows its edge, and the dark of the room opens up
behind it. A `pack` leaf is the building's own drawn door (the Farm
farmhouses, manor, and windmill, in the season's sheet); a `made` leaf is
planks in the colors of an open doorway's frame (the Painted Lands Forest
houses, `DoorLeaf.make_leaf`). Doorways that stand open (the Farm barn and
greenhouse) have none.

Pack: The Painted Lands – Interior Cozy Cottage Tileset (antarcticbees),
`assets/pack/cozy_cottage/` (git-ignored). Sheets: `wallpapers_and_floors.png`,
`furniture.png` (five wood tones, 288 px apart), `decoration.png`. Catalog
`scripts/interior_art.gd`; generator `scripts/interior_plan.gd`; painter
`scripts/interior_view.gd`; life `scripts/interior_life.gd`; the Painted Lands
doors `scripts/house_interiors.gd`. Used by the Green Caves homes and the
Painted Lands randomizer's houses; never on the outdoor maps themselves.

Sheet systems:

- Wallpaper groups at rows 0, 5, 10, 15: a lip (wall top edged toward the
  room) over three face rows; one trim color each (cream, brown, mid, dark),
  matching the wall-top frames at `(0, 20)`, `(5, 20)`, `(10, 20)`, `(15, 20)`
  (3×3, trim on the side toward the room; nubs for a room only diagonal in
  the next two columns, rows 0–1 of the frame) and their black-filled copies
  nine rows lower (used everywhere: the void round an interior is black).
- Doorways: two-wide openings with a transparent hole; group starts
  `DOORWAY` = 29, 34, 34, 38.
- Floors: planks in 2×4 blocks from `(28–44, 20–23)`, parquet 2×2 from rows
  25–28, tiles `(20–27, 21–23)` (kitchens, baths, pantries).
- Furniture and decoration: `InteriorArt.ART` (rect, footprint cells, place:
  wall, floor, face, top). Fireplaces are their own art in any wood tone.
  Kitchen counters are modules along the north wall (`COUNTERS`, wood or
  marble tops, one sink). Left out: fridges, washers, stoves, screens.

Layout (`InteriorPlan.generate(seed, rooms, opts)`): a rectangle split into
one to six rooms by one-cell walls (each room at least 4 wide and 6 tall: three
face rows and three floor rows); each split gets a door (a gap two cells tall
in a vertical wall, or a two-wide doorway through a horizontal wall and the
face under it, drawn with the group's door frame); the way out is a gap in the
south wall of a south room (three wide, the arch's, in caves). Room sets by
count (the first is the entry room): 1 cottage; 2 living/bedroom,
cottage/bedroom, living/kitchen; 3 living, kitchen, bedroom (or hall …, or
study); 4–6 add study, bath, dining, pantry, a second bedroom. Bath and pantry
take the smallest rooms.

Furnishing: a window first (not in hearth rooms, baths, or pantries), then the
room's set (cottage: hearth, bed, wardrobe, counters, table and chairs;
living: hearth, rug, sofa, low table, armchair, bookshelf, floor lamp; hall;
kitchen: counters with a sink, dish shelf, table and chairs; bedroom: bed,
nightstand, wardrobe, dresser or vanity; study: bookshelves, desk and chair;
bath: tub, vanity; dining: long table and chairs; pantry: shelves, baskets),
floor plants and baskets in corners, hangings on the face (windows,
paintings, vines, herbs, shelves, mirrors) where nothing tall stands, and
something on every table and cabinet top. Tall wall furniture never stands in
front of a hanging. A piece is placed only if every door, the way out, and
some floor of every room stay reachable from the way out; door cells, their
approach, and the doorway rows are kept clear. Every home has a fire: without
a living room, a cooking hearth takes a wall (displacing a hanging).
`tools/check_interiors.gd` checks 600 homes; `tools/interior_preview.tscn`
shows six side by side.

Life (`interior_life.gd`): flickering flames in every fireplace opening
(y-sorted just in front of it), dappled sunbeams from each window (Painted
Lands; slanted, dithered, dimming as clouds pass, leaf shadows moving across
them, dust motes turning in them), steam from cups and teapots, a moth round
half the lamps, and a house cat in 70 % of homes (four coats: sleeps by the
hearth or in a sunbeam, stretches, wanders, sits and flicks its tail, comes to
sit by the walker or trots off). Hearth and lamp light come from
`fire_ambience.gd` (radius 30 and 14, no smoke). `tools/sim_interior.gd`
measures it headless: about 0.59 % of a home's pixels change per frame
(quietest 0.33 %), comparable with the outdoor camera windows.

Painted Lands doors (`house_interiors.gd`, `forest.gd` `interiors = true` in
the randomizer only): walking up into a door from its doorstep fades to black
and opens the house's interior, a sub-map 20000 px below the map (rooms by
building: porch cottage 3–6, flower cottage 2–4, gable cottage 2–5, hut 1–2,
shed 1, barn 1–3, from the map id and house index; built once per map). The
outdoor map is hidden and paused, the walker is moved inside above the way
out, and the camera is limited to the home (centered when smaller than the
screen). Walking down through the way out returns to the doorstep facing out.
Regenerating from the menu while indoors drops the interior first.
