extends Resource

class_name ItemData

@export var item_id : String
@export var item_type : GlobalType.itemTypes
@export var item_name : String
@export var item_value : int
@export var item_sprite : Texture2D




#Turns it all into a dictionary which can be sent across rpc
func to_dictionary() -> Dictionary:
	return {
		"item_id" : item_id
	}
	
func apply_dictionary(dict : Dictionary) -> void:
	pass


func on_received_from_pack(player : PlayerController) -> void:
	player.request_add_item(item_id)
