extends Node


var item_database := {
	"basic_pack" : preload("uid://uahckpyfglq8"),
	"fire_starter" : preload("uid://2twhyqyaf5yo"),
	"water_starter" : preload("uid://yk8syj882a5q"),
	"grass_starter" : preload("uid://b2wgydhjcfr8l")
}


func create_item(item_id : String) -> ItemData:
	if not item_database.has(item_id):
		push_error("Unknown item id: " + item_id)
		return null
	
	var base_data = item_database[item_id] as ItemData
	
	return base_data.duplicate(true) as ItemData
	
func create_item_from_dictionary(dict : Dictionary) -> ItemData:
	var item_id = dict.get("item_id", "") as String

	var item = create_item(item_id)
	if not item:
		return null
	
	item.apply_dictionary(dict)
	return item
