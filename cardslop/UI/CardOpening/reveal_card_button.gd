extends VBoxContainer

class_name CardOpeningButton

var is_revealed = false

@onready var card_text = $CardName
@onready var card_button = $RevealButton

func _on_mouse_entered() -> void:
	card_text.self_modulate.a = 1 if card_button.disabled else 0

func _on_mouse_exited() -> void:
	card_text.self_modulate.a = 0

func _on_pressed() -> void:
	if not is_revealed:
		get_parent().get_parent().get_parent().request_card_reveal(self)

func reset() -> void:
		card_button.disabled = false
		card_text.self_modulate = 0
		is_revealed = false

func setup_card(data : ItemData) -> void:
	card_text.text = data.item_name
	card_button.texture_disabled = data.item_sprite
	
#We grab the default data for this item_id.
#Allows for dicts that have different keys (some dont change item_name) to be
#passed in without errors from missing values
func setup_card_from_dict(data : Dictionary) -> void:
	var default_data = ItemDatabase.item_database[data["item_id"]] as ItemData
	
	card_text.text = data.get("item_name", default_data.item_name)
	card_button.texture_disabled = await CardTextureGenerator.generate(default_data)
	
	card_button.disabled = true
	card_text.self_modulate.a = 1
	
	is_revealed = true
