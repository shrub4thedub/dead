shader_type canvas_item;

uniform float time : hint_range(0.0, 10.0) = 0.0;
uniform vec2 ripple_center = vec2(0.5, 0.5);
uniform float ripple_radius : hint_range(0.0, 2.0) = 0.5;
uniform float ripple_intensity : hint_range(0.0, 1.0) = 0.1;
uniform float ripple_frequency : hint_range(1.0, 50.0) = 10.0;

void fragment() {
    vec2 uv = UV;
    vec2 center = ripple_center;
    
    float distance = length(uv - center);
    float ripple = sin((distance - time) * ripple_frequency) * ripple_intensity;
    
    // Apply ripple effect within radius
    if (distance < ripple_radius && distance > ripple_radius - 0.1) {
        vec2 offset = normalize(uv - center) * ripple;
        uv += offset;
    }
    
    COLOR = texture(TEXTURE, uv);
}