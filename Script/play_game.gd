# play_game.gd - Enhanced play game button with wallet and backend integration
extends Button

@onready var honey_comb: HoneyComb = $"../HoneyComb"

var honeycomb_manager: Node
var progress_tracker: Node
var backend_config: BackendConfig

func _ready():
	# Connect the pressed signal (if not already connected via the editor)
	#connect("pressed", Callable(self, "_on_pressed"))
	print("Play Game button ready")
	
	# Get references to autoloads
	honeycomb_manager = get_node("/root/HoneycombManager")
	progress_tracker = get_node("/root/GameProgressTracker")
	backend_config = BackendConfig.new()
	
	# Connect to progress tracker signals
	if progress_tracker:
		progress_tracker.backend_connected.connect(_on_backend_connected)
		progress_tracker.backend_error.connect(_on_backend_error)
		progress_tracker.wallet_created.connect(_on_wallet_created)
		progress_tracker.blockchain_profile_ready.connect(_on_blockchain_profile_ready)

func _on_pressed():
	print("Play Game button pressed")
	
	# Check if user has a wallet connected
	if not GameGlobals.is_wallet_connected():
		print("No wallet connected, creating new wallet automatically")
		await redirect_to_wallet_creation()
		# After wallet creation, proceed to game selection
		proceed_to_game_select()
		return
	
	# Check if backend is connected
	if not progress_tracker or not progress_tracker.is_backend_connected:
		print("Backend not connected, proceeding with local mode")
		proceed_to_game_select()
		return
	
	# Set up Honeycomb integration if available
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
	
	# Initialize user in backend if not already done
	await initialize_user_in_backend()
	
	# Proceed to game selection
	proceed_to_game_select()

func redirect_to_wallet_creation():
	"""Redirect user to wallet creation/connection screen"""
	print("Redirecting to wallet creation...")
	
	# Automatically create a new wallet for the user
	await create_new_wallet_for_user()
	
	# Note: proceed_to_game_select() is called from _on_pressed() after this function returns

func create_new_wallet_for_user():
	"""Automatically create a new wallet for the user"""
	print("Creating new wallet for user...")
	
	# Show creating wallet message
	show_wallet_required_message()
	await get_tree().create_timer(1.0).timeout
	
	# Create new wallet using GameProgressTracker
	if progress_tracker:
		print("🔑 Generating blockchain wallet...")
		var wallet_data = progress_tracker.create_blockchain_wallet()
		print("✅ New wallet created: ", wallet_data.address)
		
		# Set wallet info in GameGlobals
		GameGlobals.set_wallet_info(wallet_data.address, wallet_data.private_key)
		
		# Create user in backend
		print("👤 Creating user profile in backend...")
		var username = "Player_" + wallet_data.address.slice(0, 8)
		var success = progress_tracker.create_or_get_user(wallet_data.address, username, username)
		
		if success:
			print("✅ User created in backend with wallet: ", wallet_data.address)
			
			# Initialize blockchain profile
			print("🌐 Initializing blockchain profile...")
			await progress_tracker.initialize_blockchain_profile()
			print("✅ Blockchain profile ready!")
		else:
			print("❌ Failed to create user in backend")
	else:
		print("❌ Progress tracker not available")
	
	print("🎮 Ready to play! Redirecting to game selection...")
	await get_tree().create_timer(1.0).timeout

func show_wallet_required_message():
	"""Show message that wallet is required"""
	# You could show a popup or update UI here
	print("🔐 Creating new blockchain wallet...")
	print("⏳ Please wait while we set up your wallet and blockchain profile...")

func initialize_user_in_backend() -> void:
	"""Initialize user profile in backend"""
	var wallet_address = GameGlobals.get_wallet_address()
	
	if wallet_address == "":
		print("No wallet address available")
		return
	
	print("Initializing user in backend with wallet: ", wallet_address)
	
	# Create or get user in backend
	var username = "Player_" + wallet_address.slice(0, 8)
	var success = progress_tracker.create_or_get_user(wallet_address, username, username)
	
	if success:
		print("✅ User initialized in backend successfully")
		
		# Initialize blockchain profile if not already done
		if not progress_tracker.is_blockchain_profile_ready():
			await progress_tracker.initialize_blockchain_profile()
	else:
		print("❌ Failed to initialize user in backend")

func proceed_to_game_select():
	"""Proceed to game selection screen"""
	print("Proceeding to game selection...")
	
	# Get references to the ColorRect and AnimationPlayer
	var transition = get_node("../ColorRect") # Adjust path if needed
	var animation_player = get_node("../AnimationPlayer") # Adjust path if needed
	
	# Play the SlideIn animation
	if animation_player:
		animation_player.play("SlideIn")
		await animation_player.animation_finished
	
	# Load and change to the new game menu scene
	var new_game_scene = load("res://scene/game_select.tscn")
	get_tree().change_scene_to_packed(new_game_scene)

# Signal handlers

func _on_backend_connected():
	print("✅ Backend connected in play game button!")
	# Backend is now available for user initialization

func _on_backend_error(error_message: String):
	print("❌ Backend error in play game button: ", error_message)
	# Handle backend connection errors

func _on_wallet_created(wallet_address: String):
	print("✅ Wallet created: ", wallet_address)
	# Wallet is ready for use

func _on_blockchain_profile_ready():
	print("✅ Blockchain profile ready!")
	# User's blockchain profile is initialized and ready for missions/rewards

# Honeycomb signal handlers (if needed)
func _on_honeycomb_connected():
	print("✅ Connected to Honeycomb Protocol!")

func _on_honeycomb_error(error_message: String):
	print("❌ Honeycomb Error: ", error_message)

func _on_xp_gained(amount: int):
	print("🎉 XP Gained: +", amount)

func _on_level_up(new_level: int):
	print("🎊 LEVEL UP! New level: ", new_level)

func _on_mission_completed(mission_id: String, reward_xp: int):
	print("🏆 Mission Completed: ", mission_id, " (+", reward_xp, " XP)")
