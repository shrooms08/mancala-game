# GameProgressTracker.gd - Comprehensive game progress tracking and backend integration
extends Node

# Backend configuration
var backend_url: String = "http://localhost:8080"
var current_user_pubkey: String = ""
var current_game_id: String = ""
var is_backend_connected: bool = false

# Game tracking variables
var game_start_time: Dictionary = {}
var game_stats: Dictionary = {
  "stones_captured": 0,
  "extra_turns": 0,
  "fast_moves": 0,
  "play_time": 0,
  "total_moves": 0,
  "last_move_time": {}
}

# HTTP client for backend communication
var http_client: HTTPRequest

# Signals for UI updates
signal progress_updated(progress_type, data)
signal backend_connected()
signal backend_error(message)
signal xp_gained(amount, reason)
signal level_up(new_level)
signal mission_completed(mission_id, reward_xp)

func _ready():
  print("GameProgressTracker initialized")
  http_client = HTTPRequest.new()
  add_child(http_client)
  http_client.request_completed.connect(_on_http_request_completed)
  
  # Try to connect to backend
  connect_to_backend()

func connect_to_backend():
  """Connect to the Node.js backend server"""
  print("Connecting to backend at: ", backend_url)
  
  # Test backend connection with health check
  var headers = ["Content-Type: application/json"]
  var url = backend_url + "/health"
  
  var error = http_client.request(url, headers, HTTPClient.METHOD_GET)
  if error != OK:
    print("ERROR: Failed to send health check request")
    backend_error.emit("Failed to connect to backend")
    return
  
  print("Health check request sent to backend")

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
  elif response_code == 0:
    # Connection failed
    print("Connection failed, backend may be offline")
    backend_error.emit("Backend connection failed")
  else:
    print("ERROR: Backend request failed with code: ", response_code)
    backend_error.emit("Backend request failed: " + str(response_code))

func handle_backend_response(data: Dictionary):
  """Process successful responses from backend"""
  if data.has("ok") and data.ok:
    if data.has("bootstrapped") and data.bootstrapped:
      is_backend_connected = true
      backend_connected.emit()
      print("✅ Backend connected successfully!")
  else:
    print("Backend response indicates error: ", data)

# USER MANAGEMENT

func create_or_get_user(wallet_address: String, username: String = "", display_name: String = "") -> bool:
	"""Create a new user or get existing user from backend"""
	if not is_backend_connected:
		print("Backend not connected, cannot create user")
		return false
	
	current_user_pubkey = wallet_address
	
	var user_data = {
		"userPubkey": wallet_address,
		"username": username,
		"displayName": display_name
	}
	
	var headers = ["Content-Type: application/json"]
	var url = backend_url + "/users"
	
	var json_string = JSON.stringify(user_data)
	var error = http_client.request(url, headers, HTTPClient.METHOD_POST, json_string)
	
	if error != OK:
		print("ERROR: Failed to send user creation request")
		return false
	
	print("User creation request sent to backend")
	return true

func create_new_user() -> String:
	"""Create a new user with automatic wallet generation"""
	if not is_backend_connected:
		print("Backend not connected, cannot create new user")
		return ""
	
	# Generate a unique user ID (simulating wallet generation)
	var timestamp = Time.get_unix_time_from_system()
	var random_suffix = str(randi() % 10000).pad_zeros(4)
	var new_user_pubkey = "user_" + str(timestamp) + "_" + random_suffix
	
	print("Creating new user with pubkey: ", new_user_pubkey)
	
	# Create user with default values
	var user_data = {
		"userPubkey": new_user_pubkey,
		"username": "Player" + random_suffix,
		"displayName": "Player " + random_suffix
	}
	
	var headers = ["Content-Type: application/json"]
	var url = backend_url + "/users"
	
	var json_string = JSON.stringify(user_data)
	var error = http_client.request(url, headers, HTTPClient.METHOD_POST, json_string)
	
	if error != OK:
		print("ERROR: Failed to send new user creation request")
		return ""
	
	# Set as current user
	current_user_pubkey = new_user_pubkey
	print("New user created successfully: ", new_user_pubkey)
	
	return new_user_pubkey

# GAME PROGRESS TRACKING

func start_new_game(game_mode: String, ai_difficulty: String = ""):
  """Start tracking a new game"""
  current_game_id = "game_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())
  game_start_time = Time.get_time_dict_from_system()
  
  # Reset game stats
  game_stats = {
    "stones_captured": 0,
    "extra_turns": 0,
    "fast_moves": 0,
    "play_time": 0,
    "total_moves": 0,
    "last_move_time": {}
  }
  
  print("New game started: ", current_game_id, " (", game_mode, ")")
  
  # Update user preferences if available
  if current_user_pubkey != "" and is_backend_connected:
    update_user_preferences(game_mode, ai_difficulty)

func end_game(result: String, final_stats: Dictionary):
  """End the current game and submit results to backend"""
  if current_game_id == "":
    print("No active game to end")
    return
  
  # Calculate final play time
  var current_time = Time.get_time_dict_from_system()
  var play_time = calculate_time_difference(game_start_time, current_time)
  
  # Prepare game result data
  var game_result = {
    "userPubkey": current_user_pubkey,
    "gameId": current_game_id,
    "result": result,
    "gameMode": "PVE" if GameGlobals.game_mode == GameGlobals.GameMode.PVE else "PVP",
    "aiDifficulty": GameGlobals.ai_difficulty if GameGlobals.is_ai_game() else "",
    "stats": {
      "stonesCaptured": final_stats.get("stones_captured", 0),
      "extraTurns": final_stats.get("extra_turns", 0),
      "fastMoves": final_stats.get("fast_moves", 0),
      "playTime": play_time,
      "totalMoves": final_stats.get("total_moves", 0)
    },
    "timestamp": Time.get_datetime_string_from_system()
  }
  
  # Submit to backend
  if is_backend_connected and current_user_pubkey != "":
    submit_game_result(game_result)
  
  # Reset game tracking
  current_game_id = ""
  game_start_time = {}
  game_stats = {}
  
  print("Game ended: ", result, " - Stats submitted to backend")

func record_stone_capture(captured_stones: int):
  """Record stone capture for mission progress"""
  game_stats.stones_captured += captured_stones
  
  # Update mission progress
  if is_backend_connected and current_user_pubkey != "":
    update_mission_progress("captureMaster", captured_stones)
  
  print("Stones captured: ", captured_stones, " (Total: ", game_stats.stones_captured, ")")

func record_extra_turn():
  """Record extra turn for mission progress"""
  game_stats.extra_turns += 1
  
  # Update mission progress
  if is_backend_connected and current_user_pubkey != "":
    update_mission_progress("extraTurnPro", 1)
  
  print("Extra turn recorded: ", game_stats.extra_turns)

func record_fast_move(move_time: float):
  """Record fast move for mission progress"""
  if move_time < 5.0:  # Fast move threshold
    game_stats.fast_moves += 1
    
    # Update mission progress
    if is_backend_connected and current_user_pubkey != "":
      update_mission_progress("speedDemon", 1)
    
    print("Fast move recorded: ", game_stats.fast_moves, " (Time: ", move_time, "s)")

func record_game_victory(vs_ai: bool, ai_difficulty: String = ""):
  """Record game victory and grant XP"""
  # Grant victory XP
  var base_xp = 100
  var bonus_xp = 0
  
  if vs_ai:
    match ai_difficulty:
      "Easy": bonus_xp = 10
      "Medium": bonus_xp = 25
      "Hard": bonus_xp = 50
    
    # Update AI slayer mission
    if is_backend_connected and current_user_pubkey != "":
      update_mission_progress("aiSlayer", 1)
  
  # Update first victory mission
  if is_backend_connected and current_user_pubkey != "":
    update_mission_progress("firstVictory", 1)
  
  # Grant XP
  if is_backend_connected and current_user_pubkey != "":
    grant_xp(base_xp + bonus_xp, "Game Victory" + (" vs AI (" + ai_difficulty + ")" if vs_ai else ""))
  
  print("Game victory recorded: +", base_xp + bonus_xp, " XP")

func record_move():
  """Record a move for statistics"""
  game_stats.total_moves += 1
  game_stats.last_move_time = Time.get_time_dict_from_system()

# BACKEND API CALLS

func submit_game_result(game_result: Dictionary):
  """Submit game result to backend"""
  var headers = ["Content-Type: application/json"]
  var url = backend_url + "/game/game-result"
  
  var json_string = JSON.stringify(game_result)
  var error = http_client.request(url, headers, HTTPClient.METHOD_POST, json_string)
  
  if error != OK:
    print("ERROR: Failed to submit game result")
  else:
    print("Game result submitted to backend")

func grant_xp(amount: int, reason: String):
  """Grant XP to user via backend"""
  var xp_data = {
    "userPubkey": current_user_pubkey,
    "amount": amount,
    "reason": reason,
    "gameId": current_game_id,
    "timestamp": Time.get_datetime_string_from_system()
  }
  
  var headers = ["Content-Type: application/json"]
  var url = backend_url + "/game/grant-xp"
  
  var json_string = JSON.stringify(xp_data)
  var error = http_client.request(url, headers, HTTPClient.METHOD_POST, json_string)
  
  if error != OK:
    print("ERROR: Failed to send XP grant request")
  else:
    print("XP grant request sent: +", amount, " XP for ", reason)
    xp_gained.emit(amount, reason)

func update_mission_progress(mission_id: String, progress: int):
  """Update mission progress via backend"""
  var mission_data = {
    "userPubkey": current_user_pubkey,
    "missionId": mission_id,
    "progress": progress,
    "gameId": current_game_id,
    "timestamp": Time.get_datetime_string_from_system()
  }
  
  var headers = ["Content-Type: application/json"]
  var url = backend_url + "/game/mission-progress"
  
  var json_string = JSON.stringify(mission_data)
  var error = http_client.request(url, headers, HTTPClient.METHOD_POST, json_string)
  
  if error != OK:
    print("ERROR: Failed to send mission progress update")
  else:
    print("Mission progress updated: ", mission_id, " +", progress)

func update_user_preferences(game_mode: String, ai_difficulty: String):
  """Update user game preferences"""
  var update_data = {
    "gameMode": game_mode,
    "aiDifficulty": ai_difficulty
  }
  
  var headers = ["Content-Type: application/json"]
  var url = backend_url + "/users/" + current_user_pubkey
  
  var json_string = JSON.stringify(update_data)
  var error = http_client.request(url, headers, HTTPClient.METHOD_PUT, json_string)
  
  if error != OK:
    print("ERROR: Failed to update user preferences")
  else:
    print("User preferences updated")

func get_user_stats() -> Dictionary:
  """Get current user statistics from backend"""
  if not is_backend_connected or current_user_pubkey == "":
    return {}
  
  var url = backend_url + "/game/stats/" + current_user_pubkey
  var error = http_client.request(url, [], HTTPClient.METHOD_GET)
  
  if error != OK:
    print("ERROR: Failed to get user stats")
    return {}
  
  print("User stats request sent")
  return {}

# UTILITY FUNCTIONS

func calculate_time_difference(start_time: Dictionary, end_time: Dictionary) -> float:
  """Calculate time difference in seconds between two time dictionaries"""
  if start_time.is_empty():
    return 0.0
  
  var start_seconds = start_time.hour * 3600 + start_time.minute * 60 + start_time.second
  var end_seconds = end_time.hour * 3600 + end_time.minute * 60 + end_time.second
  
  return float(end_seconds - start_seconds)

func get_current_game_stats() -> Dictionary:
  """Get current game statistics"""
  return game_stats.duplicate()

func is_user_connected() -> bool:
  """Check if user is connected and authenticated"""
  return current_user_pubkey != "" and is_backend_connected

func get_user_pubkey() -> String:
  """Get current user's public key"""
  return current_user_pubkey

func get_game_id() -> String:
  """Get current game ID"""
  return current_game_id
