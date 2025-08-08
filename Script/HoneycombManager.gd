# HoneycombManager.gd - Updated with proper Honeycomb SDK integration
extends Node

# Honeycomb Integration Manager for Mancala
# This handles all blockchain interactions via Honeycomb Protocol

# Honeycomb node reference (will be set from main scene)
var honeycomb_node: Node
var is_honeycomb_ready: bool = false

# Project and wallet data
var project_address: String = ""
var authority_keypair_path: String = "res://id.json"
var payer_address: String = ""
var is_connected: bool = false

# Player progression data
var player_xp: int = 0
var player_level: int = 1
var player_traits: Array = []
var active_missions: Dictionary = {}
var completed_missions: Array = []
var character_address: String = ""

# Mission definitions with proper structure for Honeycomb
var missions = {
	"first_victory": {
		"name": "First Victory",
		"description": "Win your first game",
		"target": 1,
		"current": 0,
		"reward_xp": 50,
		"completed": false,
		"mission_address": ""
	},
	"capture_master": {
		"name": "Capture Master", 
		"description": "Capture 10 stones total",
		"target": 10,
		"current": 0,
		"reward_xp": 100,
		"completed": false,
		"mission_address": ""
	},
	"extra_turn_pro": {
		"name": "Extra Turn Pro",
		"description": "Get 5 extra turns in games",
		"target": 5,
		"current": 0,
		"reward_xp": 75,
		"completed": false,
		"mission_address": ""
	},
	"ai_slayer": {
		"name": "AI Slayer",
		"description": "Beat Hard AI 3 times",
		"target": 3,
		"current": 0,
		"reward_xp": 200,
		"completed": false,
		"mission_address": ""
	},
	"speed_demon": {
		"name": "Speed Demon",
		"description": "Make 10 moves in under 5 seconds",
		"target": 10,
		"current": 0,
		"reward_xp": 150,
		"completed": false,
		"mission_address": ""
	}
}

# Resource addresses
var xp_resource_address: String = ""
var character_model_address: String = ""

# Signals for UI updates
signal xp_gained(amount)
signal level_up(new_level)
signal mission_progress(mission_id, current, target)
signal mission_completed(mission_id, reward_xp)
signal trait_unlocked(trait_id)
signal honeycomb_connected()
signal honeycomb_error(message)

func _ready():
	print("Honeycomb Manager initialized")
	# Don't initialize here, wait for honeycomb node to be set

func set_honeycomb_node(node: Node):
	"""Set the Honeycomb node reference from the main scene"""
	honeycomb_node = node
	if honeycomb_node:
		print("Honeycomb node set, initializing...")
		await initialize_honeycomb()
	else:
		print("ERROR: Honeycomb node is null!")

func initialize_honeycomb():
	"""Initialize Honeycomb connection and setup project"""
	if not honeycomb_node:
		print("ERROR: Honeycomb node not set!")
		honeycomb_error.emit("Honeycomb node not available")
		return
	
	print("Initializing Honeycomb Protocol connection...")
	
	# Load the authority keypair from id.json
	if not load_authority_keypair():
		return
	
	# Check if we have an existing project or need to create one
	if project_address == "":
		await create_honeycomb_project()
	else:
		is_connected = true
		honeycomb_connected.emit()
	
	# Setup game resources and missions
	await setup_game_resources()
	load_player_data()

func load_authority_keypair() -> bool:
	"""Load the authority keypair from id.json file"""
	if not FileAccess.file_exists(authority_keypair_path):
		print("ERROR: Authority keypair file not found at: ", authority_keypair_path)
		honeycomb_error.emit("Keypair file not found")
		return false
	
	var file = FileAccess.open(authority_keypair_path, FileAccess.READ)
	if not file:
		print("ERROR: Could not open keypair file")
		honeycomb_error.emit("Could not read keypair file")
		return false
	
	var keypair_data = file.get_as_text()
	file.close()
	
	# Set the authority keypair in the honeycomb node
	honeycomb_node.set_authority_keypair_from_json(keypair_data)
	
	# Get the public key for payer address
	payer_address = honeycomb_node.get_authority_pubkey()
	print("Authority loaded with pubkey: ", payer_address)
	
	return true

func create_honeycomb_project():
	"""Create a new Honeycomb project for the Mancala game"""
	print("Creating Honeycomb project for Mancala...")
	
	if not honeycomb_node:
		honeycomb_error.emit("Honeycomb node not available")
		return
	
	# Create project using the Honeycomb SDK
	var project_name = "Mancala Blockchain Game"
	var project_description = "A strategic Mancala game with on-chain progression using Honeycomb Protocol"
	var project_tags = ["game", "mancala", "strategy", "progression"]
	var project_genre = "Game"
	
	# Call the Honeycomb SDK to create project
	var result = await honeycomb_node.create_project(
		project_name,
		project_description,
		project_tags,
		project_genre,
		false  # not compressed
	)
	
	if result.success:
		project_address = result.project_address
		print("Project created successfully: ", project_address)
		is_connected = true
		honeycomb_connected.emit()
		save_project_data()
	else:
		print("ERROR: Failed to create project: ", result.error)
		honeycomb_error.emit("Failed to create project: " + str(result.error))

func setup_game_resources():
	"""Setup XP resource, character model, and missions"""
	if not is_connected:
		return
	
	print("Setting up game resources...")
	
	# Create XP resource
	await create_xp_resource()
	
	# Create character model for players
	await create_character_model()
	
	# Setup missions
	await setup_missions()

func create_xp_resource():
	"""Create the XP resource for player progression"""
	print("Creating XP resource...")
	
	var resource_params = {
		"name": "Experience Points",
		"symbol": "XP",
		"uri": "",  # Could add metadata URI
		"decimals": 0
	}
	
	var result = await honeycomb_node.create_resource(
		project_address,
		resource_params
	)
	
	if result.success:
		xp_resource_address = result.resource_address
		print("XP resource created: ", xp_resource_address)
	else:
		print("ERROR: Failed to create XP resource: ", result.error)

func create_character_model():
	"""Create character model for player characters"""
	print("Creating character model...")
	
	var character_config = {
		"name": "Mancala Player",
		"symbol": "MPLAYER",
		"description": "A Mancala game player character",
		"uri": ""  # Could add character metadata URI
	}
	
	var result = await honeycomb_node.create_character_model(
		project_address,
		character_config
	)
	
	if result.success:
		character_model_address = result.character_model_address
		print("Character model created: ", character_model_address)
	else:
		print("ERROR: Failed to create character model: ", result.error)

func setup_missions():
	"""Create missions in the Honeycomb system"""
	print("Setting up missions...")
	
	for mission_id in missions:
		var mission_data = missions[mission_id]
		
		var mission_config = {
			"name": mission_data.name,
			"description": mission_data.description,
			"reward": {
				"resource_address": xp_resource_address,
				"amount": mission_data.reward_xp
			}
		}
		
		var result = await honeycomb_node.create_mission(
			project_address,
			mission_config
		)
		
		if result.success:
			missions[mission_id]["mission_address"] = result.mission_address
			print("Mission created: ", mission_data.name, " -> ", result.mission_address)
		else:
			print("ERROR: Failed to create mission ", mission_data.name, ": ", result.error)

func create_player_character(wallet_address: String = ""):
	"""Create a character for the current player"""
	if not is_connected:
		print("Not connected to Honeycomb")
		return null
	
	var player_wallet = wallet_address if wallet_address != "" else payer_address
	print("Creating player character for wallet: ", player_wallet)
	
	var character_data = {
		"wallet": player_wallet,
		"name": "Mancala Player",
		"attributes": {
			"level": 1,
			"xp": 0,
			"games_played": 0,
			"games_won": 0
		}
	}
	
	var result = await honeycomb_node.create_character(
		project_address,
		character_model_address,
		character_data
	)
	
	if result.success:
		character_address = result.character_address
		print("Character created: ", character_address)
		return result
	else:
		print("ERROR: Failed to create character: ", result.error)
		return null

func grant_xp(amount: int, reason: String):
	"""Grant XP to player both locally and on-chain"""
	print("Granting ", amount, " XP for: ", reason)
	
	var old_level = calculate_level(player_xp)
	player_xp += amount
	var new_level = calculate_level(player_xp)
	
	# Update XP on-chain if connected
	if is_connected and character_address != "":
		update_xp_on_chain(player_xp)
	
	xp_gained.emit(amount)
	
	if new_level > old_level:
		player_level = new_level
		level_up.emit(new_level)
		check_trait_unlocks()

func update_xp_on_chain(total_xp: int):
	"""Update player's XP resource on the blockchain"""
	if not is_connected or xp_resource_address == "" or character_address == "":
		return
	
	print("Updating XP on-chain: ", total_xp)
	
	var result = await honeycomb_node.mint_resource_to_character(
		character_address,
		xp_resource_address,
		total_xp
	)
	
	if result.success:
		print("XP updated on-chain successfully")
	else:
		print("ERROR: Failed to update XP on-chain: ", result.error)

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
		
		# Complete mission on-chain
		if is_connected and missions[mission_id]["mission_address"] != "":
			complete_mission_on_chain(mission_id)

func complete_mission_on_chain(mission_id: String):
	"""Mark mission as completed on the blockchain"""
	var mission_address = missions[mission_id]["mission_address"]
	if mission_address == "":
		return
	
	print("Completing mission on-chain: ", mission_id)
	
	var result = await honeycomb_node.participate_in_mission(
		character_address,
		mission_address
	)
	
	if result.success:
		print("Mission completed on-chain successfully")
	else:
		print("ERROR: Failed to complete mission on-chain: ", result.error)

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
		"project_address": project_address
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

func save_project_data():
	"""Save project and connection data"""
	var data = {
		"project_address": project_address,
		"character_address": character_address,
		"xp_resource_address": xp_resource_address,
		"character_model_address": character_model_address
	}
	
	var file = FileAccess.open("user://honeycomb_project.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_project_data():
	"""Load project and connection data"""
	var file = FileAccess.open("user://honeycomb_project.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			var data = json.get_data()
			project_address = data.get("project_address", "")
			character_address = data.get("character_address", "")
			xp_resource_address = data.get("xp_resource_address", "")
			character_model_address = data.get("character_model_address", "")

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
	save_project_data()
