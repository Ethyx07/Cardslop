extends Item

class_name CardPack
var monster_card_data := [preload("uid://2twhyqyaf5yo"), preload("uid://b2wgydhjcfr8l"), preload("uid://yk8syj882a5q")]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_item_use(player : PlayerController) -> void:
	var monster_card := MonsterCard.new()
	monster_card.item_data = monster_card_data.pick_random()
	#player.remove_item_from_inventory(self)
	#player.add_item_to_inventory(monster_card)
	
