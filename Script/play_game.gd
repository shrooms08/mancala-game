extends Button

@onready var honey_comb: HoneyComb = $"../HoneyComb"

var honeycomb_manager: Node

func _ready():
	# Connect the pressed signal (if not already connected via the editor)
	#connect("pressed", Callable(self, "_on_pressed"))
	print("Main ready called")
	#randomize()
	print("Game starting...")
	
	# Get reference to HoneycombManager autoload (you'll need to add this to autoload)
	honeycomb_manager = get_node("/root/HoneycombManager")

func _on_pressed():
	print("Pressed")
	
	print(honey_comb)
	
	# Set up Honeycomb integration
	if honey_comb and honeycomb_manager:
		print("Setting up Honeycomb integration...")
		honeycomb_manager.set_honeycomb_node(honey_comb)
		
		# Connect to Honeycomb signals
		#honeycomb_manager.honeycomb_connected.connect(_on_honeycomb_connected)
		#honeycomb_manager.honeycomb_error.connect(_on_honeycomb_error)
		#honeycomb_manager.xp_gained.connect(_on_xp_gained)
		#honeycomb_manager.level_up.connect(_on_level_up)
		#honeycomb_manager.mission_completed.connect(_on_mission_completed)
	else:
		print("WARNING: Honeycomb integration not available")
		
	# Get references to the ColorRect and AnimationPlayer
	var transition = get_node("../ColorRect") # Adjust path if needed
	var animation_player = get_node("../AnimationPlayer") # Adjust path if needed
	
	# Play the SlideIn animation
	animation_player.play("SlideIn")
	await animation_player.animation_finished
	
	# Load and change to the new game menu scene
	var new_game_scene = load("res://scene/game_select.tscn")
	get_tree().change_scene_to_packed(new_game_scene)
	
	# Optional: Play SlideOut on the new scene (if implemented there)
	# Note: This line won't execute on the new scene unless AnimationPlayer is global
	# animation_player.play("SlideOut")
