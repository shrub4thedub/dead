extends Area2D

var player_nearby = false
var dialogue_system = null
@onready var prompt_label = $PromptLabel
@onready var sprite = $Sprite2D

# Floating animation variables
var float_time = 0.0
var base_position: Vector2

var conversation_sets = [
	[
		"Welcome to the Department of Death. How can I be of assistance?",
	],
	[
		"Ah, an applicant for the open position. I see.",
	],
	[
		"Yes, the position is... still available. Any past experience?",
	],
	[
		"I see. Wonderful. Yes, you seem like a good fit.",
	],
	[
		"We will have you assigned to a trial mission, to... test the waters.",
	],
	[
		"I would give you a standard issue sycthe, but it appears you have brought your own. I like a well prepared employee.",
	],
	[
		"Your co-workers are mostly occupied with missions as of now. You can speak to the handler to get information on your trial mission.",
	],
	[
		"Run along now.",
	],
	[
		"Go on, I haven't got all day.",
	]
]

var current_conversation_index = 0

func _ready():
	add_to_group("manager")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	base_position = sprite.position
	# Set LiberationSans Bold Italic font for prompt label
	var liberation_font = load("res://Assets/LiberationSans-BoldItalic.ttf") as FontFile
	prompt_label.add_theme_font_override("font", liberation_font)
	prompt_label.scale = Vector2(1.0, 1.2)  # 1.2x vertical stretch
	# Find dialogue system after scene is ready
	call_deferred("find_dialogue_system")

func _process(delta):
	float_time += delta
	
	# Floating animation only (no shaking like the fish)
	var float_offset = sin(float_time * 1.5) * 4.0  # Slightly slower and higher than fish
	sprite.position = base_position + Vector2(0, float_offset)

func find_dialogue_system():
	dialogue_system = get_tree().get_first_node_in_group("dialogue_system")

func _on_body_entered(body):
	if body.name == "Player":
		player_nearby = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body):
	if body.name == "Player":
		player_nearby = false
		if prompt_label:
			prompt_label.visible = false

func _input(event):
	if player_nearby and event.is_action_pressed("interact"):
		talk_to_manager()

func talk_to_manager():
	if not dialogue_system:
		find_dialogue_system()
	
	if dialogue_system:
		# Hide the Press F prompt during dialogue
		if prompt_label:
			prompt_label.visible = false
		
		# Get current conversation set
		var current_conversation = conversation_sets[current_conversation_index]
		dialogue_system.start_conversation("Manager", current_conversation)
		
		# Show employment status text after the employment conversation (conversation 7: "Run along now.")
		if current_conversation_index == 7:
			show_employment_status("You are now employed")
		
		# Move to next conversation for next time
		current_conversation_index = (current_conversation_index + 1) % conversation_sets.size()

func _on_dialogue_ended():
	# Show the Press F prompt again when dialogue ends (if player is still nearby)
	if player_nearby and prompt_label:
		prompt_label.visible = true

func start_speaking(text: String):
	# Manager doesn't shake when speaking, but this function is needed for dialogue system integration
	pass

func _on_mission_completed():
	# Manager disappears when mission is completed
	# Create a fade out effect
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 1.0)
	tween.tween_callback(func(): queue_free())

func show_employment_status(text: String, color: Color = Color.WHITE):
	# Find the GameUI and show status text
	var game_ui = get_tree().get_first_node_in_group("game_ui")
	if not game_ui:
		# Try to find it through the main scene
		var main_scene = get_tree().get_first_node_in_group("main_scene")
		if main_scene:
			for child in main_scene.get_children():
				if child.has_method("show_status_text"):
					game_ui = child
					break
	
	if game_ui and game_ui.has_method("show_status_text"):
		game_ui.show_status_text(text, color)

func get_conversation_index():
	return current_conversation_index
