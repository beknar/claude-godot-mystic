shader_type canvas_item;
// Wind sway for flower deco tiles. Each 16px cell leans left or right by
// whole pixels on a slow wave: the top rows (the flower heads) move one
// pixel, the stems bend, and the bottom rows stay planted. The wave's phase
// runs across the map, so gusts ripple through the meadow. Only the pack's
// own pixels are shown; a shifted pixel that would come from outside the
// cell is left transparent, so neighbouring atlas cells never bleed in.

uniform float speed = 1.7;
uniform float ripple = 0.23; // phase change per cell along the wind
uniform float amplitude = 1.35; // in pixels, before rounding
uniform float planted_rows = 5.0; // bottom rows that never move

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 cell = floor(world_pos / 16.0);
	vec2 local = world_pos - cell * 16.0; // 0..16 inside the cell
	// Height above the planted base, 0 at the base and 1 at the top row.
	float h = clamp((16.0 - planted_rows - local.y) / (16.0 - planted_rows), 0.0, 1.0);
	float phase = TIME * speed + cell.x * ripple + cell.y * ripple * 0.45;
	float gust = 0.65 + 0.35 * sin(TIME * 0.37 + cell.x * 0.05);
	float sway = sin(phase) * gust;
	float shift = round(sway * amplitude * h);
	float src_x = local.x - shift;
	if (src_x < 0.0 || src_x >= 16.0) {
		COLOR = vec4(0.0);
	} else {
		COLOR = texture(TEXTURE, UV - vec2(shift * TEXTURE_PIXEL_SIZE.x, 0.0));
	}
}
