extends Node2D
class_name EnvironmentEffects

# Ripple effect system
var ripple_shader: Shader
var ripple_material: ShaderMaterial
var active_ripples = []

# Tile shake system
var shaking_tiles = {}
var original_tile_positions = {}

func _ready():
	setup_ripple_system()
	setup_tile_shake_system()

func setup_ripple_system():
	# Create ripple shader material
	ripple_shader = preload("res://shaders/ripple.gdshader") if ResourceLoader.exists("res://shaders/ripple.gdshader") else null
	if ripple_shader:
		ripple_material = ShaderMaterial.new()
		ripple_material.shader = ripple_shader

func setup_tile_shake_system():
	# Find tilemap in scene
	var tilemap = get_tree().get_first_node_in_group("tilemap")
	if not tilemap:
		# Try to find tilemap by name
		tilemap = get_tree().get_nodes_in_group("tilemap")[0] if get_tree().get_nodes_in_group("tilemap").size() > 0 else null
	
	if tilemap:
		original_tile_positions[tilemap] = tilemap.position

func _process(delta):
	update_ripples(delta)
	update_tile_shakes(delta)

func update_ripples(delta):
	for i in range(active_ripples.size() - 1, -1, -1):
		var ripple = active_ripples[i]
		ripple.time += delta
		ripple.radius += ripple.speed * delta
		ripple.intensity *= 0.95  # Fade out
		
		if ripple.intensity < 0.01 or ripple.time > ripple.lifetime:
			active_ripples.remove_at(i)

func update_tile_shakes(delta):
	for tilemap in shaking_tiles.keys():
		var shake_data = shaking_tiles[tilemap]
		shake_data.timer -= delta
		
		if shake_data.timer > 0:
			var shake_offset = Vector2(
				randf_range(-shake_data.intensity, shake_data.intensity),
				randf_range(-shake_data.intensity, shake_data.intensity)
			)
			tilemap.position = original_tile_positions[tilemap] + shake_offset
		else:
			tilemap.position = original_tile_positions[tilemap]
			shaking_tiles.erase(tilemap)

func create_ripple(position: Vector2, intensity: float = 1.0, color: Color = Color.WHITE):
	var ripple = {
		"position": position,
		"radius": 0.0,
		"intensity": intensity,
		"color": color,
		"speed": 200.0 * intensity,
		"lifetime": 1.0,
		"time": 0.0
	}
	active_ripples.append(ripple)
	
	# Create visual ripple effect
	create_visual_ripple(position, intensity, color)

func create_visual_ripple(position: Vector2, intensity: float, color: Color):
	# Create a temporary sprite for the ripple
	var ripple_sprite = Sprite2D.new()
	add_child(ripple_sprite)
	
	# Create a simple circle texture
	var texture = ImageTexture.new()
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Draw circle
	for x in range(64):
		for y in range(64):
			var dist = Vector2(x - 32, y - 32).length()
			if dist <= 30 and dist >= 25:
				var alpha = 1.0 - abs(dist - 27.5) / 2.5
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	texture.set_image(image)
	ripple_sprite.texture = texture
	ripple_sprite.global_position = position
	ripple_sprite.modulate = color
	ripple_sprite.scale = Vector2.ZERO
	
	# Animate ripple
	var tween = create_tween()
	tween.parallel().tween_property(ripple_sprite, "scale", Vector2(3.0 * intensity, 3.0 * intensity), 1.0)
	tween.parallel().tween_property(ripple_sprite, "modulate:a", 0.0, 1.0)
	tween.tween_callback(ripple_sprite.queue_free)

func shake_tiles(position: Vector2, radius: float, intensity: float, duration: float):
	var tilemap = get_tree().get_first_node_in_group("tilemap")
	if not tilemap:
		return
	
	# Check if tiles are within radius
	var tile_distance = position.distance_to(tilemap.global_position)
	if tile_distance <= radius:
		var shake_intensity = intensity * (1.0 - tile_distance / radius)
		
		if not tilemap in shaking_tiles:
			shaking_tiles[tilemap] = {
				"intensity": shake_intensity,
				"timer": duration
			}
		else:
			# Extend existing shake
			shaking_tiles[tilemap].intensity = max(shaking_tiles[tilemap].intensity, shake_intensity)
			shaking_tiles[tilemap].timer = max(shaking_tiles[tilemap].timer, duration)

func create_impact_wave(position: Vector2, direction: Vector2, intensity: float):
	# Create multiple ripples in a wave pattern
	for i in range(3):
		var offset_pos = position + direction * i * 30
		create_ripple(offset_pos, intensity * (1.0 - i * 0.3), Color.WHITE)
		
		# Add delay between ripples
		await get_tree().create_timer(0.1).timeout

func debris_burst(position: Vector2, direction: Vector2, intensity: float):
	# Create particle debris effect
	var debris_count = int(10 * intensity)
	
	for i in debris_count:
		var debris = create_debris_particle()
		add_child(debris)
		debris.global_position = position
		
		# Random velocity in cone around direction
		var angle_spread = PI / 3  # 60 degrees
		var random_angle = direction.angle() + randf_range(-angle_spread/2, angle_spread/2)
		var velocity = Vector2.from_angle(random_angle) * randf_range(100, 300) * intensity
		
		animate_debris(debris, velocity)

func create_debris_particle() -> Sprite2D:
	var debris = Sprite2D.new()
	
	# Create small square texture
	var texture = ImageTexture.new()
	var image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.6, 0.4, 0.2, 1.0))  # Brown debris
	texture.set_image(image)
	
	debris.texture = texture
	debris.rotation = randf() * TAU
	return debris

func animate_debris(debris: Sprite2D, velocity: Vector2):
	var tween = create_tween()
	var end_position = debris.global_position + velocity * 0.5
	
	# Arc motion with gravity
	tween.parallel().tween_method(
		func(pos): debris.global_position = pos,
		debris.global_position,
		end_position + Vector2(0, 100),  # Add gravity
		1.0
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Rotation
	tween.parallel().tween_property(debris, "rotation", debris.rotation + TAU * 2, 1.0)
	
	# Fade out
	tween.parallel().tween_property(debris, "modulate:a", 0.0, 1.0)
	
	tween.tween_callback(debris.queue_free)

# Called by effects manager for various impacts
func on_player_land(position: Vector2, force: float):
	create_ripple(position, force / 400.0, Color.WHITE)
	shake_tiles(position, 100.0, force / 200.0, 0.3)
	debris_burst(position, Vector2.UP, force / 600.0)

func on_wall_impact(position: Vector2, normal: Vector2, force: float):
	create_impact_wave(position, -normal, force / 300.0)
	shake_tiles(position, 80.0, force / 250.0, 0.2)

func on_dash_impact(position: Vector2, direction: Vector2, force: float):
	create_ripple(position, force / 300.0, Color.CYAN)
	create_impact_wave(position, direction, force / 400.0)