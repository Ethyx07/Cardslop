extends Node3D

const PLAYERCONTROLLER = preload("uid://cl4xivdhhcbae")
const OBJECT = preload("uid://bspd4g0rn741p")
var players : Array[CharacterBody3D]

var monster_database = {
	"fire" : preload("uid://pkiyr2cgd6mf"),
	"water" : preload("uid://nyqbayhmaq5t"),
	"grass" : preload("uid://byoqg3mpofgvs")
}

func _ready() -> void:
	Networking.host_created.connect(on_host_created)
	
	multiplayer.connected_to_server.connect(on_connected_to_server)
	$MultiplayerSpawner.spawn_function = spawn_from_data

func on_connected_to_server() -> void:
	$CanvasLayer/VBoxContainer.hide()

func on_host_created() -> void:
	#Spawns host player
	spawn_player(multiplayer.get_unique_id())
	multiplayer.peer_connected.connect(spawn_player)


func spawn_player(peer_id : int) -> void:	
	if not multiplayer.is_server():
		return
	
	var spawn_data := {
		"type": "player",
		"peer_id": peer_id,
		"position": $SpawnPoint.position
	}
	
	$MultiplayerSpawner.spawn(spawn_data)

func spawn_monster(spawn_position : Vector3, peer_id : int, monster_data : String) -> void:
	$MultiplayerSpawner.spawn({
		"type": "monster",
		"position": spawn_position,
		"peer_id": peer_id,
		"monster_data" : monster_data
		})
		
func spawn_from_data(data : Dictionary) -> Node:
	if data["type"] == "player":
		var new_player := PLAYERCONTROLLER.instantiate() as CharacterBody3D
		
		new_player.name = str(data["peer_id"])
		new_player.position = data["position"] + Vector3(0, 2,0)
		return new_player
	
	elif data["type"] == "monster":
		var new_monster := OBJECT.instantiate()
		new_monster.position = data["position"] + Vector3(0,2,0)
		var trainer = get_node_or_null(str(data["peer_id"])) as PlayerController
		if not trainer:
			return null
		trainer.set_monster(new_monster)
		new_monster.trainer = trainer
		new_monster.set_monster_data(monster_database[data["monster_data"]])
		return new_monster 
	
	return null
	
func initialise_player(player : CharacterBody3D) -> void:	
	for other in players:
		player.add_collision_exception_with(other)
		other.add_collision_exception_with(player)
	players.append(player)


func _on_host_pressed() -> void:
	Networking.host_lobby()
	$CanvasLayer/VBoxContainer.hide()
	
func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_join_pressed() -> void:
	Steam.activateGameOverlay("friends")

func _on_multiplayer_spawner_spawned(node: Node) -> void:
	if node is CharacterBody3D:
		initialise_player(node)
		
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Quit"):
		get_tree().quit()
