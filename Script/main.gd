extends Node2D

var pits = [4,4,4,4,4,4,0,4,4,4,4,4,4,0] #initial stones
var player_turn = 0 #0 = player 1, 1 = player 2
var game_over = false
var is_animating = false #Prevent clicks durin animation
var StoneScene = preload("res://scene/Stone.tscn")

#UI References - will be set in_ready()
var turn_label: Label
var player1_score_label: Label
var player2_score_label: Label
var status_label: Label
var restart_button: Button
var game_ui: Control

signal game_ended(winner)

func _ready():
	randomize()
	print("Game starting...")
	setup_game_ui()
	debug_node_structure()
	connect_touchscreen_signals()
	update_board_display()
	update_game_ui()
	
	#Enable global touch detection for debugging
	print("=== Setting up global touch detection ===")
	
	
func setup_game_ui():
	#Create the main UI container
	game_ui = Control.new()
	game_ui.name = "GameUI"
	game_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(game_ui)
	
	#Turn indicator
	turn_label = Label.new()
	turn_label.text = "Player 1's Turn"
	turn_label.add_theme_font_size_override("font_size", 24)
	turn_label.add_theme_color_override("font color", Color.WHITE)
	turn_label.position = Vector2(50,20)
	game_ui.add_child(turn_label)
	
	#Player 1 Score (bottom left)
	var player1_container = VBoxContainer.new()
	player1_container.position = Vector2(50,100)
	game_ui.add_child(player1_container)
	
	var player1_title = Label.new()
	player1_title.text = "Player 1"
	player1_title.add_theme_font_size_override("font_size", 18)
	player1_title.add_theme_color_override("font_color", Color.CYAN)
	player1_container.add_child(player1_title)
	
	player1_score_label = Label.new()
	player1_score_label.text = "Score: 0"
	player1_score_label.add_theme_font_size_override("font_size", 16)
	player1_score_label.add_theme_color_override("font_color", Color.WHITE)
	player1_container.add_child(player1_score_label)
	
	#Player 2 Score (top right)
	var player2_container = VBoxContainer.new()
	player2_container.position = Vector2(650,50)
	game_ui.add_child(player2_container)
	
	var player2_title = Label.new()
	player2_title.text = "Player 2"
	player2_title.add_theme_font_size_override("font_size", 18)
	player2_title.add_theme_color_override("font_color", Color.ORANGE)
	player2_container.add_child(player2_title)
	
	player2_score_label = Label.new()
	player2_score_label.text = "Score: 0"
	player2_score_label.add_theme_font_size_override("font_size", 16)
	player2_score_label.add_theme_color_override("font_color", Color.WHITE)
	player2_container.add_child(player1_score_label)
	
	#Status message (center)
	status_label = Label.new()
	status_label.text = "Make your move!"
	status_label.add_theme_font_size_override("font_size", 20)
	status_label.add_theme_color_override("font_color", Color.YELLOW)
	status_label.position = Vector2(300,250)
	game_ui.add_child(status_label)
	
	#Restart button
	restart_button = Button.new()
	restart_button.text = "New Game"
	restart_button.position = Vector2(350, 20)
	restart_button.size = Vector2(100, 40)
	restart_button.pressed.connect(_on_restart_button_pressed)
	game_ui.add_child(restart_button)
	
func update_game_ui():
	if not turn_label:
		return
	
	#Update turn indicator
	if game_over:
		turn_label.text + "Game Over"
		turn_label.add_theme_color_override("font color", Color.RED)
		
	else:
		if player_turn == 0:
			turn_label.text = "Player 1's Turn"
			turn_label.add_theme_color_override("font_color", Color.CYAN)
		else:
			turn_label.text = "Player 2's Turn"
			turn_label.add_theme_color_override("font_color", Color.ORANGE)
			
	#Update scores
	player1_score_label.text = "Score: " + str(pits[6])
	player2_score_label.text = "Score: " + str(pits[13])
	
	#Clear status after a delay (unless it's game over)
	if not game_over and status_label.text != "Make your move!":
		var status_tween = create_tween()
		status_tween.tween_delay(2.0)
		status_tween.tween_callback(func(): status_label.text = "Make your move")
		
		
func show_status_message(message: String, color: Color = Color.YELLOW):
	if status_label:
		status_label.text = message
		status_label.add_theme_color_override("font_color", color)
		
func _on_restart_button_pressed():
	restart_game()
	
#Global touch detection - this will catch ALL touches on the screen
func _input(event): 
	if event is InputEventScreenTouch:
		if event.pressed:
			print("GLOBAL TOUCH DETECTED at position: ", event.position)
		else:
			print("GLOBAL TOUCH RELEASED at position: ", event.position)
			
	elif event is InputEventScreenDrag:
		print("GLOBAL DRAG at position:", event.position)
		
#Alternative: Use _unhandled_input to catch touches that weren't handled by UI
func _unhandled_input(event):
	if event is InputEventScreenTouch:
		print("UNHANDLED TOUCH at position: ", event.position)
		
		
func debug_node_structure():
	print("=== Debugging Node Structure ===")
	var pit_nodes = $PitNodes
	print ("PitNodes found: ", pit_nodes != null)
	
	if pit_nodes:
		print("PitNodes children count: ", pit_nodes.get_child_count())
		for child in pit_nodes.get_children():
			print("Child name: ", child.name, "-Type: ", child.get_class())
			
	#Try to access each pit individually
	for i in range(14):
		if i == 6 or i == 13:
			continue
		var pit_name = "Pit" + str(i)
		if pit_nodes and pit_nodes.has_node(pit_name):
			var pit_node = pit_nodes.get_node(pit_name)
			print("Pit ", i, "found - Type: ", pit_node.get_class())
			
			#Check if it has the required child nodes
			if pit_node.has_node("CountLabel"):
				print("- CountLabel: Found")
			else:
				print(" -CountLabel: MISSING")
				
			if pit_node.has_node("StoneContainer"):
				print(" -StoneContainer: Found")
			else:
				print(" -StoneContainer: MISSING")
		else:
			print("Pit", i, "NOT FOUND")
			
func connect_touchscreen_signals():
	print("=== Connecting TouchScreen Signals ===")
	#Connect TouchScreenButton signals dynamically
	for i in range(14):
		if i == 6 or i == 13: #Skip stores
			continue
		var pit_name = "Pit" + str(i)
		print("Looking for: ", pit_name)
		
		if not $PitNodes.has_node(pit_name):
			print("ERROR: Node", pit_name, "not found!")
			continue
			
		var pit_node = $PitNodes.get_node(pit_name)
		print("Found Pit", i, "-Type: ", pit_node.get_class())
		print(" Position: ", pit_node.global_position)
		print(" Size: ", pit_node.size if pit_node.has_method("get_size") else "No size property")
		
		
		if pit_node is TouchScreenButton:
			print(" TouchScreenButton properties:")
			print("  -Visible: ", pit_node.visible)
			print("  -Modulate: ", pit_node.modulate)
			print("  -Process Mode: ", pit_node.process_mode)
			
			#Check for  CollisionShape2D
			var collision_shape = null
			for child in pit_node.get_children():
				if child is CollisionShape2D:
					collision_shape = child
					break
					
			if collision_shape:
				print(" -CollisionShape2D found: ", collision_shape.shape != null)
				if collision_shape.shape:
					print("   Shape type: ", collision_shape.shape.get_class())
			else:
				print(   "- No CollisionShape2D found!")
			
			#Check if signal exists and connect 
			if pit_node.has_signal("pressed"):
				pit_node.pressed.connect(_on_pit_pressed.bind(i))
				print("Connected released signal for pit", i)
			else:
				print("x Pit", i, "doesn't have 'pressed' signal")
		else:
			print("x Pit", i, "is not TouchScreenButton, it's: ", pit_node.get_class())
		
		#Try other connection methods based on node type
		if pit_node.has_signal("gui_input"):
			pit_node.gui_input.connect(_on_pit_gui_input.bind(i))
			print ("Connected Pit", i, "via gui_input")
		elif pit_node.has_signal("input_event"):
			pit_node.input_event.connect(_on_pit_input_event.bind(i))
			print("Connected Pit", i, "via input_event")
		elif pit_node.has_signal("pressed"):
			pit_node.pressed.connect(_on_pit_pressed.bind(i))
			print("Connected Pit", i, "via pressed signal")
			
func _on_pit_pressed(index):
	print("TouchScreen pit PRESSED: ", index)
	handle_pit_click(index)
	
func _on_pit_released(index):
	print("TouchScreen pit RELEASED: ", index)
	
func _on_pit_gui_input(event, index):
	print("GUI input received for pit: ", index, " -Event: ", event.get_class())
	if event is InputEventScreenTouch:
		if event.pressed:
			print("GUI input pit TOUCHED: ", index)
			handle_pit_click(index)
		else:
			print("GUI input pit RELEASED: ", index)
			
func _on_pit_input_event(viewport, event, shape_idx, pit_index):
	print("Input event received for pit ", pit_index, " -Event: ", event.get_class())
	if event is InputEventScreenTouch and event.pressed:
		print("Input event pit TOUCHED: ", pit_index)
		handle_pit_click(pit_index)
	
	
func connect_pit_signals():
	#Connect all pit signals dynamically instead of individual function
	for i in range (14):
		if i == 6 or i ==13: # Skip stores
			continue
		var pit_node = $PitNodes.get_node("Pit" + str(i))
		if pit_node.has_signal("pressed"):
			pit_node.pressed.connect(_on_pit_pressed.bind(i))
		elif pit_node.has_signal("button_pressed"):
			pit_node.button_pressed.connect(_on_pit_pressed.bind(i))
		elif pit_node.has_signal("input_event"):
			pit_node.input_event.connect(_on_pit_pressed.bind(i))
		else:
			print("Warning: Could not connect signal for Pit", i)
		
		

	
func clear_children(node):
	for child in node.get_children():
		child.queue_free()
		
func update_board_display():
	for i in range(pits.size()):
		var pit_node = $PitNodes.get_node("Pit" + str(i))
		var label = pit_node.get_node("CountLabel")
		label.text = str(pits[i])
		var container = pit_node.get_node("StoneContainer")
		clear_children(container)
		
		for j in range(pits[i]):
			var stone = StoneScene.instantiate()
			stone.position = Vector2(randf_range(0,30), randf_range(0,30))
			container.add_child(stone)
			
			
	
func handle_pit_click(index):
	print("Handle pit click called for index: ", index)
	if game_over:
		print("Game is over, ignoring click")
		return
		
	# Don't allow clicking opponent's pit or empty pit
	if pits[index] == 0:
		print("Pit is empty, ignoring click")
		return
	if (player_turn == 0 and index > 5) or (player_turn == 1 and index < 7):
		print("Not player's turn or wrong pit, ignoring click")
		return
		
	print("Processing move for player ", player_turn, " on pit ", index)
	
	#Start the animated stpone distribution
	animate_stone_distribution(index)
	
func animate_stone_distribution(start_index):
	is_animating = true
	
	var stones_to_move = pits[start_index]
	pits[start_index] = 0
	var current_index = start_index
	
	#Create an array to track the movement sequence
	var movement_sequence = []
	var temp_stones = stones_to_move
	var temp_current = current_index
	
	#Calculate the full movement path
	while temp_stones > 0:
		temp_current = (temp_current + 1) % 14
		
		#Skip opponent's store
		if (player_turn == 0 and temp_current == 13) or (player_turn == 1 and temp_current == 6):
			continue
		
		movement_sequence.append(temp_current)
		temp_stones -= 1
		
	print("Movement sequence: ", movement_sequence)
	
	#Update display to show empty starting pit
	update_board_display()
	
	#reate all animated stones at once
	var animated_stones = []
	for i in range(stones_to_move):
		var stone = StoneScene.instantiate()
		add_child(stone)
		stone.global_position = get_pit_center_position(start_index)
		animated_stones.append(stone)
		
	#Animate all stones to their destinations simultaneously
	animate_all_stones_together(animated_stones, movement_sequence, start_index)
	
	
func animate_all_stones_together(stones, sequence, start_index):
	var delay_between_arrivals = 0.2 #Time between each stone arriving
	
	for i in range(stones.size()):
		var stone = stones[i]
		var target_pit = sequence[i]
		var arrival_delay = i * delay_between_arrivals
		
		#Calculate the path for their stone
		var start_pos = get_pit_center_position(start_index)
		var end_pos = get_pit_center_position(target_pit)
		
		#Create tween for this stone
		var tween = create_tween()
		
		#Add delay before this stone starts moving
		if arrival_delay > 0:
			tween.tween_interval(arrival_delay)
			
		#Animate stone to destination
		var flight_duration = 0.4
		tween.tween_property(stone, "global_position", end_pos, flight_duration)
		
		#When stone arrives, add it to the pit
		tween.tween_callback(_on_individual_stone_arrival.bind(stone, target_pit, i, stones.size()))
		
func _on_individual_stone_arrival(stone, target_pit, stone_index, total_stones):
	#Remove the animated stones
	stone.queue_free()
	
	#Add stone to the target pit
	pits[target_pit] += 1
	update_single_pit_display(target_pit)
	
	print("Stone", stone_index + 1, "arrived at pit", target_pit)
	
	#If this is the last stone, complete the move
	if stone_index == total_stones - 1:
		var final_pit = target_pit
		print("All stones have arrived. Final pit: ", final_pit)
		
		#Small delay before completing move for visual clarity
		var completion_tween = create_tween()
		completion_tween.tween_interval(0.3)
		completion_tween.tween_callback(complete_move.bind(final_pit))
		
		
func get_original_pit_from_sequence(sequence):
	# Calculate original pit from sequence
	var first_target = sequence[0]
	var original = (first_target - 1) % 14
	if original < 0:
		original = 13
		
	#Handle store skipping logic
	while (player_turn == 0 and original == 13) or (player_turn == 1 and original == 6):
		original = (original - 1) % 14
		if original < 0:
			original = 13
	return original
	
func get_pit_center_position(pit_index):
	var pit_node = $PitNodes.get_node("Pit" + str(pit_index))
	
	#Get the center position differently based on node type
	if pit_node is TouchScreenButton:
		#TouchScreenButton doesn't have size property, use shape instead
		var collision_shape = null
		for child in pit_node.get_children():
			if child is CollisionShape2D:
				collision_shape = child
				break
				
		if collision_shape and collision_shape.shape:
			if collision_shape.shape is RectangleShape2D:
				var rect_shape = collision_shape.shape as RectangleShape2D
				return pit_node.global_position + Vector2(rect_shape.size.x / 2, rect_shape.size.y / 2)
			elif collision_shape.shape is CircleShape2D:
				var circle_shape = collision_shape.shape as CircleShape2D
				return pit_node.global_position + Vector2(circle_shape.radius, circle_shape.radius)
			elif collision_shape.shape is CapsuleShape2D:
				var capsule_shape = collision_shape.shape as CapsuleShape2D
				return pit_node.global_position + Vector2(capsule_shape.radius, capsule_shape.height / 2)
				
		#Fallback: Use estimated center
		return pit_node.global_position + Vector2(50,50)
	else:
		#For other node types that have size property
		if pit_node.has_method("get_size"):
			var node_size = pit_node.get_size()
			return pit_node.global_position + Vector2(node_size.x / 2, node_size.y / 2)
		else:
			#Fallback for nodes without size
			return pit_node.global_position + Vector2(50,50)
			
			
func update_single_pit_display(pit_index):
	var pit_node = $PitNodes.get_node("Pit" + str(pit_index))
	var label = pit_node.get_node("CountLabel")
	label.text = str(pits[pit_index])
	
	var container = pit_node.get_node("StoneContainer")
	clear_children(container)
	
	#Add stones to display
	if pit_index == 6 or pit_index == 13:
		#Store arrangement
		for j in range(pits[pit_index]):
			var stone = StoneScene.instantiate()
			var stones_per_row = 2
			var row = j / stones_per_row
			var col = j % stones_per_row
			stone.position = Vector2(col * 25 + randf_range(-3,3), row * 25 + randf_range(-3,3))
			container.add_child(stone)
	else:
		#Regular pit arrangement
		for j in range(pits[pit_index]):
			var stone = StoneScene.instantiate()
			stone.position = Vector2(randf_range(0,30), randf_range(0,30))
			container.add_child(stone)
			
func complete_move(final_index):
	print ("Move completed. Final position: pit ", final_index)
	
	#Check for capture
	check_capture(final_index)
	
	#Check if player gets another turn
	var player_store = 6 if player_turn == 0 else 13
	if final_index != player_store:
		player_turn = 1 - player_turn
		print("Switching to player ", player_turn)
	else:
		print("Player ", player_turn, "gets another turn!")
	
	#Check win condition
	check_game_over()
	
	#Update full board display
	update_board_display()
	
	#Re-enable input
	is_animating = false
	
	
func check_capture(last_index):
	#Only capture if last stone landed in player's empty pit (not store)
	var player_store = 6 if player_turn == 0 else 13
	if last_index == player_store:
		return #Landed in store, no capture
		
	#Check if it's player's side and was empty before the stone was placed
	var is_player_side = (player_turn == 0 and last_index < 6) or (player_turn == 1 and last_index > 6 and last_index < 13)
	if not is_player_side or pits[last_index] != 1:
		return #Not player's side or pit wasn't empty
		
	#Calculate opposite pit
	var opposite_index = 12 - last_index
	if pits[opposite_index] == 0:
		return #No stones to capture
		
	#Perform capture
	var captured_stones = pits[opposite_index] + pits[last_index]
	pits[opposite_index] = 0
	pits[last_index] = 0
	pits[player_store] += captured_stones
	
	print("Player", player_turn + 1, "captured", captured_stones, "stones!")
	
func check_game_over():
	#Check if player 1's side is empty (pits 0-5
	var player1_empty = true
	for i in range(6):
		if pits[i] > 0:
			player1_empty = false
			break
			
	#Check if player 2's side is empty (pits 7-12)
	var player2_empty = true
	for i in range(7,13):
		if pits[i] > 0:
			player2_empty = false
			break
			
	if player1_empty or player2_empty:
		end_game()
		
func end_game():
	game_over = true
	
	#Move remaining stones to respective stores
	for i in range(6):
		if pits[i] > 0:
			pits[6] += pits[i]
			pits[i] = 0
			
	for i in range(7,13):
		if pits[i] > 0:
			pits[13] += pits[i]
			pits[i] = 0
			
	#Determine winner
	var winner = -1 #-1 = tie
	if pits[6] > pits[13]:
		winner = 0 #player 1 wins
	elif pits[13] > pits[6]:
		winner = 1 #Player 2 wins
		
	print("Game Over!")
	print("Player 1 score: ", pits[6])
	print("Player 2 score: ", pits[13])
	if winner == -1:
		print("It's a tie")
	else:
		print("Player ", winner + 1, "wins!")
	
	game_ended.emit(winner)
	
func restart_game():
	pits = [4,4,4,4,4,4,0,4,4,4,4,4,4,0]
	player_turn = 0
	game_over = false
	update_board_display()
	
	# Individual pit functions (temporary - connect these in the editor)
func _on_pit_0_pressed():
	handle_pit_click(0)


func _on_pit_1_pressed():
	handle_pit_click(1)


func _on_pit_2_pressed():
	handle_pit_click(2)


func _on_pit_3_pressed():
	handle_pit_click(3)


func _on_pit_4_pressed():
	handle_pit_click(4)


func _on_pit_5_pressed():
	handle_pit_click(5)


func _on_pit_7_pressed():
	handle_pit_click(7)


func _on_pit_8_pressed():
	handle_pit_click(8)


func _on_pit_9_pressed():
	handle_pit_click(9)


func _on_pit_10_pressed():
	handle_pit_click(10)


func _on_pit_11_pressed():
	handle_pit_click(11)
	
func _on_pit_12_pressed():
	handle_pit_click(12)
