extends Resource
class_name BuildingData

enum Category {
	SPECIAL, PRODUCTION, POWER, LOGISTICS, ORGANIZATION, 
	TRANSPORT, FOUNDATIONS, WALLS, ARCHITECTURE
}

enum SubCategory {
	# Special
	PROGRESSION, AWESOME_BONUS_PROGRAM, FICSIT_BLUEPRINT_DESIGNERS, WORKSTATIONS,
	# Production
	MANUFACTURERS, SMELTERS, MINERS, FLUID_EXTRACTORS,
	# Power
	GENERATORS, POWER_DISTRIBUTION, WALL_OUTLETS,
	# Logistics
	CONVEYOR_BELTS, CONVEYOR_LIFTS, CONVEYOR_SUPPORTS, PIPELINES, PIPELINE_SUPPORTS, SORTING, MONITORING,
	# Organization
	LIGHTS, SIGNS, STORAGE, TOWERS,
	# Transport
	VEHICLE_TRANSPORT, VEHICLE_PATHS, RAILWAY_TRANSPORT, HYPERTUBES, JUMP_PADS, ELEVATORS,
	# Foundations
	FOUNDATIONS, RAMPS, INVERTED_RAMPS, QUARTER_PIPES,
	# Walls
	BASIC_WALLS, CONVEYOR_CONNECTIONS, RAMP_WALLS, INVERTED_RAMP_WALLS, TILTED_WALLS, WINDOW_WALLS, FRAMED_WINDOWS, DOORS,
	# Architecture
	ROOFS, FRAMES, BEAMS, PILLARS, ATTACHMENTS, CATWALKS
}

# This dictionary maps the Main Categories to their specific SubCategories
const CATEGORY_TREE: Dictionary = {
	Category.SPECIAL: [SubCategory.PROGRESSION, SubCategory.AWESOME_BONUS_PROGRAM, SubCategory.FICSIT_BLUEPRINT_DESIGNERS, SubCategory.WORKSTATIONS],
	Category.PRODUCTION: [SubCategory.MANUFACTURERS, SubCategory.SMELTERS, SubCategory.MINERS, SubCategory.FLUID_EXTRACTORS],
	Category.POWER: [SubCategory.GENERATORS, SubCategory.POWER_DISTRIBUTION, SubCategory.WALL_OUTLETS],
	Category.LOGISTICS: [SubCategory.CONVEYOR_BELTS, SubCategory.CONVEYOR_LIFTS, SubCategory.CONVEYOR_SUPPORTS, SubCategory.PIPELINES, SubCategory.PIPELINE_SUPPORTS, SubCategory.SORTING, SubCategory.MONITORING],
	Category.ORGANIZATION: [SubCategory.LIGHTS, SubCategory.SIGNS, SubCategory.STORAGE, SubCategory.TOWERS],
	Category.TRANSPORT: [SubCategory.VEHICLE_TRANSPORT, SubCategory.VEHICLE_PATHS, SubCategory.RAILWAY_TRANSPORT, SubCategory.HYPERTUBES, SubCategory.JUMP_PADS, SubCategory.ELEVATORS],
	Category.FOUNDATIONS: [SubCategory.FOUNDATIONS, SubCategory.RAMPS, SubCategory.INVERTED_RAMPS, SubCategory.QUARTER_PIPES],
	Category.WALLS: [SubCategory.BASIC_WALLS, SubCategory.CONVEYOR_CONNECTIONS, SubCategory.RAMP_WALLS, SubCategory.INVERTED_RAMP_WALLS, SubCategory.TILTED_WALLS, SubCategory.WINDOW_WALLS, SubCategory.FRAMED_WINDOWS, SubCategory.DOORS],
	Category.ARCHITECTURE: [SubCategory.ROOFS, SubCategory.FRAMES, SubCategory.BEAMS, SubCategory.PILLARS, SubCategory.ATTACHMENTS, SubCategory.CATWALKS]
}

@export var building_name: String = "New Building"

# Godot's Vector2i is the exact equivalent of Unity's Vector2Int
@export var size_meters: Vector3i = Vector3i(8, 8, 1) 

# Texture2D is Godot's standard for UI icons and sprites
@export var icon: Texture2D

# For the grid visual (equivalent to Unity's public GameObject prefab)
@export var prefab: PackedScene

# --- Make sure these are exported so you can assign them in the Inspector! ---
@export var category: Category
@export var sub_category: SubCategory

@export var power_consumption: float = 0.0
@export var power_generation: float = 0.0

# Array to hold the materials needed to build this structure
@export var requirements: Array[BuildingRequirement] = []

# Calculates the net power, just like the GetNetPower() method in your Unity script
func get_net_power() -> float:
	return power_generation - power_consumption
