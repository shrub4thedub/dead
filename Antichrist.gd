extends Area2D

var is_alive: bool = true

func _ready():
	$Sprite2D.texture = preload("res://Assets/Antichrist_alive.png")

func _on_slash_hit(player):
	if is_alive:
		die()

func die():
	if not is_alive:
		return
	
	is_alive = false
	$Sprite2D.texture = preload("res://Assets/Antichrist_dead.png")
	
	var game_ui = get_tree().get_first_node_in_group("game_ui")
	if game_ui and game_ui.has_method("show_status_text"):
		game_ui.show_status_text("The Antichrist has been slain", Color.RED)
	
	GameState.kill_antichrist()