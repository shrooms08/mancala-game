extends Control


#Reference to buttons(set these in the inspector or via @onready)
@onready var vs_friend_button: Button = $VBoxContainer/VsFriendButton
@onready var vs_bot_button: Button = $VBoxContainer/VsBotButton


#Game Mode Selection
enum GameMode {PVP, PVE}

func _ready():
	print("READY CHECK")
	print("Game Selector children:")
	for child in get_children():
		print("  - Child: ", child.name, " (", child.get_class(), ")")
  
		if child.name == "VBoxContainer":
			print("    VBoxContainer children:")
   
			for grandchild in child.get_children():
				print("      - ", grandchild.name, " (", grandchild.get_class(), ")")

 # Try direct access
	var vbox = $VBoxContainer
	print("VBoxContainer found: ", vbox != null)
 
	if vbox:
		var friend_btn = vbox.get_node("VsFriendButton")
		var bot_btn = vbox.get_node("VsBotButton")
		print("Friend button: ", friend_btn)
		print("Bot button: ", bot_btn)
	
	
func _on_vs_friend_button_pressed():
	print ("Starting Player vs Player game...")
	#Set global game mode(you'll need this in your main game)
	GameGlobals.game_mode = GameGlobals.GameMode.PVP
	
	#Go directly to main game scene
	get_tree().change_scene_to_file("res://scene/main.tscn")
	
func _on_vs_bot_button_pressed():
	print ("Starting Player vs AI game...")
	#Set global game mode(you'll need this in your main game)
	GameGlobals.game_mode = GameGlobals.GameMode.PVE
	GameGlobals.ai_difficulty = "Medium"  #Default AI difficulty
	
	#Go directly to main game scene
	get_tree().change_scene_to_file("res://scene/main.tscn")
