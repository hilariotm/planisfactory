extends Node2D

signal layout_changed

@export var player_controller: Node

var pixels_per_meter: int = 16 

# Dynamic Building Variables
var current_building_data: BuildingData
var current_building_size_px: Vector2 
var preview_instance: Node2D 
var current_rotation: float = 0.0 # NEW: Tracks the 10-degree rotation

var placed_buildings: Array[Dictionary] = []

var valid_color: Color = Color(1.0, 1.0, 1.0, 0.5)      
var invalid_color: Color = Color(1.0, 0.2, 0.2, 0.6)    

# Chunk System
var active_chunks: Dictionary = { Vector2(0, 0): true }
var chunk_size_meters: float = 32.0

# Grid Colors
var color_8x8: Color = Color(1.0, 1.0, 1.0, 0.8) 
var color_4x4: Color = Color(0.7, 0.7, 0.7, 0.5) 
var color_1x1: Color = Color(0.4, 0.4, 0.4, 0.2) 

func set_active_building(new_data: BuildingData):
	current_building_data = new_data
	current_building_size_px = Vector2(new_data.size_meters.x, new_data.size_meters.y) * pixels_per_meter
	current_rotation = 0.0 # Reset rotation when selecting a new building
	
	if is_instance_valid(preview_instance):
		preview_instance.queue_free()
		
	if new_data.prefab:
		preview_instance = new_data.prefab.instantiate()
		preview_instance.modulate = valid_color
		preview_instance.z_index = 10
		add_child.call_deferred(preview_instance)

func _process(_delta):
	# Hide the preview if we aren't in build mode
	if player_controller.current_state != player_controller.State.BUILD:
		if is_instance_valid(preview_instance):
			preview_instance.visible = false
		return
		
	if is_instance_valid(preview_instance) and current_building_data:
		preview_instance.visible = true # Ensure it is visible
		var mouse_pos = get_global_mouse_position()
		
		# We no longer need to offset the position because our sprites are Centered!
		var snapped_pos = get_snapped_position(mouse_pos)
		
		preview_instance.position = snapped_pos
		preview_instance.rotation_degrees = current_rotation
		
		var proposed_polygon = get_building_polygon_meters(snapped_pos, current_building_size_px, current_rotation)
		var placement_info = evaluate_placement(proposed_polygon, current_building_data)
		
		if not placement_info["is_valid"]:
			preview_instance.modulate = invalid_color
		else:
			preview_instance.modulate = valid_color
			preview_instance.z_index = 10 + placement_info["elevation"]

func _unhandled_input(event):
	# DISMANTLE MODE LOGIC
	if player_controller.current_state == player_controller.State.DISMANTLE:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dismantle_building_at(get_global_mouse_position())
		return

	# BUILD MODE LOGIC
	if player_controller.current_state == player_controller.State.BUILD:
		# Handle Rotation via Keyboard (R and Shift+R)
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_R:
				if event.shift_pressed:
					current_rotation -= 10.0
				else:
					current_rotation += 10.0
			
				# Keep the angle mathematically clean between 0 and 360
				current_rotation = wrapf(current_rotation, 0.0, 360.0)

		# Handle Mouse Placement
		if current_building_data == null or not is_instance_valid(preview_instance):
			return

		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = get_global_mouse_position()
			var snapped_pos = get_snapped_position(mouse_pos)
		
			var proposed_polygon = get_building_polygon_meters(snapped_pos, current_building_size_px, current_rotation)
			
			# 1. Update the call to pass the current_building_data
			var placement_info = evaluate_placement(proposed_polygon, current_building_data)
		
			if not placement_info["is_valid"]:
				return
			
			# --- 2. NEW LIFTING LOGIC ---
			# Push all valid intersecting machines UP by the height of this new foundation
			for b in placement_info["buildings_to_lift"]:
				b["elevation"] += current_building_data.size_meters.z
				b["instance"].z_index = b["elevation"]
			# -------------------------
			
			var new_building = current_building_data.prefab.instantiate()
			new_building.position = snapped_pos
			new_building.rotation_degrees = current_rotation
			new_building.z_index = placement_info["elevation"]
			
			add_child(new_building)
			
			placed_buildings.append({
				"instance": new_building,
				"polygon": proposed_polygon,
				"data": current_building_data,
				"elevation": placement_info["elevation"]
			})
			
			layout_changed.emit() # Tell the UI a building was added!
			
			expand_grid_if_needed(snapped_pos.x / pixels_per_meter, snapped_pos.y / pixels_per_meter)

# --- NEW: Generates an angled mathematical polygon for precise overlap checking ---
func get_building_polygon_meters(center_pixel_pos: Vector2, size_pixels: Vector2, rot_degrees: float) -> PackedVector2Array:
	# We shrink the collision by a tiny 0.01m margin. 
	# This guarantees that buildings placed perfectly side-by-side do not trigger a false overlap!
	var half_size_m = ((size_pixels / pixels_per_meter) / 2.0) - Vector2(0.01, 0.01) 
	var center_m = center_pixel_pos / pixels_per_meter
	
	# FIX: Renamed from 'transform' to 'poly_transform' to prevent shadowing
	var poly_transform = Transform2D(deg_to_rad(rot_degrees), center_m)
	
	var corners = PackedVector2Array([
		Vector2(-half_size_m.x, -half_size_m.y), # Top Left
		Vector2(half_size_m.x, -half_size_m.y),  # Top Right
		Vector2(half_size_m.x, half_size_m.y),   # Bottom Right
		Vector2(-half_size_m.x, half_size_m.y)   # Bottom Left
	])
	
	var polygon = PackedVector2Array()
	for point in corners:
		# Make sure to update the variable name here too!
		polygon.append(poly_transform * point) 
		
	return polygon

# Evaluates if a spot is valid, calculates Z-level, and checks if machines need lifting
func evaluate_placement(proposed_polygon: PackedVector2Array, data: BuildingData) -> Dictionary:
	var result = {
		"is_valid": true,
		"elevation": 0,
		"buildings_to_lift": [] 
	}
	
	var intersected_buildings = []
	
	# PASS 1: Gather all intersections and determine our base elevation
	for building in placed_buildings:
		var intersection = Geometry2D.intersect_polygons(building["polygon"], proposed_polygon)
		
		if intersection.size() > 0: 
			intersected_buildings.append(building)
			
			if building["data"].category == BuildingData.Category.FOUNDATIONS:
				var foundation_top = building["elevation"] + building["data"].size_meters.z
				if result["elevation"] == 0:
					result["elevation"] = foundation_top
				elif result["elevation"] != foundation_top:
					# Placed over uneven foundations
					result["is_valid"] = false
					
	# If the foundations are already uneven, stop checking
	if not result["is_valid"]:
		return result
		
	# Calculate exactly how high the top of our new building will reach
	var proposed_top = result["elevation"] + data.size_meters.z
	
	# PASS 2: Check Machines now that we know our exact placement elevation
	for building in intersected_buildings:
		# Ignore foundations, we already processed them
		if building["data"].category != BuildingData.Category.FOUNDATIONS:
			
			# If we are holding a Foundation
			if data.category == BuildingData.Category.FOUNDATIONS:
				if building["elevation"] == result["elevation"]:
					# Machine is on the ground with us, flag it to be lifted!
					result["buildings_to_lift"].append(building)
				elif building["elevation"] >= proposed_top:
					# The machine is ALREADY lifted (sitting on an adjacent foundation).
					# We can safely slide underneath it without lifting it again!
					pass 
				else:
					# Machine is clipping into our placement space
					result["is_valid"] = false
					break
			
			# If we are holding a Machine
			else:
				var machine_top = building["elevation"] + building["data"].size_meters.z
				# Simple 3D bounding box check to ensure they don't clip vertically
				if result["elevation"] < machine_top and proposed_top > building["elevation"]:
					result["is_valid"] = false
					break
					
	return result

func get_chunk_coords(pos_x: float, pos_y: float) -> Vector2:
	var cx = floor((pos_x + 16.0) / chunk_size_meters)
	var cy = floor((pos_y + 16.0) / chunk_size_meters)
	return Vector2(cx, cy)

func expand_grid_if_needed(placed_x: float, placed_y: float):
	var chunk_coords = get_chunk_coords(placed_x, placed_y)
	if not active_chunks.has(chunk_coords):
		active_chunks[chunk_coords] = true
		queue_redraw()

func _draw():
	for chunk in active_chunks.keys():
		var start_x = int(chunk.x * chunk_size_meters) - 16
		var end_x = start_x + int(chunk_size_meters)
		var start_y = int(chunk.y * chunk_size_meters) - 16
		var end_y = start_y + int(chunk_size_meters)

		for x in range(start_x, end_x):
			var px = x * pixels_per_meter
			var start_point = Vector2(px, start_y * pixels_per_meter)
			var end_point = Vector2(px, end_y * pixels_per_meter)
			if x % 8 == 0: draw_line(start_point, end_point, color_8x8, 2.0)
			elif x % 4 == 0: draw_line(start_point, end_point, color_4x4, 1.0)
			else: draw_line(start_point, end_point, color_1x1, 1.0)

		for y in range(start_y, end_y):
			var py = y * pixels_per_meter
			var start_point = Vector2(start_x * pixels_per_meter, py)
			var end_point = Vector2(end_x * pixels_per_meter, py)
			if y % 8 == 0: draw_line(start_point, end_point, color_8x8, 2.0)
			elif y % 4 == 0: draw_line(start_point, end_point, color_4x4, 1.0)
			else: draw_line(start_point, end_point, color_1x1, 1.0)
		
		if not active_chunks.has(Vector2(chunk.x + 1, chunk.y)):
			var px = end_x * pixels_per_meter
			var start_point = Vector2(px, start_y * pixels_per_meter)
			var end_point = Vector2(px, end_y * pixels_per_meter)
			if end_x % 8 == 0: draw_line(start_point, end_point, color_8x8, 2.0)
			elif end_x % 4 == 0: draw_line(start_point, end_point, color_4x4, 1.0)
			else: draw_line(start_point, end_point, color_1x1, 1.0)

		if not active_chunks.has(Vector2(chunk.x, chunk.y + 1)):
			var py = end_y * pixels_per_meter
			var start_point = Vector2(start_x * pixels_per_meter, py)
			var end_point = Vector2(end_x * pixels_per_meter, py)
			if end_y % 8 == 0: draw_line(start_point, end_point, color_8x8, 2.0)
			elif end_y % 4 == 0: draw_line(start_point, end_point, color_4x4, 1.0)
			else: draw_line(start_point, end_point, color_1x1, 1.0)

func get_snapped_position(raw_position: Vector2) -> Vector2:
	var snapped_x = round(raw_position.x / pixels_per_meter) * pixels_per_meter
	var snapped_y = round(raw_position.y / pixels_per_meter) * pixels_per_meter
	return Vector2(snapped_x, snapped_y)
	
func dismantle_building_at(mouse_pos: Vector2):
	# Convert mouse pixel position to meters for the polygon check
	var mouse_m = mouse_pos / pixels_per_meter
	
	# Loop backwards through the array to ensure we delete the TOP-MOST building first!
	for i in range(placed_buildings.size() - 1, -1, -1):
		var building = placed_buildings[i]
		
		if Geometry2D.is_point_in_polygon(mouse_m, building["polygon"]):
			# Destroy the visual node in the game world
			building["instance"].queue_free()
			
			# Remove the data from our tracking array
			placed_buildings.remove_at(i)
			
			layout_changed.emit() # Tell the UI a building was removed!
			
			break # Only delete one building per click
			
# Sums up all required materials for every building on the grid
func calculate_total_materials() -> Dictionary:
	var totals: Dictionary = {}
	
	for building in placed_buildings:
		var data: BuildingData = building["data"]
		
		for req in data.requirements:
			if totals.has(req.resource):
				totals[req.resource] += req.amount
			else:
				totals[req.resource] = req.amount
				
	return totals

# Sums up the total power generation, consumption, and net balance of the layout
func calculate_power_totals() -> Dictionary:
	var totals = {
		"generation": 0.0,
		"consumption": 0.0,
		"balance": 0.0
	}
	
	for building in placed_buildings:
		var data: BuildingData = building["data"]
		totals["generation"] += data.power_generation
		totals["consumption"] += data.power_consumption
		
	totals["balance"] = totals["generation"] - totals["consumption"]
	return totals
