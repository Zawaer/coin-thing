shader_type spatial;

uniform float grid_size = 1.0;
uniform vec3 line_color = vec3(1.0, 1.0, 1.0);
uniform vec3 floor_color = vec3(0.2, 0.2, 0.2);

void fragment() {
    vec2 uv = UV / grid_size;
    vec2 grid = abs(fract(uv - 0.5) - 0.5) / fwidth(uv);
    float line = min(grid.x, grid.y);
    ALBEDO = mix(floor_color, line_color, 1.0 - min(line, 1.0));
}
