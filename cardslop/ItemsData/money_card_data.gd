extends ItemData

class_name MoneyCardData

#Turns it all into a dictionary which can be sent across rpc
func to_dictionary() -> Dictionary:
	return {
		"item_id" : item_id,
		"item_value" : item_value,
		"item_name" : item_name
	}
	
func apply_dictionary(dict : Dictionary) -> void:
	super(dict)
	item_value = dict.get("item_value", 0)
	item_name = dict.get("item_name", 0)

func on_received_from_pack(player : PlayerController) -> void:
	item_name = "$%d (Money)" % item_value
	player.add_item_data_to_inventory(self)
	
	
