extends ItemData

class_name MoneyCardData

#Turns it all into a dictionary which can be sent across rpc
func to_dictionary() -> Dictionary:
	return {
		"item_id" : item_id,
		"item_value" : item_value
	}
	
func apply_dictionary(dict : Dictionary) -> void:
	item_value = dict.get("item_value", 0)
