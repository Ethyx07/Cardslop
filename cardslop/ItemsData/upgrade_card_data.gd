extends ItemData

class_name UpgradeCardData


#Turns it all into a dictionary which can be sent across rpc
func to_dictionary() -> Dictionary:
	return {
		"item_id" : item_id,
	}
	
func apply_dictionary(dict : Dictionary) -> void:
	pass
