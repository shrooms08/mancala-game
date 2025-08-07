extends Control

# Reference to buttons (set these in the inspector or via @onready)
@onready var vs_friend_button: Button = $VBoxContainer/VsFriendButton
@onready var vs_bot_button: Button = $VBoxContainer/VsBotButton


# Game mode selection
enum GameMode { PVP, PVE }

func _ready():
 # Connect button signals to directly start games
	vs_friend_button.pressed.connect(_on_vs_friend_pressed)
	vs_bot_button.pressed.connect(_on_vs_bot_pressed)

func _on_vs_friend_pressed():
	print("Starting Player vs Player game...")
 
 # Set global game mode (you'll need this in your main game)
	GameGlobals.game_mode = GameGlobals.GameMode.PVP
 
 # Go directly to main game scene
	get_tree().change_scene_to_file("res://scene/main.tscn")

func _on_vs_bot_pressed():
	print("Starting Player vs AI game...")
 
 # Set global game mode
	GameGlobals.game_mode = GameGlobals.GameMode.PVE
	GameGlobals.ai_difficulty = "Medium"  # Default AI difficulty
 
 # Go directly to main game scene
	get_tree().change_scene_to_file("res://scene/main.tscn")
