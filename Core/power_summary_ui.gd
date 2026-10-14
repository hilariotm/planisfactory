extends PanelContainer

@export var grid_manager: Node2D

@onready var generation_label = $VBoxContainer/GenerationLabel
@onready var consumption_label = $VBoxContainer/ConsumptionLabel
@onready var balance_label = $VBoxContainer/BalanceLabel

func _ready():
	# Listen to the exact same signal our resource list uses!
	if grid_manager:
		grid_manager.layout_changed.connect(update_power_summary)
		
	update_power_summary()

func update_power_summary():
	if not grid_manager:
		return
		
	var totals = grid_manager.calculate_power_totals()
	
	# Update the text with a MW (Megawatt) suffix
	generation_label.text = "Generation: +%.1f MW" % totals["generation"]
	consumption_label.text = "Consumption: -%.1f MW" % totals["consumption"]
	
	# Change the color of the balance text depending on if we have surplus or deficit
	if totals["balance"] >= 0:
		balance_label.text = "Balance: +%.1f MW" % totals["balance"]
		balance_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2)) # Green
	else:
		balance_label.text = "Balance: %.1f MW" % totals["balance"]
		balance_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2)) # Red
