# HoneycombManager.gd - Updated to connect to Node.js Backend
extends Node

# Backend configuration
var backend_config: BackendConfig
var backend_url: String = "http://localhost:8080"
var is_backend_connected: bool = false
var project_address: String = ""

# Player progression data
var player_xp: int = 0
var player_level: int = 1
var player_traits: Array = []
var active_missions: Dictionary = {}
var completed_missions: Array = []
var character_address: String = ""
var user_profile_address: String = ""

# Mission definitions
var missions = {
	"first_victory": {
		"name": "First Victory",
		"description": "Win your first game",
		"target": 1,
		"current": 0,
		"reward_xp": 50,
		"completed": false
	},
	"capture_master": {
		"name": "Capture Master", 
		"description": "Capture 10 stones total",
		"target": 10,
		"current": 0,
		"reward_xp": 100,
		"completed": false
	},
	"extra_turn_pro": {
		"name": "Extra Turn Pro",
		"description": "Get 5 extra turns in games",
		"target": 5,
		"current": 0,
		"reward_xp": 75,
		"completed": false
	},
	"ai_slayer": {
		"name": "AI Slayer",
		"description": "Beat Hard AI 3 times",
		"target": 3,
		"current": 0,
		"reward_xp": 200,
		"completed": false
	},
	"speed_demon": {
		"name": "Speed Demon",
		"description": "Make 10 moves in under 5 seconds",
		"target": 10,
		"current": 0,
		"reward_xp": 150,
		"completed": false
	}
}

# HTTP client for backend communication
var http_client: HTTPRequest
var connection_retry_count: int = 0
var max_retries: int = 3

# Signals for UI updates
signal xp_gained(amount)
signal level_up(new_level)
signal mission_progress(mission_id, current, target)
signal mission_completed(mission_id, reward_xp)
signal trait_unlocked(trait_id)
signal backend_connected()
signal backend_error(message)

func _ready():
	print("Honeycomb Manager initialized - Backend Mode")
	
	# Load backend configuration
	load_backend_config()
	
	http_client = HTTPRequest.new()
	add_child(http_client)
	http_client.request_completed.connect(_on_http_request_completed)
	
	# Try to connect to backend
	connect_to_backend()

func load_backend_config():
	"""Load backend configuration from resource file"""
	backend_config = BackendConfig.new()
	backend_url = backend_config.get_full_backend_url()
	print("Backend URL configured: ", backend_url)

func connect_to_backend():
	"""Connect to the Node.js backend server"""
	print("Connecting to backend at: ", backend_url)
	
	# Test backend connection with health check
	var headers = ["Content-Type: application/json"]
	var url = backend_config.get_health_check_url()
	
	var error = http_client.request(url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		print("ERROR: Failed to send health check request")
		backend_error.emit("Failed to connect to backend")
		return
	
	print("Health check request sent to backend")

func retry_connection():
	"""Retry backend connection with exponential backoff"""
	if connection_retry_count < max_retries:
		connection_retry_count += 1
		var delay = pow(2, connection_retry_count) # Exponential backoff: 2, 4, 8 seconds
		print("Retrying backend connection in ", delay, " seconds... (attempt ", connection_retry_count, "/", max_retries, ")")
		
		var timer = get_tree().create_timer(delay)
		await timer.timeout
		connect_to_backend()
	else:
		print("Max retry attempts reached. Backend connection failed.")
		backend_error.emit("Failed to connect to backend after " + str(max_retries) + " attempts")

func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	"""Handle HTTP responses from backend"""
	var response_body = body.get_string_from_utf8()
	print("Backend response: ", response_code, " - ", response_body)
	
	if response_code == 200:
		var json = JSON.new()
		var parse_result = json.parse(response_body)
		if parse_result == OK:
			var data = json.get_data()
			handle_backend_response(data)
		else:
			print("ERROR: Failed to parse backend response")
			backend_error.emit("Invalid backend response format")
	elif response_code == 0:
		# Connection failed - retry
		print("Connection failed, attempting retry...")
		retry_connection()
	else:
		print("ERROR: Backend request failed with code: ", response_code)
		backend_error.emit("Backend request failed: " + str(response_code))
		
		# Reset retry count on successful response
		connection_retry_count = 0

func handle_backend_response(data: Dictionary):
	"""Process successful responses from backend"""
	if data.has("ok") and data.ok:
		if data.has("project"):
			project_address = data.project
			print("Backend project address: ", project_address)
		
		if data.has("bootstrapped") and data.bootstrapped:
			is_backend_connected = true
			backend_connected.emit()
			print("✅ Backend connected successfully!")
			
			# Initialize player profile if we have a project
			if project_address != "":
				initialize_player_profile()
	else:
		print("Backend response indicates error: ", data)

func initialize_player_profile():
	"""Initialize player profile on the backend"""
	if not is_backend_connected:
		print("Backend not connected, skipping profile initialization")
		return
	
	print("Initializing player profile on backend...")
	
	# For now, use a placeholder wallet address
	# In a real implementation, this would come from the connected wallet
	var placeholder_wallet = "placeholder_wallet_address_12345678901234567890123456789012"
	
	var profile_data = {
		"userPubkey": placeholder_wallet
	}
	
	var headers = ["Content-Type: application/json"]
	var url = backend_config.get_users_endpoint()
	
	var json_string = JSON.stringify(profile_data)
	var error = http_client.request(url, headers, HTTPClient.METHOD_POST, json_string)
	
	if error != OK:
		print("ERROR: Failed to send profile creation request")
		backend_error.emit("Failed to create profile")
		return
	
	print("Profile creation request sent to backend")

func grant_xp(amount: int, reason: String):
	"""Grant XP to player via backend"""
	print("Granting ", amount, " XP for: ", reason)
	
	var old_level = calculate_level(player_xp)
	player_xp += amount
	var new_level = calculate_level(player_xp)
	
	# Send XP grant to backend
	if is_backend_connected and user_profile_address != "":
		send_xp_grant_to_backend(amount, reason)
	
	xp_gained.emit(amount)
	
	if new_level > old_level:
		player_level = new_level
		level_up.emit(new_level)
		check_trait_unlocks()

func send_xp_grant_to_backend(amount: int, reason: String):
	"""Send XP grant request to backend"""
	var xp_data = {
		"userPubkey": user_profile_address,
		"amount": amount,
		"reason": reason
	}
	
	var headers = ["Content-Type: application/json"]
	var url = backend_config.get_game_endpoint() + "/grant-xp"
	
	var json_string = JSON.stringify(xp_data)
	var error = http_client.request(url, headers, HTTPClient.METHOD_POST, json_string)
	
	if error != OK:
		print("ERROR: Failed to send XP grant request to backend")
	else:
		print("XP grant request sent to backend: ", amount, " XP for ", reason)

func progress_mission(mission_id: String, amount: int = 1):
	"""Progress a mission both locally and on-chain"""
	if missions.has(mission_id) and not missions[mission_id]["completed"]:
		missions[mission_id]["current"] += amount
		var current = missions[mission_id]["current"]
		var target = missions[mission_id]["target"]
		
		print("Mission progress - ", mission_id, ": ", current, "/", target)
		mission_progress.emit(mission_id, current, target)
		
		if current >= target:
			complete_mission(mission_id)

func complete_mission(mission_id: String):
	"""Complete a mission and grant rewards"""
	if missions.has(mission_id) and not missions[mission_id]["completed"]:
		missions[mission_id]["completed"] = true
		var reward_xp = missions[mission_id]["reward_xp"]
		
		print("Mission completed: ", missions[mission_id]["name"])
		mission_completed.emit(mission_id, reward_xp)
		
		# Grant reward XP
		grant_xp(reward_xp, "Mission: " + missions[mission_id]["name"])

func calculate_level(xp: int) -> int:
	"""Calculate level from XP using square root progression"""
	return int(sqrt(xp / 100.0)) + 1

func get_xp_for_level(level: int) -> int:
	"""Calculate XP required for a specific level"""
	return (level - 1) * (level - 1) * 100

func get_player_stats() -> Dictionary:
	"""Get current player statistics"""
	return {
		"xp": player_xp,
		"level": player_level,
		"traits": player_traits,
		"missions": missions,
		"character_address": character_address,
		"project_address": project_address,
		"backend_connected": is_backend_connected
	}

# GAME EVENT HANDLERS - Called from your Mancala game

func on_game_won(vs_ai: bool, ai_difficulty: String = ""):
	"""Handle game victory event"""
	var base_xp = 100
	var bonus_xp = 0
	
	if vs_ai:
		match ai_difficulty:
			"Easy": 
				bonus_xp = 10
			"Medium": 
				bonus_xp = 25
			"Hard":
				bonus_xp = 50
				progress_mission("ai_slayer")
	
	grant_xp(base_xp + bonus_xp, "Game Victory" + (" vs AI (" + ai_difficulty + ")" if vs_ai else ""))
	progress_mission("first_victory")

func on_stones_captured(stone_count: int):
	"""Handle stone capture event"""
	var xp_per_stone = 5
	grant_xp(stone_count * xp_per_stone, "Captured " + str(stone_count) + " stones")
	progress_mission("capture_master", stone_count)

func on_extra_turn():
	"""Handle extra turn event"""
	grant_xp(10, "Extra turn")
	progress_mission("extra_turn_pro")

func on_fast_move(move_time: float):
	"""Handle fast move event"""
	if move_time < 5.0:
		progress_mission("speed_demon")

# DATA PERSISTENCE

func save_player_data():
	"""Save player progression data"""
	var data = get_player_stats()
	var file = FileAccess.open("user://player_data.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_player_data():
	"""Load player progression data"""
	var file = FileAccess.open("user://player_data.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			var data = json.get_data()
			player_xp = data.get("xp", 0)
			player_level = data.get("level", 1)
			player_traits = data.get("traits", [])
			
			# Load missions progress
			var saved_missions = data.get("missions", {})
			for mission_id in saved_missions:
				if missions.has(mission_id):
					missions[mission_id]["current"] = saved_missions[mission_id].get("current", 0)
					missions[mission_id]["completed"] = saved_missions[mission_id].get("completed", false)

func unlock_trait(trait_id: String):
	"""Unlock a trait for the player"""
	# Implementation for trait system
	pass

func check_trait_unlocks():
	"""Check if any traits should be unlocked based on progress"""
	# Implementation for trait checking
	pass

func _exit_tree():
	"""Save data when exiting"""
	save_player_data()
