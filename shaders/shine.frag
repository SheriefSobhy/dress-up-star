// Moving sparkle highlights for shiny things (jewelry, crowns, sunglasses,
// glitter nails). Drawn over a part of the doll; [uMask] is a picture of
// only the shiny pixels, so the sparkles never leave the jewelry.
//
// Coordinates are doll space (the 200 x 400 drawing space), so the sparkles
// are the same size on every phone.
#version 460 core

#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec4 uRect;   // left, top, width, height of the mask (doll space)
uniform float uTime;  // seconds
uniform sampler2D uMask;

out vec4 fragColor;

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

void main() {
  vec2 pos = FlutterFragCoord().xy;
  float mask = texture(uMask, (pos - uRect.xy) / uRect.zw).a;
  if (mask < 0.02) {
    fragColor = vec4(0.0);
    return;
  }

  // A soft band of light sweeping across, every couple of seconds.
  float band = mod(pos.x * 0.7 + pos.y - uTime * 70.0, 160.0) - 80.0;
  float glint = exp(-band * band / 30.0) * 0.6;

  // Little four-pointed stars that twinkle on and off.
  vec2 grid = pos / 10.0;
  vec2 cell = floor(grid);
  float h = hash(cell);
  // Kept near the middle so the star arms fit in their cell.
  vec2 center = vec2(hash(cell + 3.1), hash(cell + 7.7)) * 0.2 + 0.4;
  vec2 d = abs(fract(grid) - center);
  float twinkle = sin(6.2831 * fract(uTime * (0.35 + h * 0.5) + h * 9.0));
  twinkle = max(twinkle, 0.0);
  twinkle *= twinkle * step(0.5, h);
  float arms = (1.0 - smoothstep(0.0, 0.05, min(d.x, d.y))) *
      (1.0 - smoothstep(0.05, 0.4, max(d.x, d.y)));
  float core = 1.0 - smoothstep(0.0, 0.12, length(d));
  float glow = exp(-dot(d, d) * 60.0) * 0.45;
  float star = (max(arms, core) + glow) * twinkle;

  float light = clamp((glint + star) * mask, 0.0, 0.95);
  fragColor = vec4(vec3(1.0, 0.97, 0.86) * light, light);
}
