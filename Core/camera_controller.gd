extends Camera2D

# --- ZOOM SETTINGS ---
var zoom_min: Vector2 = Vector2(0.2, 0.2)  # How far out you can zoom
var zoom_max: Vector2 = Vector2(3.0, 3.0)  # How close you can zoom in
var zoom_speed: float = 0.15               # How fast the scroll wheel zooms

# --- PAN SETTINGS ---
var is_panning: bool = false
var last_mouse_pos: Vector2

func _unhandled_input(event: InputEvent) -> void:
	# 1. Handle Zooming (Scroll Wheel)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			# Zoom In
			zoom += Vector2(zoom_speed, zoom_speed)
			zoom = zoom.clamp(zoom_min, zoom_max)
			
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			# Zoom Out
			zoom -= Vector2(zoom_speed, zoom_speed)
			zoom = zoom.clamp(zoom_min, zoom_max)
			
		# 2. Handle Panning Trigger (Middle Mouse Button)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_panning = true
				last_mouse_pos = event.position
			else:
				is_panning = false

	# 3. Handle Panning Movement
	elif event is InputEventMouseMotion and is_panning:
		# Calculate how far the mouse moved since the last frame
		var delta = event.position - last_mouse_pos
		
		# Move the camera in the opposite direction of the mouse drag.
		# We divide by zoom.x so the pan speed scales perfectly whether you are zoomed way in or way out!
		position -= delta / zoom.x
		
		# Update the last mouse position for the next frame
		last_mouse_pos = event.position
