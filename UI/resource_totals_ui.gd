extends PanelContainer

@export var grid_manager: Node2D
@export var entry_prefab: PackedScene

@onready var content_container = $ContentContainer

func _ready():
	# Connect the grid manager's signal to our update function
	if grid_manager:
		grid_manager.layout_changed.connect(update_totals)
		
	# Run once at startup to clear the panel if it's empty
	update_totals()

func update_totals():
	# 1. Clear out the old list
	for child in content_container.get_children():
		child.queue_free()
		
	if not grid_manager:
		return
		
	# 2. Get the fresh totals dictionary
	var totals = grid_manager.calculate_total_materials()
	
	# 3. Spawn a new UI row for each required resource
	for resource in totals.keys():
		var entry = entry_prefab.instantiate()
		content_container.add_child(entry)
		
		# Grab the nodes inside the instantiated row
		var icon_rect = entry.get_node("Icon")
		var label = entry.get_node("AmountLabel")
		
		# Apply the data
		icon_rect.texture = resource.icon
		label.text = "%s x%d" % [resource.resource_item_name, totals[resource]]
