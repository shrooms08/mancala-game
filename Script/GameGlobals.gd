# GameGlobals.gd - Global game state and configuration
extends Node

# Game mode enumeration
enum GameMode { PVP, PVE }

# Current game state
var game_mode: GameMode = GameMode.PVP
var ai_difficulty: String = "Medium"

# Wallet and blockchain integration
var current_wallet_address: String = ""
var current_wallet_private_key: String = ""
var is_blockchain_connected: bool = false

# Backend connection status
var backend_connected: bool = false

func is_ai_game() -> bool:
	return game_mode == GameMode.PVE

func set_game_mode(mode: GameMode):
	game_mode = mode

func set_ai_difficulty(difficulty: String):
	ai_difficulty = difficulty

func set_wallet_info(address: String, private_key: String):
	current_wallet_address = address
	current_wallet_private_key = private_key

func is_wallet_connected() -> bool:
	return current_wallet_address != ""

func get_wallet_address() -> String:
	return current_wallet_address

func get_wallet_private_key() -> String:
	return current_wallet_private_key
