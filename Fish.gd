extends Area2D

var player_in_range = false
var dialogue_system = null
@onready var interaction_prompt = $InteractionPrompt

# Fish dialogue lines
var dialogue_lines = [
	"Hello there, traveler! I'm just a friendly fish swimming through the void.",
	"Have you tried the grappling hooks? They're quite useful for getting around!",
	"I've been watching you practice those air dashes. Very impressive!",
	"The coins scattered around here? I put them there. Consider them a gift!",
	"This place can be tricky to navigate, but you seem to be getting the hang of it.",
	"I wonder what lies beyond these floating platforms...",
	"Keep practicing those movement techniques - you're doing great!"
]

var current_dialogue_index = 0

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	add_to_group("npcs")
	
	# Find the dialogue system (might not be ready yet, so we'll check again later)
	call_deferred("find_dialogue_system")

func find_dialogue_system():
	dialogue_system = get_tree().get_first_node_in_group("dialogue_system")

func _on_body_entered(body):
	if body.has_method("_physics_process"):  # Check if it's the player
		player_in_range = true
		if interaction_prompt:
			interaction_prompt.visible = true

func _on_body_exited(body):
	if body.has_method("_physics_process"):  # Check if it's the player
		player_in_range = false
		if interaction_prompt:
			interaction_prompt.visible = false

func _input(event):
	if player_in_range and event.is_action_pressed("ui_accept"):  # Spacebar to talk
		start_dialogue()

func start_dialogue():
	if not dialogue_system:
		find_dialogue_system()
	
	if dialogue_system:
		var current_line = dialogue_lines[current_dialogue_index]
		dialogue_system.show_dialogue("Fish", current_line)
		
		# Cycle through dialogue lines
		current_dialogue_index = (current_dialogue_index + 1) % dialogue_lines.size()