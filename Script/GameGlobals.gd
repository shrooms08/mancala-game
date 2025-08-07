extends Node

#Game mode enum
enum GameMode {PVP, PVE}

#Global game settings
var game_mode: GameMode = GameMode.PVP
var ai_difficulty: String = "Medium"

#AI difficulty options
var ai_difficulties = ["Easy", "Medium", "Hard"]

func is_ai_game() -> bool:
	return game_mode == GameMode.PVE
	
func is_pvp_game() -> bool:
	return game_mode == GameMode.PVP
