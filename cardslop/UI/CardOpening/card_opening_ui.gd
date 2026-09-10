extends Control

class_name CardOpeningUI

@onready var card_buttons : Array[CardOpeningButton] = [
	$VBoxContainer/UpperContainer/Card1,
	$VBoxContainer/UpperContainer/Card2,
	$VBoxContainer/UpperContainer/Card3,
	$VBoxContainer/LowerContainer/Card4,
	$VBoxContainer/LowerContainer/Card5
]
@export var controlling_player : PlayerController

@onready var confirm_button = $VBoxContainer/Confirm


#--------------------------------------------
#		UI SETUP LOGIC
#--------------------------------------------
#Here we request to setup the ui (if client)
#If not client we can just set it up
#We reset the ui to it default state prior to setting it up

#Called from server to client to say "activate ui please"
@rpc("any_peer", "call_remote", "reliable")
func request_setup_ui() -> void:
	if not is_multiplayer_authority():
		return
	
	setup_ui()

func setup_ui() -> void:
	if not is_multiplayer_authority():
		return
		
	reset_ui()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true

func reset_ui() -> void:
	for i in card_buttons.size():
		var button := card_buttons[i]
		if not button:
			continue
		button.reset()

	if not confirm_button:
		return

	confirm_button.disabled = true


#--------------------------------------------
#		CARD REVEAL LOGIC
#--------------------------------------------
# We first request to reveal a card (called from our button)
# Player controller logic occurs on server side (gets the card and returns its dict of info
# We then request/setup card data on that card_button
# This is finished by checking if all buttons are active allowing us to quit out

func request_card_reveal(card_button : CardOpeningButton) -> void:
	var card_index = card_buttons.find(card_button)
	if multiplayer.is_server():
		controlling_player.reveal_card(card_index)
	else:
		controlling_player.request_reveal_card.rpc_id(1, card_index)

#Requesting that client sets their card to visible and all that
@rpc("any_peer", "call_remote", "reliable")
func request_setup_card_data(button_index : int, card_data : Dictionary) -> void:
	if not is_multiplayer_authority():
		return
	setup_card_data(button_index, card_data)
	
func setup_card_data(button_index : int, card_data : Dictionary) -> void:
	var card_button = card_buttons[button_index]
	card_button.setup_card_from_dict(card_data)
	check_all_cards_revealed()

func check_all_cards_revealed() -> void:
	for button in card_buttons:
		if not button.is_revealed:
			return
	confirm_button.disabled = false

func _on_confirm_pressed() -> void:
	if multiplayer.is_server():
		controlling_player.complete_pack_opening()
	else:
		controlling_player.request_complete_pack_opening.rpc_id(1)
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
