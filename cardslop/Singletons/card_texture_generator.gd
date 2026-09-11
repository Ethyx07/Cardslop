extends Node

const MONEY_CARD_RENDERER = preload("uid://bbpxj4phdgtod")

func generate(item_data : ItemData, override_data : Dictionary) -> Texture2D:
	if not item_data:
		return null
	
	match item_data.item_type:
		GlobalType.itemTypes.MoneyCard:
			return await generate_money_card(item_data, override_data)
		GlobalType.itemTypes.MonsterCard:
			return generate_monster_card(item_data, override_data)
		_:
			return item_data.item_sprite

func generate_money_card(item_data : ItemData, override_data : Dictionary) -> Texture2D:
	var renderer =  MONEY_CARD_RENDERER.instantiate()
	add_child(renderer)
	var texture = await renderer.generate(item_data, override_data)
	
	renderer.queue_free()
	return texture
	
func generate_monster_card(item_data : ItemData, override_data : Dictionary) -> Texture2D:
	return item_data.item_sprite
