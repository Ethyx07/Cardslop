extends VBoxContainer

class_name PlayerInventory

@export var controlling_player : PlayerController
@export var selected_style : StyleBoxFlat
@export var default_style : StyleBoxFlat

@export var inventory_slots : Array[InventorySlot]

const INVENTORY_SLOT = preload("uid://iacrjivymled")

var selected_slot : InventorySlot

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not controlling_player:
		return
		
	var inventory_size = controlling_player.get_inventory_size()
	while inventory_slots.size() < inventory_size: #Gives us dynamic sizing
		var inventory_slot = INVENTORY_SLOT.instantiate() as InventorySlot
		$InventoryRow.add_child(inventory_slot)
		inventory_slots.append(inventory_slot)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if not controlling_player:
		print("Not controlling a player, yikes")
		return
		
	if selected_slot:
		var item_data = selected_slot.get_item_data() as ItemData
		if item_data:
			$Label.text = item_data.item_name
		else:
			$Label.text = ""
		
func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	#Checks key pressed & if its a number key. If so we try to set that inventory slot to active
	if event is InputEventKey and event.pressed and not event.echo:
		var key_pressed = event.as_text()
		if not key_pressed.is_valid_int():
			return
		var key_index = int(key_pressed) - 1
		if key_index < inventory_slots.size():
			update_selected_slot(inventory_slots[key_index])
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			change_inventory_slot(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			change_inventory_slot(1)

#Updates the currently selected slot to the new one being passed in
func update_selected_slot(new_slot : PanelContainer) -> void:
	new_slot.add_theme_stylebox_override("panel", selected_style)
	
	if selected_slot and selected_slot != new_slot:
		selected_slot.remove_theme_stylebox_override("panel")
		selected_slot.add_theme_stylebox_override("panel", default_style)
		
	selected_slot = new_slot

func change_inventory_slot(direction : int) -> void:
	if inventory_slots.is_empty():
		return
	
	var current_index := inventory_slots.find(selected_slot)
	
	if current_index == -1:
		current_index = 0
	#Reminder Riley: Wrapi treats this as [min, max)
	var new_index = wrapi(current_index + direction, 0, inventory_slots.size())
	
	update_selected_slot(inventory_slots[new_index])

func get_selected_slot_index() -> int:
	if not selected_slot:
		return -1
	return inventory_slots.find(selected_slot)
	
func get_selected_item_data() -> ItemData:
	if not selected_slot:
		return null
		
	return selected_slot.get_item_data()

func set_inventory(new_inventory : Array[Dictionary]) -> void:
	for slot in inventory_slots:
		slot.clear_slot()
	
	for i in new_inventory.size():
		if i >= inventory_slots.size():
			break
		var item := ItemDatabase.create_item_from_dictionary(new_inventory[i])
		if item:
			inventory_slots[i].set_item_data(item)
