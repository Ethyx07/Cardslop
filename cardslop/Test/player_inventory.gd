extends HBoxContainer

@export var controlling_player : PlayerController

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if not controlling_player:
		print("Not controlling a player, yikes")
		return
	
	if Input.is_action_just_pressed("Inventory1"):
		controlling_player.set_selected_monster("fire")
	if Input.is_action_just_pressed("Inventory2"):
		controlling_player.set_selected_monster("water")
	if Input.is_action_just_pressed("Inventory3"):
		controlling_player.set_selected_monster("grass")
