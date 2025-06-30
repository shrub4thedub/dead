extends CanvasLayer

var transition_overlay: ColorRect
var screen_captures: Array[TextureRect]
var transition_tween: Tween
var distortion_timer: float = 0.0
var is_distorting: bool = false
var old_scene_texture: ImageTexture
var new_scene_texture: ImageTexture
var is_scene_transition: bool = false

func _ready():
	# Add to group so doors can find this transition system
	add_to_group("scene_transition")
	
	# Create the transition overlay
	transition_overlay = ColorRect.new()
	transition_overlay.color = Color.BLACK
	transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_overlay.modulate.a = 0.0
	add_child(transition_overlay)
	
	# Check if we should skip transition (like on main menu first load)
	var main_scene = get_tree().get_first_node_in_group("main_scene")
	var should_skip = false
	
	if main_scene and "is_title_active" in main_scene:
		# Skip transition if title screen is active (first game load)
		should_skip = main_scene.is_title_active
	
	# Start the distortion effect if we shouldn't skip it
	if not should_skip:
		call_deferred("start_transition_effect")

func _input(event):
	# Debug: Press H to trigger transition effect (debug builds only)
	if OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_H:
		start_transition_effect()

func start_transition_effect():
	# Don't restrict player movement during transition
	
	# Start distortion
	is_distorting = true
	distortion_timer = 0.0
	
	# Create multiple trailing screen copies
	create_screen_trails()
	
	# Create the main transition tween
	transition_tween = create_tween()
	
	# Phase 1: Distortion (0.8 seconds)
	transition_tween.tween_callback(end_distortion).set_delay(0.8)
	
	# Phase 2: Quick fade out (0.2 seconds) - shorter to avoid freeze
	transition_tween.tween_callback(end_transition).set_delay(0.8)

# Smooth scene transition with fade to black
func start_scene_transition(target_scene_path: String):
	print("Starting scene transition to: ", target_scene_path)
	
	# Skip file existence check in exported builds (FileAccess might not work)
	if OS.is_debug_build():
		if not FileAccess.file_exists(target_scene_path):
			print("ERROR: Scene file does not exist: ", target_scene_path)
			return
	
	# Start the blur effect (will handle shader loading gracefully)
	start_transition_effect()
	
	# Immediately start fade to black
	transition_overlay.modulate.a = 0.0
	var fade_tween = create_tween()
	fade_tween.tween_property(transition_overlay, "modulate:a", 1.0, 0.4)
	
	# Change scene after fade
	fade_tween.tween_callback(func():
		print("Tween callback - changing scene to: ", target_scene_path)
		var error = get_tree().change_scene_to_file(target_scene_path)
		if error != OK:
			print("ERROR: Failed to change scene: ", error)
			# Reset overlay if scene change failed
			transition_overlay.modulate.a = 0.0
		else:
			print("Scene change successful")
	).set_delay(0.4)

func set_overlay_color(color: Color):
	transition_overlay.color = color

func add_camera_shake(camera: Camera2D, duration: float):
	var original_offset = camera.offset
	var shake_intensity = 15.0
	var shake_frequency = 20.0
	
	# Create rapid camera shaking
	for i in range(int(duration * shake_frequency)):
		var delay = i / shake_frequency
		var shake_x = randf_range(-shake_intensity, shake_intensity)
		var shake_y = randf_range(-shake_intensity, shake_intensity)
		
		transition_tween.tween_property(camera, "offset", original_offset + Vector2(shake_x, shake_y), 0.05).set_delay(delay)
	
	# Return camera to original position
	transition_tween.tween_property(camera, "offset", original_offset, 0.1).set_delay(duration)

func create_screen_trails():
	# Clear any existing trails
	for capture in screen_captures:
		if is_instance_valid(capture):
			capture.queue_free()
	screen_captures.clear()
	
	# Get current screen content
	var viewport = get_viewport()
	await RenderingServer.frame_post_draw
	var screen_image = viewport.get_texture().get_image()
	var screen_texture = ImageTexture.create_from_image(screen_image)
	
	# Load the gaussian blur shader, fallback to simple blur, gracefully handle missing shaders
	var blur_shader = null
	if ResourceLoader.exists("res://gaussian_blur.gdshader"):
		blur_shader = load("res://gaussian_blur.gdshader")
		print("Successfully loaded gaussian blur shader")
	elif ResourceLoader.exists("res://simple_blur.gdshader"):
		blur_shader = load("res://simple_blur.gdshader")
		print("Successfully loaded simple blur shader")
	else:
		print("WARNING: No blur shaders found, skipping visual effects")
		# Continue without shaders - just show basic screen captures
	
	# Get viewport size for proper sizing
	var viewport_size = viewport.get_visible_rect().size
	
	# Create 6 trailing copies with gaussian blur shader
	for i in range(6):
		var trail_copy = TextureRect.new()
		trail_copy.texture = screen_texture
		trail_copy.size = viewport_size
		trail_copy.position = Vector2.ZERO
		
		# Create shader material with blur if shader is available
		if blur_shader:
			var material = ShaderMaterial.new()
			material.shader = blur_shader
			var blur_value = float(i + 1) * 0.5
			
			# Set blur parameter (try both names)
			material.set_shader_parameter("blur_strength", blur_value)
			material.set_shader_parameter("blur_amount", blur_value)
			
			# Set alpha multiplier for proper opacity
			var opacity = 0.4 - (i * 0.05)  # Decreasing opacity: 0.4, 0.35, 0.3, 0.25, 0.2, 0.15
			material.set_shader_parameter("alpha_multiplier", max(0.1, opacity))
			
			trail_copy.material = material
		else:
			# Fallback: use modulate for opacity without shader effects
			var opacity = 0.4 - (i * 0.05)
			trail_copy.modulate = Color(1.0, 1.0, 1.0, max(0.1, opacity))
		print("Created trail ", i, " with shader: ", blur_shader != null)
		
		# Set modulate to full opacity only if using shader (otherwise already set above)
		if blur_shader:
			trail_copy.modulate = Color(1.0, 1.0, 1.0, 1.0)
		trail_copy.z_index = 15 + i
		
		# Use simple stretch to maintain aspect
		trail_copy.stretch_mode = TextureRect.STRETCH_KEEP
		
		add_child(trail_copy)
		screen_captures.append(trail_copy)

func _process(delta):
	if is_distorting:
		distortion_timer += delta
		
		# Animate the screen trails with more floaty, dream-like movement
		for i in range(screen_captures.size()):
			var trail = screen_captures[i]
			if is_instance_valid(trail):
				# Smoother, floatier movement with sine waves
				var time_offset = distortion_timer + i * 0.4
				var base_intensity = 20.0 + i * 8.0
				
				# Multiple overlapping sine waves for organic movement
				var shake_x = sin(time_offset * 3.0 + i) * base_intensity
				shake_x += sin(time_offset * 7.0 + i * 2.0) * (base_intensity * 0.5)
				shake_x += sin(time_offset * 1.5 + i * 0.5) * (base_intensity * 0.3)
				
				var shake_y = cos(time_offset * 2.5 + i * 1.2) * base_intensity
				shake_y += cos(time_offset * 5.5 + i * 1.8) * (base_intensity * 0.4)
				shake_y += cos(time_offset * 1.2 + i * 0.8) * (base_intensity * 0.6)
				
				# Gentle waning effect that builds slowly
				var chaos_multiplier = 1.0 + (distortion_timer * distortion_timer) * 0.8
				shake_x *= chaos_multiplier
				shake_y *= chaos_multiplier
				
				# Set position with floating movement
				trail.position = Vector2(shake_x, shake_y)
				
				# Gentler rotation with floating motion  
				trail.rotation += sin(time_offset * 2.0 + i) * 0.015 * delta
				
				# Dynamic blur strength modulation for shader (only if shader is available)
				if trail.material and trail.material is ShaderMaterial:
					var base_strength = float(i + 1) * 0.5
					var dynamic_strength = base_strength + sin(time_offset * 1.5) * 1.0
					dynamic_strength = max(0.1, min(5.0, dynamic_strength))  # Clamp to reasonable limits
					# Set both parameter names
					trail.material.set_shader_parameter("blur_strength", dynamic_strength)
					trail.material.set_shader_parameter("blur_amount", dynamic_strength)

func end_distortion():
	is_distorting = false
	
	# Quick fade out of all trailing copies to avoid freezing
	for i in range(screen_captures.size()):
		var trail = screen_captures[i]
		if is_instance_valid(trail):
			var fade_tween = create_tween()
			var fade_delay = i * 0.02  # Much shorter stagger
			var fade_duration = 0.3    # Much shorter fade
			
			# Quick settle and fade
			fade_tween.tween_property(trail, "position", Vector2.ZERO, 0.1).set_delay(fade_delay)
			fade_tween.parallel().tween_property(trail, "rotation", 0.0, 0.1).set_delay(fade_delay)
			fade_tween.tween_property(trail, "modulate:a", 0.0, fade_duration).set_delay(fade_delay + 0.1)
			fade_tween.tween_callback(trail.queue_free).set_delay(fade_delay + 0.1 + fade_duration)

func end_transition():
	# Player movement was never disabled, no need to re-enable
	
	# Clean up any remaining trails
	for trail in screen_captures:
		if is_instance_valid(trail):
			trail.queue_free()
	screen_captures.clear()
	
	print("Scene transition effect completed")

func create_blended_transition():
	# Clear any existing trails
	for capture in screen_captures:
		if is_instance_valid(capture):
			capture.queue_free()
	screen_captures.clear()
	
	# Get viewport size
	var viewport = get_viewport()
	var viewport_size = viewport.get_visible_rect().size
	
	# Load blur shader with graceful fallback
	var blur_shader = null
	if ResourceLoader.exists("res://gaussian_blur.gdshader"):
		blur_shader = load("res://gaussian_blur.gdshader")
	elif ResourceLoader.exists("res://simple_blur.gdshader"):
		blur_shader = load("res://simple_blur.gdshader")
	else:
		print("WARNING: No blur shaders found for blended transition")
		# Continue without shaders
	
	# Create blended copies showing transition from old to new scene
	for i in range(6):
		var trail_copy = TextureRect.new()
		trail_copy.size = viewport_size
		trail_copy.position = Vector2.ZERO
		
		# Blend ratio: 0 = all old scene, 1 = all new scene
		var blend_ratio = float(i) / 5.0
		
		# Use old scene texture for early frames, new scene for later frames
		if blend_ratio < 0.5:
			trail_copy.texture = old_scene_texture
		else:
			trail_copy.texture = new_scene_texture
		
		# Create shader material with blur if shader is available
		var opacity = 0.4 - (i * 0.05)
		if blend_ratio < 0.5:
			# Old scene fading out
			opacity *= (1.0 - blend_ratio * 2.0)
		else:
			# New scene fading in
			opacity *= ((blend_ratio - 0.5) * 2.0)
		
		if blur_shader:
			var material = ShaderMaterial.new()
			material.shader = blur_shader
			var blur_value = float(i + 1) * 0.3
			
			# Set shader parameters
			material.set_shader_parameter("blur_strength", blur_value)
			material.set_shader_parameter("blur_amount", blur_value)
			material.set_shader_parameter("alpha_multiplier", max(0.1, opacity))
			
			trail_copy.material = material
			trail_copy.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			# Fallback: use modulate for opacity without shader effects
			trail_copy.modulate = Color(1.0, 1.0, 1.0, max(0.1, opacity))
		trail_copy.z_index = 15 + i
		trail_copy.stretch_mode = TextureRect.STRETCH_KEEP
		
		add_child(trail_copy)
		screen_captures.append(trail_copy)
	
	# Start the blended distortion effect
	is_distorting = true
	distortion_timer = 0.0
	
	# Create transition tween
	transition_tween = create_tween()
	transition_tween.tween_callback(end_distortion).set_delay(0.8)
	transition_tween.tween_callback(end_transition).set_delay(0.8)
