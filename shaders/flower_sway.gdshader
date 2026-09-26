shader_type canvas_item;
// Wind sway for flower deco tiles. Each flower leans by whole pixels on a
// slow wave: its top row moves the most, its stem bends, and its bottom
// rows stay planted. Heights come from `art_rows`, one texel per atlas
// cell (R = first drawn row, G = last drawn row), so short flowers drawn
// low in their cell lean as much as tall ones. The wave's phase runs across
// the map, so gusts ripple through the meadow. Only the pack's own pixels
// are shown; a shifted pixel from outside the cell is left transparent, so
// neighbouring atlas cells never bleed in.

uniform sampler2D art_rows : filter_nearest;
uniform float speed = 1.7;
uniform float ripple = 0.23; // phase change per cell along the wind
uniform float amplitude = 1.35; // in pixels at the flower's top, before rounding
uniform float planted_rows = 3.0; // bottom rows of each flower that never move

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 cell = floor(world_pos / 16.0);
	vec2 local = world_pos - cell * 16.0; // 0..16 inside the cell
	// The tile atlas may pad every cell with a 1px border in the texture it
	// draws from (TileSetAtlasSource.use_texture_padding), so cells sit 18px
	// apart there instead of 16. Work out the stride from the sizes.
	ivec2 cells = textureSize(art_rows, 0);
	float stride = (textureSize(TEXTURE, 0).x == cells.x * 16) ? 16.0 : 18.0;
	vec2 px = UV / TEXTURE_PIXEL_SIZE;
	ivec2 atlas_cell = ivec2(floor(px / stride));
	vec4 rows = texelFetch(art_rows, atlas_cell, 0) * 255.0;
	float top = rows.r;
	float base = rows.g + 1.0 - planted_rows; // rows at or below this stay put
	// Height above the planted base, 0 at the base and 1 at the flower's top.
	float h = clamp((base - local.y) / max(base - top, 1.0), 0.0, 1.0);
	float phase = TIME * speed + cell.x * ripple + cell.y * ripple * 0.45;
	float gust = 0.65 + 0.35 * sin(TIME * 0.37 + cell.x * 0.05);
	float shift = round(sin(phase) * gust * amplitude * h);
	float src_x = local.x - shift;
	if (src_x < 0.0 || src_x >= 16.0) {
		COLOR = vec4(0.0);
	} else {
		COLOR = texture(TEXTURE, UV - vec2(shift * TEXTURE_PIXEL_SIZE.x, 0.0));
	}
}
