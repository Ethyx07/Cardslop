extends Interactable

const CARD_PACK_DATA = preload("uid://uahckpyfglq8")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$InteractableLabel.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super(delta)
	

func on_interacted(player : PlayerController) -> void:
	super(player)
	print("card seller as interacted with by ", player.name)
	
	player.request_add_item(CARD_PACK_DATA)
