extends PanelContainer

class_name InventorySlot

var stored_item : Item
var item_data : ItemData

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_item_data() -> ItemData:
	return item_data if item_data else null

func get_item() -> Item:
	return stored_item if stored_item else null

func add_item_to_slot(item : Item) -> void:
	if stored_item:
		return
	stored_item = item
	item_data = item.item_data
	$ItemTexture.texture = item_data.item_sprite

func clear_slot() -> void:
	$ItemTexture.texture = null
	stored_item = null
	item_data = null
	
