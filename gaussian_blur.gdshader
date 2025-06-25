shader_type canvas_item;

uniform float blur_strength : hint_range(0.0, 10.0) = 1.0;
uniform float alpha_multiplier : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec4 color = vec4(0.0);
    float total_weight = 0.0;
    
    // Use fixed small sample count for performance
    int samples = int(clamp(blur_strength, 1.0, 5.0));
    
    // Apply gaussian blur with smaller kernel
    for (int x = -samples; x <= samples; x++) {
        for (int y = -samples; y <= samples; y++) {
            vec2 offset = vec2(float(x), float(y)) * TEXTURE_PIXEL_SIZE * blur_strength;
            vec2 sample_uv = UV + offset;
            
            // Simple gaussian weight calculation
            float distance_sq = float(x * x + y * y);
            float weight = exp(-distance_sq / (blur_strength * blur_strength * 0.5));
            
            // Clamp UV coordinates to avoid sampling outside texture
            sample_uv = clamp(sample_uv, vec2(0.0), vec2(1.0));
            
            color += texture(TEXTURE, sample_uv) * weight;
            total_weight += weight;
        }
    }
    
    // Normalize by total weight
    if (total_weight > 0.0) {
        color /= total_weight;
    }
    
    COLOR = vec4(color.rgb, color.a * alpha_multiplier);
}