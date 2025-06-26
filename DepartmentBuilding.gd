extends Node2D

@onready var department_sprite = $DepartmentSprite
@onready var inside_sprite = $InsideSprite
@onready var interaction_area = $InteractionArea
@onready var manager = get_node("../Manager")
@onready var handler = get_node("../Handler")

var outside_texture: Texture2D
var inside_texture: Texture2D
var is_inside = false
var crossfade_tween: Tween

func _ready():
	# Load both textures
	outside_texture = load("res://Assets/DepartmentOutside.png")
	inside_texture = load("res://Assets/DepartmentInside.png")
	
	# Set up sprites
	department_sprite.texture = outside_texture
	inside_sprite.texture = inside_texture
	inside_sprite.modulate.a = 0.0  # Start invisible
	
	# Set z-index so inside is behind everything
	inside_sprite.z_index = -10
	department_sprite.z_index = -5
	
	# Initially hide interior objects
	manager.visible = false
	handler.visible = false
	
	# Connect player interaction
	interaction_area.body_entered.connect(_on_player_entered)
	interaction_area.body_exited.connect(_on_player_exited)

func _on_player_entered(body):
	if body.name == "Player" and not is_inside:
		crossfade_to_inside()

func _on_player_exited(body):
	if body.name == "Player" and is_inside:
		crossfade_to_outside()

func crossfade_to_inside():
	is_inside = true
	print("Player entered department - switching to inside view")
	
	# Stop any existing tween
	if crossfade_tween:
		crossfade_tween.kill()
	
	# Create new tween for simultaneous crossfade
	crossfade_tween = create_tween()
	crossfade_tween.set_parallel(true)  # Allow multiple tweens to run simultaneously
	
	# Fade out outside sprite and fade in inside sprite at the same time
	crossfade_tween.tween_property(department_sprite, "modulate:a", 0.0, 0.5)
	crossfade_tween.tween_property(inside_sprite, "modulate:a", 1.0, 0.5)
	
	# Show interior objects after crossfade
	crossfade_tween.tween_callback(func(): 
		manager.visible = true
		handler.visible = true
	)

func crossfade_to_outside():
	is_inside = false
	print("Player exited department - switching to outside view")
	
	# Hide interior objects immediately
	manager.visible = false
	handler.visible = false
	
	# Stop any existing tween
	if crossfade_tween:
		crossfade_tween.kill()
	
	# Create new tween for simultaneous crossfade
	crossfade_tween = create_tween()
	crossfade_tween.set_parallel(true)  # Allow multiple tweens to run simultaneously
	
	# Fade out inside sprite and fade in outside sprite at the same time
	crossfade_tween.tween_property(inside_sprite, "modulate:a", 0.0, 0.5)
	crossfade_tween.tween_property(department_sprite, "modulate:a", 1.0, 0.5)