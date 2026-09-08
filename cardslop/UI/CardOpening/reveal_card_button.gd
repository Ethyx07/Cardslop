extends VBoxContainer

class_name CardOpeningButton

func _on_mouse_entered() -> void:
	$CardName.self_modulate.a = 1 if $RevealButton.disabled else 0

func _on_mouse_exited() -> void:
	$CardName.self_modulate.a = 0

func _on_pressed() -> void:
	$RevealButton.disabled = true
	$CardName.self_modulate.a = 1

func setup_card(data : ItemData) -> void:
	$CardName.text = data.item_name
	$RevealButton.texture_disabled = data.item_sprite
