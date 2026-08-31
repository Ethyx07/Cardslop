extends PanelContainer

class_name InventorySlot

var item_data : ItemData

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_item_data() -> ItemData:
	return item_data if item_data else null

func set_item_data(new_item_data : ItemData) -> void:
	item_data = new_item_data
	
	if item_data:
		$ItemTexture.texture = item_data.item_sprite
	else:
		$ItemTexture.texture = null
	

func clear_slot() -> void:
	$ItemTexture.texture = null
	item_data = null
	
