extends CharacterBody3D

class_name PlayerController

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const INVENTORY_SIZE = 5

var current_monster : Monster
var monster_spawned := false

var hovered_interactable : Interactable

@export var mouse_sensitivity := 0.001

@onready var head : Node3D = $Head
@onready var eye_camera: Camera3D = $Head/EyeCamera
@onready var player_inventory : PlayerInventory = $PlayerUI/PlayerInventory

#Server side REAL inventory (not just the visual stuff the ui does)
var inventory : Array[ItemData] = [] #Empty so sad :(

var current_monster_data : String

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	
	var steam_id = Steam.getSteamID()
	var player_name = Steam.getFriendPersonaName(steam_id)
	$Head/Label3D.text = player_name
	
	
func _ready() -> void:
	$PlayerUI.visible = is_multiplayer_authority()
	
	if is_multiplayer_authority():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	if not eye_camera.current:
		eye_camera.make_current()
		
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("Interact") and hovered_interactable:
		hovered_interactable.on_interacted(self)
	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	var startPos := eye_camera.global_position
	var endPos := startPos + -(eye_camera.global_basis.z * 2)
	
	var ray := PhysicsRayQueryParameters3D.create(startPos, endPos)
	ray.collision_mask = 1 << 2
	var result := get_world_3d().direct_space_state.intersect_ray(ray)
	if result:
		var collider = result.collider as Interactable
		if collider:
			if hovered_interactable and hovered_interactable != collider:
				hovered_interactable.set_hovered_over(false, null) #Disables hovered interactable if we go from one to another in one frame
				
			hovered_interactable = collider
			hovered_interactable.set_hovered_over(true, self)
	else:
		if hovered_interactable:
			clear_hovered_interactable()
			
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("Left", "Right", "Up", "Down")
	var direction := (eye_camera.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()

func clear_hovered_interactable() -> void:
	hovered_interactable.set_hovered_over(false, null)
	hovered_interactable = null

func get_inventory_size() -> int:
	return INVENTORY_SIZE

#--------------------------------------------
#		INVENTORY LOGIC
#--------------------------------------------

#Can only send string cos rpc doesnt like sending resources. This is called by whatever is attempting to add something to this players inventory
func request_add_item(item_id : String) -> void:
	if multiplayer.is_server():
		add_item_to_inventory(item_id)
	else:
		request_add_item_server.rpc_id(1, item_id)

@rpc("any_peer", "call_remote", "reliable")
func request_add_item_server(item_id : String) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id != get_multiplayer_authority(): #Gotta make sure we only adjust the senders inventory
		return
	
	add_item_to_inventory(item_id)

#SERVER ONLY
func add_item_to_inventory(item_id : String) -> void:
	if not multiplayer.is_server(): 
		return
	
	if inventory.size() >= INVENTORY_SIZE:
		print("Attempting to add item to full inventory")
		return
	
	var new_item := ItemDatabase.create_item(item_id) as ItemData
	
	if not new_item:
		return
		
	inventory.append(new_item)
	
	sync_inventory_to_owner()

#SERVER ONLY - Different from add item. Add item adds the default item, add_item_data adds a customised version
func add_item_data_to_inventory(item_data : ItemData) -> void:
	if not multiplayer.is_server(): 
		return
		
	if inventory.size() >= INVENTORY_SIZE:
		print("Attempting to add item to full inventory")
		return
	
	if not item_data:
		return
	
	inventory.append(item_data)
	
	sync_inventory_to_owner()
		
	

#SERVER ONLY
func remove_item_from_inventory(slot_index : int) -> void:
	if not multiplayer.is_server(): 
		return
	
	if slot_index < 0 or slot_index >= inventory.size(): #Cant remove from slot if its an empty one or not within our inventory size
		return
	
	inventory.remove_at(slot_index)
	
	sync_inventory_to_owner()

func get_inventory_as_dictionaries() -> Array[Dictionary]:
	var result : Array[Dictionary]
	
	for item in inventory:
		result.append(item.to_dictionary())
	
	return result

func sync_inventory_to_owner() -> void:
	if not multiplayer.is_server():
		return
	
	var inventory_data = get_inventory_as_dictionaries()
	var owner_id := get_multiplayer_authority() 
	if owner_id == multiplayer.get_unique_id(): #Checks if its server that we are updating
		update_inventory_ui(inventory_data)
	else:
		update_inventory_ui.rpc_id(owner_id, inventory_data)
		
@rpc("any_peer", "call_remote", "reliable")
func update_inventory_ui(new_inventory : Array[Dictionary]) -> void:
	if not is_multiplayer_authority():
		return
	
	player_inventory.set_inventory(new_inventory)


#--------------------------------------------
#		INVENTORY INTERACTION LOGIC
#--------------------------------------------

#Got default values for spawning and spawn pos stuff for things that dont need to be spawned into the world
func request_use_item(slot_index : int, spawn_position : Vector3 = Vector3.ZERO, has_spawn_position : bool = false) -> void:
	if multiplayer.is_server():
		use_inventory_item(slot_index, spawn_position, has_spawn_position)
	else:
		request_use_item_server.rpc_id(1, slot_index, spawn_position, has_spawn_position)

#Asks the server very nicely to let us use our items
@rpc("any_peer", "call_remote", "reliable")
func request_use_item_server(slot_index : int, spawn_position, has_spawn_position) -> void:
	if not multiplayer.is_server():
		return

	var sender_id = multiplayer.get_remote_sender_id()
	
	if sender_id != get_multiplayer_authority(): #Only want to use the item on the player who requested it
		return
		
	use_inventory_item(slot_index, spawn_position, has_spawn_position)
	
#SERVER ONLY FUNCTION: SHOULD NEVER BE CALLED LOCALLY
func use_inventory_item(slot_index, spawn_position, has_spawn_position) -> void: 
	if not multiplayer.is_server():
		return
	if slot_index < 0 or slot_index >= inventory.size():
		return
	var item_data := inventory[slot_index]
	
	if item_data:
		match item_data.item_type:
			GlobalType.itemTypes.CardPack:
				open_card_pack(slot_index, item_data)
			GlobalType.itemTypes.MonsterCard:
				if has_spawn_position:
					use_monster_card(slot_index, item_data, spawn_position)
		
#Server function
func open_card_pack(slot_index : int, item_data : ItemData) -> void:
	if not multiplayer.is_server():
		return
	#Temp stuff here
	var possible_cards = ItemDatabase.get_card_list_from_id(item_data.item_id)
	if possible_cards.size() <= 0:
		push_error("Card pack doesnt have card list associated with it")
		return
	
	var cards_in_pack : Array[ItemData]
	
	var monster_card_list = possible_cards["monster_cards"]
	var monster_id = monster_card_list.pick_random()
	
	
	var money_value = possible_cards["money_cards"].pick_random()
	var new_card = ItemDatabase.create_item(monster_id)
	if not new_card:
		return
	var new_money = ItemDatabase.create_item("money_card")
	new_money.item_value = money_value
	new_money.item_name = "$%d (Money)" % new_money.item_value
	if not new_money:
		return
	cards_in_pack.append(new_card)
	cards_in_pack.append(new_money)
	
	remove_item_from_inventory(slot_index)
	
	for card in cards_in_pack:
		card.on_received_from_pack(self)

	#inventory[slot_index] = new_card
	
	sync_inventory_to_owner()

#Server function
func use_monster_card(slot_index : int, item_data : ItemData, spawn_position : Vector3) -> void:
	if not multiplayer.is_server():
		return
	
	if current_monster: #Wont be needed in future as we will hide this ui when monsters are spawned 
		return
	get_parent().spawn_monster(spawn_position, get_multiplayer_authority(), item_data.item_id)
	
	print(
		"Spawned monster from card: ",
		item_data.item_id,
		" | Bonus health: ",
		item_data.bonus_health,
		" | Bonus attack: ",
		item_data.bonus_damage
	)
	
	#Apply bonus effects here
	
	#End of bonus effects
	

func get_item_use_spawn_position() -> Dictionary:
	var start_pos := eye_camera.global_position
	var end_pos := start_pos + -(eye_camera.global_basis.z * 20)

	var ray := PhysicsRayQueryParameters3D.create(start_pos,end_pos)

	ray.collision_mask = 1 << 1

	return get_world_3d().direct_space_state.intersect_ray(ray)
	
#--------------------------------------------
#		MONSTER LOGIC
#--------------------------------------------

func set_monster(monster : Monster) -> void:
	if not monster:
		return
	current_monster = monster
	monster_spawned = true
	
func clear_monster() -> void:
	current_monster = null
	monster_spawned = false


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	if event is InputEventMouseMotion:
		var relative = event.relative * mouse_sensitivity

		head.rotate_y(-relative.x)
		eye_camera.rotate_x(-relative.y)

		eye_camera.rotation.x = clamp(eye_camera.rotation.x, deg_to_rad(-40),deg_to_rad(40))

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var slot_index := player_inventory.get_selected_slot_index()

		if slot_index == -1:
			return

		var result := get_item_use_spawn_position()

		if result:
			request_use_item(slot_index, result.position, true)
		else:
			request_use_item(slot_index)

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if current_monster:
			if multiplayer.is_server():
				request_despawn(current_monster.name)
			else:
				request_despawn.rpc_id(1, current_monster.name)



func try_spawn_monster(key : String) -> void:
	var result := get_item_use_spawn_position()
	
	if result:
		if multiplayer.is_server():
			request_spawn(result.position, multiplayer.get_unique_id(), key)
		else:
			request_spawn.rpc_id(1, result.position, multiplayer.get_unique_id(), key)
		

@rpc("any_peer", "call_remote", "reliable")
func request_spawn(spawn_position : Vector3, peer_id : int, monster_data : String) -> void:
	if not multiplayer.is_server():
		return
	
	get_parent().spawn_monster(spawn_position, peer_id, monster_data)

@rpc("any_peer", "call_remote", "reliable")
func request_despawn(monster_name : String) -> void:
	var monster = get_parent().get_node_or_null(monster_name) as Monster
	if not monster:
		return
	
	monster.queue_free()	

	
	
