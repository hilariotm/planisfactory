extends PanelContainer

@export var grid_manager: Node2D
@export var player_controller: Node
@export var all_buildings: Array[BuildingData] = [] # Drag all your .tres files here!

@onready var category_bar = $VBoxContainer/CategoryBar
@onready var sub_category_bar = $VBoxContainer/SubCategoryBar
@onready var building_grid = $VBoxContainer/ScrollContainer/BuildingGrid

func _ready():
	_populate_categories()

# --- 1. Populate Main Categories ---
func _populate_categories():
	_clear_container(category_bar)
	
	# Loop through the enums to create the main buttons
	for cat_key in BuildingData.Category.keys():
		var btn = Button.new()
		btn.text = cat_key.capitalize() # Turns "PRODUCTION" into "Production"
		btn.pressed.connect(func(): _on_category_selected(BuildingData.Category[cat_key]))
		category_bar.add_child(btn)

# --- 2. Populate SubCategories when a Main Category is clicked ---
func _on_category_selected(selected_category: BuildingData.Category):
	_clear_container(sub_category_bar)
	_clear_container(building_grid) # Clear the grid so old buildings don't linger
	
	var sub_cats = BuildingData.CATEGORY_TREE[selected_category]
	
	for sub_cat in sub_cats:
		var btn = Button.new()
		btn.text = BuildingData.SubCategory.keys()[sub_cat].capitalize()
		btn.pressed.connect(func(): _on_subcategory_selected(selected_category, sub_cat))
		sub_category_bar.add_child(btn)

# --- 3. Populate Buildings when a SubCategory is clicked ---
func _on_subcategory_selected(cat: BuildingData.Category, sub_cat: BuildingData.SubCategory):
	_clear_container(building_grid)
	
	for building in all_buildings:
		if building.category == cat and building.sub_category == sub_cat:
			var btn = Button.new()
			
			# 1. Apply the SVG Icon
			if building.icon:
				btn.icon = building.icon
				btn.expand_icon = true # Forces the SVG to resize to fit the button
				btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				
			# 2. Use a Tooltip instead of button text so the grid stays clean
			var raw_name = building.resource_path.get_file().get_basename()
			btn.tooltip_text = raw_name.capitalize() 
			
			# 3. Set a uniform square size for the grid
			btn.custom_minimum_size = Vector2(80, 80) 
			
			# Tell the Grid Manager to equip this building!
			btn.pressed.connect(func(): 
				player_controller.set_state(player_controller.State.BUILD)
				grid_manager.set_active_building(building)
			)
			building_grid.add_child(btn)

# Helper function to wipe old buttons when swapping menus
func _clear_container(container: Container):
	for child in container.get_children():
		child.queue_free()
