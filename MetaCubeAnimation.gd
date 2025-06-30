extends Node2D
class_name MetaCubeAnimation

@onready var sprite: Sprite2D
var frame_textures: Array[Texture2D] = []
var current_frame: int = 0
var frame_direction: int = 1  # 1 for forward, -1 for backward (ping-pong)
var animation_speed: float = 0.08  # Time between frames
var animation_timer: float = 0.0

func _ready():
	# Create sprite
	sprite = Sprite2D.new()
	add_child(sprite)
	
	# Load all frame textures
	load_frame_textures()
	
	# Set initial frame
	if frame_textures.size() > 0:
		sprite.texture = frame_textures[0]
		current_frame = 0
	
	# Position to ensure full visibility - accounting for 224x224 frame size
	# With 1.5 scale = ~336x336 pixels, position at (168, 168) centers it properly
	position = Vector2(168, 168)  # Half of scaled size to center it properly
	
	# Set proper z-index to be behind UI text
	z_index = -1
	
	# Make it bigger and more prominent
	scale = Vector2(1.5, 1.5)
	
	# Keep it fully opaque
	modulate.a = 1.0

func load_frame_textures():
	frame_textures.clear()
	
	# Load all 102 frames
	for i in range(1, 103):  # frame_0001.png to frame_0102.png
		var frame_path = "res://Assets/MetaCube_Frames/frame_%04d.png" % i
		var texture = load(frame_path) as Texture2D
		if texture:
			frame_textures.append(texture)
		else:
			print("Failed to load frame: ", frame_path)

func _process(delta):
	if frame_textures.size() == 0:
		return
	
	animation_timer += delta
	
	if animation_timer >= animation_speed:
		animation_timer = 0.0
		
		# Update frame with ping-pong logic
		current_frame += frame_direction
		
		# Check bounds for ping-pong
		if current_frame >= frame_textures.size() - 1:
			current_frame = frame_textures.size() - 1
			frame_direction = -1  # Reverse direction
		elif current_frame <= 0:
			current_frame = 0
			frame_direction = 1  # Forward direction
		
		# Update sprite texture
		sprite.texture = frame_textures[current_frame]

func set_animation_speed(new_speed: float):
	animation_speed = new_speed

func set_scale_factor(new_scale: float):
	scale = Vector2(new_scale, new_scale)

func set_opacity(new_opacity: float):
	modulate.a = new_opacity

func set_position_offset(offset: Vector2):
	position = Vector2(168, 168) + offset