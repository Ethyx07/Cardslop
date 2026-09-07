extends Item
class_name MonsterCard

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_item_use(player : PlayerController) -> void:
	player.try_spawn_monster(item_data.item_key)
