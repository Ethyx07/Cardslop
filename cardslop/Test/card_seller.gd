extends Interactable


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$InteractableLabel.visible = false
	$SellLabel.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super(delta)
	if hovered_by and is_hovered_over:
		var item_data := hovered_by.player_inventory.get_selected_item_data() as ItemData
		if item_data:
			$SellLabel.text = "Press Q to Sell (${item_value})".format(item_data) 
			$SellLabel.visible = true
		else:
			$SellLabel.visible = false
	else:
		$SellLabel.visible = false
		
func set_hovered_over(hovered : bool, hovering : PlayerController) -> void:
	super(hovered, hovering)
	


func on_interacted(player : PlayerController) -> void:
	super(player)
	print("card seller as interacted with by ", player.name)
	
	player.request_add_item("basic_pack")
