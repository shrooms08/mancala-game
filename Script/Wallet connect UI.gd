extends Control

@onready var connect_button = $ConnectButton
@onready var status_label = $StatusLabel

var wallet_address = ""

func _ready():
	connect_button.pressed.connect(on_connect_pressed)

func on_connect_pressed():
	status_label.text = "Connecting to wallet..."
	await get_tree().create_timer(1.0).timeout  # Simulated delay

	# Simulate connection logic
	wallet_address = "DemoWallet123ABC456"
	status_label.text = "Connected: %s" % wallet_address
	print("Connected to wallet:", wallet_address)

	# Proceed to game select scene
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scene/game_select.tscn")
