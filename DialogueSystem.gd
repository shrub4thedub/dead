extends Control

@onready var dialogue_box = $DialogueBox
@onready var character_name_label = $DialogueBox/CharacterName
@onready var dialogue_text_label = $DialogueBox/DialogueText
@onready var continue_prompt = $DialogueBox/ContinuePrompt

var is_dialogue_active = false
var dialogue_queue = []
var current_dialogue_index = 0

func _ready():
	add_to_group("dialogue_system")
	hide_dialogue()

func _input(event):
	if is_dialogue_active and event.is_action_pressed("ui_accept"):
		advance_dialogue()

func show_dialogue(character_name: String, text: String):
	character_name_label.text = character_name
	dialogue_text_label.text = text
	dialogue_box.visible = true
	is_dialogue_active = true
	
	# Pause player movement during dialogue
	get_tree().paused = false  # Keep game running but we'll handle input blocking

func hide_dialogue():
	dialogue_box.visible = false
	is_dialogue_active = false

func advance_dialogue():
	hide_dialogue()

func start_dialogue_sequence(character_name: String, lines: Array[String]):
	dialogue_queue = lines
	current_dialogue_index = 0
	show_dialogue_from_queue(character_name)

func show_dialogue_from_queue(character_name: String):
	if current_dialogue_index < dialogue_queue.size():
		show_dialogue(character_name, dialogue_queue[current_dialogue_index])
		current_dialogue_index += 1
	else:
		hide_dialogue()
		dialogue_queue.clear()
		current_dialogue_index = 0
	
