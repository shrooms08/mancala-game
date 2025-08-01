extends Button

func _ready():
	# Connect the pressed signal (if not already connected via the editor)
	connect("pressed", Callable(self, "_on_pressed"))

func _on_pressed():
	# Get references to the ColorRect and AnimationPlayer
	var transition = get_node("../ColorRect") # Adjust path if needed
	var animation_player = get_node("../AnimationPlayer") # Adjust path if needed
	
	# Play the SlideIn animation
	animation_player.play("SlideIn")
	await animation_player.animation_finished
	
	# Load and change to the new game menu scene
	var new_game_scene = load("res://scene/new_game_menu.tscn")
	get_tree().change_scene_to_packed(new_game_scene)
	
	# Optional: Play SlideOut on the new scene (if implemented there)
	# Note: This line won't execute on the new scene unless AnimationPlayer is global
	# animation_player.play("SlideOut")
