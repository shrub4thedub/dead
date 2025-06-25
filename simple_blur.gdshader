shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 5.0) = 1.0;

void fragment() {
    vec4 color = vec4(0.0);
    
    // Simple box blur
    int blur_size = int(blur_amount);
    float count = 0.0;
    
    for (int x = -blur_size; x <= blur_size; x++) {
        for (int y = -blur_size; y <= blur_size; y++) {
            vec2 offset = vec2(float(x), float(y)) * TEXTURE_PIXEL_SIZE;
            color += texture(TEXTURE, UV + offset);
            count += 1.0;
        }
    }
    
    COLOR = color / count;
}