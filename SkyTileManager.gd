extends Node2D

# Preload textures to avoid runtime loading issues
var default_sky_texture = preload("res://Assets/Seamless_Sky.PNG")
var wyoming_sky_texture = preload("res://Assets/NewWyomingSeamlessSky.jpg")  # Use the actual file that exists

# Sky tile management
var sky_texture: Texture2D
var tile_size: Vector2
var active_tiles: Dictionary = {}
var camera: Camera2D
var last_camera_pos: Vector2

func _ready():
	# Determine which sky texture to use based on current scene
	var scene_name = get_tree().current_scene.scene_file_path
	print("SkyTileManager: Current scene path: ", scene_name)
	
	if scene_name.contains("Wyoming"):
		print("SkyTileManager: Using Wyoming sky texture")
		sky_texture = wyoming_sky_texture
		tile_size = Vector2(1414, 1414)  # Matches NewWyomingSeamlessSky.jpg size
	else:
		print("SkyTileManager: Using default sky texture")
		sky_texture = default_sky_texture
		tile_size = Vector2(500, 500)  # Matches Seamless_Sky.PNG size
	
	print("SkyTileManager: Sky texture loaded successfully, tile_size=", tile_size)
	
	# Find the camera (it's attached to the player)
	call_deferred("find_camera")

func find_camera():
	var player = get_node("../Player")
	if player:
		# Try to find Camera2D2 first (Main scene), then Camera2D (other scenes)
		camera = player.get_node_or_null("Camera2D2")
		if not camera:
			camera = player.get_node_or_null("Camera2D")
		
		if camera:
			print("SkyTileManager: Found camera: ", camera.name)
		else:
			print("SkyTileManager: No camera found in player")
	else:
		print("SkyTileManager: Player not found")

func _process(_delta):
	if camera:
		var camera_pos = camera.global_position
		
		# Only update if camera moved significantly
		if camera_pos.distance_to(last_camera_pos) > 100:
			update_sky_tiles(camera_pos)
			last_camera_pos = camera_pos

func update_sky_tiles(camera_pos: Vector2):
	# Calculate which tiles should be visible
	var viewport_size = get_viewport().get_visible_rect().size
	var zoom = camera.zoom if camera else Vector2(1, 1)
	var effective_viewport = viewport_size / zoom
	
	# Add some padding to ensure smooth transitions
	var padding = tile_size * 2
	var start_x = int((camera_pos.x - effective_viewport.x/2 - padding.x) / tile_size.x) * tile_size.x
	var end_x = int((camera_pos.x + effective_viewport.x/2 + padding.x) / tile_size.x) * tile_size.x
	var start_y = int((camera_pos.y - effective_viewport.y/2 - padding.y) / tile_size.y) * tile_size.y
	var end_y = int((camera_pos.y + effective_viewport.y/2 + padding.y) / tile_size.y) * tile_size.y
	
	var needed_tiles: Dictionary = {}
	
	# Generate tiles in a grid around the camera
	for x in range(start_x, end_x + tile_size.x, tile_size.x):
		for y in range(start_y, end_y + tile_size.y, tile_size.y):
			var tile_key = Vector2(x, y)
			needed_tiles[tile_key] = true
			
			# Create tile if it doesn't exist
			if not active_tiles.has(tile_key):
				create_sky_tile(tile_key)
	
	# Remove tiles that are no longer needed
	var tiles_to_remove = []
	for tile_key in active_tiles.keys():
		if not needed_tiles.has(tile_key):
			tiles_to_remove.append(tile_key)
	
	for tile_key in tiles_to_remove:
		remove_sky_tile(tile_key)

func create_sky_tile(tile_pos: Vector2):
	if not sky_texture:
		print("ERROR: Cannot create sky tile - no texture loaded")
		return
	
	var sprite = Sprite2D.new()
	sprite.texture = sky_texture
	sprite.position = tile_pos + tile_size / 2  # Center the sprite on the tile
	add_child(sprite)
	active_tiles[tile_pos] = sprite

func remove_sky_tile(tile_pos: Vector2):
	if active_tiles.has(tile_pos):
		var sprite = active_tiles[tile_pos]
		sprite.queue_free()
		active_tiles.erase(tile_pos)