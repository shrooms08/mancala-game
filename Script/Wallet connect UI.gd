# Wallet connect UI.gd - Enhanced blockchain wallet integration
extends Control

@onready var connect_button = $ConnectButton
@onready var status_label = $StatusLabel
@onready var create_wallet_button = $CreateWalletButton
@onready var wallet_info_panel = $WalletInfoPanel
@onready var wallet_address_label = $WalletInfoPanel/WalletAddressLabel
@onready var balance_label = $WalletInfoPanel/BalanceLabel

var wallet_address = ""
var wallet_private_key = ""
var progress_tracker: Node
var backend_config: BackendConfig

func _ready():
	connect_button.pressed.connect(on_connect_pressed)
	create_wallet_button.pressed.connect(on_create_wallet_pressed)
	
	# Get references to autoloads
	progress_tracker = get_node("/root/GameProgressTracker")
	backend_config = BackendConfig.new()
	
	if progress_tracker:
		progress_tracker.backend_connected.connect(_on_backend_connected)
		progress_tracker.backend_error.connect(_on_backend_error)
	
	# Initialize UI
	wallet_info_panel.visible = false
	create_wallet_button.visible = true
	status_label.text = "Connect your wallet or create a new one"

func on_connect_pressed():
	"""Connect to existing wallet (placeholder for future wallet integration)"""
	status_label.text = "Connecting to wallet..."
	await get_tree().create_timer(1.0).timeout
	
	# For now, simulate connecting to an existing wallet
	# In a real implementation, this would integrate with wallet providers like Phantom, Solflare, etc.
	wallet_address = "DemoWallet123ABC456DEF789"
	wallet_private_key = "demo_private_key_for_testing"
	
	status_label.text = "Connected to existing wallet"
	show_wallet_info()
	
	# Create or get user in backend
	await create_or_get_user_in_backend()

func on_create_wallet_pressed():
	"""Create a new blockchain wallet"""
	status_label.text = "Creating new wallet..."
	await get_tree().create_timer(1.5).timeout
	
	# Generate a new wallet (simulated for now)
	# In a real implementation, this would use proper cryptographic libraries
	wallet_address = generate_new_wallet_address()
	wallet_private_key = generate_new_private_key()
	
	status_label.text = "New wallet created successfully!"
	show_wallet_info()
	
	# Create new user in backend
	await create_or_get_user_in_backend()

func generate_new_wallet_address() -> String:
	"""Generate a new wallet address (simulated)"""
	var timestamp = Time.get_unix_time_from_system()
	var random_suffix = str(randi() % 100000).pad_zeros(5)
	return "wallet_" + str(timestamp) + "_" + random_suffix

func generate_new_private_key() -> String:
	"""Generate a new private key (simulated)"""
	var timestamp = Time.get_unix_time_from_system()
	var random_suffix = str(randi() % 100000).pad_zeros(5)
	return "pk_" + str(timestamp) + "_" + random_suffix

func show_wallet_info():
	"""Display wallet information"""
	wallet_info_panel.visible = true
	create_wallet_button.visible = false
	connect_button.visible = false
	
	wallet_address_label.text = "Address: " + wallet_address.slice(0, 12) + "..."
	balance_label.text = "Balance: 0 MANCALA"
	
	# Store wallet info in GameProgressTracker
	if progress_tracker:
		progress_tracker.set_wallet_info(wallet_address, wallet_private_key)

func create_or_get_user_in_backend() -> void:
	"""Create or get user in backend with wallet integration"""
	if not progress_tracker or not progress_tracker.is_backend_connected:
		status_label.text = "Backend not connected, using local mode"
		await get_tree().create_timer(1.0).timeout
		proceed_to_game()
		return
	
	status_label.text = "Creating user profile..."
	
	# Create user with wallet information
	var username = "Player_" + wallet_address.slice(0, 8)
	var success = progress_tracker.create_or_get_user(wallet_address, username, username)
	
	if success:
		status_label.text = "User profile created successfully!"
		print("✅ User created/retrieved in backend with wallet: ", wallet_address)
		
		# Initialize blockchain profile
		await initialize_blockchain_profile()
	else:
		status_label.text = "Failed to create user profile"
		print("❌ Failed to create user in backend")
	
	await get_tree().create_timer(1.0).timeout
	proceed_to_game()

func initialize_blockchain_profile() -> void:
	"""Initialize user's blockchain profile for missions and rewards"""
	status_label.text = "Initializing blockchain profile..."
	await get_tree().create_timer(1.0).timeout
	
	# In a real implementation, this would:
	# 1. Create a Honeycomb Protocol character profile
	# 2. Initialize mission tracking on-chain
	# 3. Set up reward distribution contracts
	
	status_label.text = "Blockchain profile ready!"

func proceed_to_game():
	"""Proceed to game selection"""
	status_label.text = "Loading game..."
	await get_tree().create_timer(0.5).timeout
	
	# Store wallet info in GameGlobals for use throughout the game
	GameGlobals.current_wallet_address = wallet_address
	GameGlobals.current_wallet_private_key = wallet_private_key
	
	get_tree().change_scene_to_file("res://scene/game_select.tscn")

func _on_backend_connected():
	print("✅ Backend connected in wallet UI!")
	status_label.text = "Backend connected - Ready to create wallet"

func _on_backend_error(error_message: String):
	print("❌ Backend error in wallet UI: ", error_message)
	status_label.text = "Backend error: " + error_message
