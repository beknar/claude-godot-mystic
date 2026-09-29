shader_type canvas_item;
// Mana Seed grass splat on the Ground layer: over pure light grass, each
// pixel takes one of four grass textures (lush, dry, flowers, moss) where
// that layer's weight field is strongest, or keeps the base grass. The
// fields are per map corner, sampled smoothly; an ordered dither and a small
// wobble break the rims, so textures meet in crisp pixel-art dithers, never
// blended colors. `fade` is 0 at any other terrain, so transition tiles and
// baked-grass art stay exactly as drawn.

uniform sampler2D weights : filter_linear, repeat_disable; // RGBA = lush, dry, flowers, moss
uniform sampler2D fade : filter_linear, repeat_disable; // R
uniform sampler2D layers : filter_nearest, repeat_disable; // 4 variants x 4 layers of 16 px
uniform vec2 corners = vec2(65.0, 41.0); // map corners (W + 1, H + 1)
uniform float seed = 0.0;
uniform float dither = 0.3; // width of the dithered rim (narrower where the layers contrast hard)

varying vec2 world;

void vertex() {
	// The layer draws in quadrants whose VERTEX is local to each quadrant;
	// the model matrix carries the quadrant's offset (the layer sits at 0, 0).
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453);
}

float bayer(ivec2 p) {
	int x = p.x & 3;
	int y = p.y & 3;
	int m[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return float(m[y * 4 + x]) / 16.0;
}

void fragment() {
	vec4 base = COLOR; // the tile texel, already times the modulate
	vec2 uvc = (world / 16.0 + 0.5) / corners;
	float f = texture(fade, uvc).r;
	COLOR = base;
	vec2 px = floor(world);
	float d = (bayer(ivec2(px)) - 0.5) * dither
		+ (hash(floor(px / 3.0)) - 0.5) * dither * 0.4
		+ sin(px.x * 0.31 + px.y * 0.17) * 0.04;
	// The fade is an edge, not a dimmer: a pixel is eligible past its
	// (dithered) half-way line, so the splat stops in a narrow band.
	if (f + d * 0.5 > 0.5) {
		vec4 w = texture(weights, uvc);
		float best = 0.5;
		int pick = -1;
		for (int i = 0; i < 4; i++) {
			float s = w[i] + d;
			if (s > best) {
				best = s;
				pick = i;
			}
		}
		if (pick >= 0) {
			vec2 cell = floor(world / 16.0);
			float variant = floor(hash(cell + float(pick) * 17.0) * 4.0);
			vec2 in_tile = mod(px, 16.0);
			vec2 luv = (vec2(variant * 16.0, float(pick) * 16.0) + in_tile + 0.5) / 64.0;
			COLOR = texture(layers, luv) * vec4(1.0, 1.0, 1.0, base.a);
		}
	}
}
