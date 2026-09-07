extends Node
class_name Item

@export var item_data : ItemData

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_item_use(player : PlayerController) -> void:
	print("the item used was ", item_data.item_name)
