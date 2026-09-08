extends Control

class_name CardOpeningUI

@export var card_buttons : Array[CardOpeningButton]

func setup_opening(card_list : Array[ItemData])-> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true
	for i in card_list.size():
		if card_buttons.size() - 1 < i:
			push_error("Trying to setup more cards than buttons")
			break
		card_buttons[i].setup_card(card_list[i])
		
