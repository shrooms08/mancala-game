# Wallet connect UI.gd - Updated to integrate with backend user management
extends Control

@onready var connect_button = $ConnectButton
@onready var status_label = $StatusLabel

var wallet_address = ""
var progress_tracker: Node

func _ready():
	connect_button.pressed.connect(on_connect_pressed)
	
	# Get reference to GameProgressTracker
	progress_tracker = get_node("/root/GameProgressTracker")
	
	if progress_tracker:
		progress_tracker.backend_connected.connect(_on_backend_connected)
		progress_tracker.backend_error.connect(_on_backend_error)

func on_connect_pressed():
	status_label.text = "Connecting to wallet..."
	await get_tree().create_timer(1.0).timeout  # Simulated delay

	# Simulate connection logic
	wallet_address = "DemoWallet123ABC456"
	status_label.text = "Connected: %s" % wallet_address
	print("Connected to wallet:", wallet_address)

	# Create or get user in backend
	if progress_tracker and progress_tracker.is_backend_connected:
		var username = "Player_" + wallet_address.slice(0, 8)
		var success = progress_tracker.create_or_get_user(wallet_address, username, username)
		
		if success:
			status_label.text = "User created in backend: %s" % username
			print("User created/retrieved in backend")
		else:
			status_label.text = "Failed to create user in backend"
			print("Failed to create user in backend")
	else:
		status_label.text = "Backend not connected, using local mode"
		print("Backend not connected, proceeding with local mode")

	# Proceed to game select scene
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scene/game_select.tscn")

func _on_backend_connected():
	print("✅ Backend connected in wallet UI!")
	status_label.text = "Backend connected - Ready to create user"

func _on_backend_error(error_message: String):
	print("❌ Backend error in wallet UI: ", error_message)
	status_label.text = "Backend error: " + error_message
