extends Resource

class_name ItemData

@export var item_id : String
@export var item_name : String
@export var item_value : int
@export var item_sprite : Texture2D


#Bonus stat stuff
@export var bonus_health : int = 0
@export var bonus_damage : float = 0
@export var level : int = 1

#Turns it all into a dictionary which can be sent across rpc
func to_dictionary() -> Dictionary:
	return {
		"item_id" : item_id,
		"bonus_damage" : bonus_damage,
		"bonus_health" : bonus_health,
		"level" : level
	}
	
func apply_dictionary(dict : Dictionary) -> void:
	bonus_damage = dict.get("bonus_damage", 0)
	bonus_health = dict.get("bonus_health", 0)
	level = dict.get("level", 1)
