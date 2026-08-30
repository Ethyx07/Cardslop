extends Interactable

const CARD_PACK = preload("uid://pl2s7w65giq2")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$InteractableLabel.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super(delta)
	

func on_interacted(player : PlayerController) -> void:
	super(player)
	print("card seller as interacted with by ", player.name)
	var card_pack = CARD_PACK.new()
	card_pack.item_data = preload("uid://uahckpyfglq8")
	player.add_item_to_inventory(card_pack)
