extends Node

class_name Interactable

var is_hovered_over := false
var hovered_by : PlayerController
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$InteractableLabel.visible = is_hovered_over


func set_hovered_over(hovered : bool, hovering : PlayerController) -> void:
	is_hovered_over = hovered
	hovered_by = hovering

func on_interacted(player : PlayerController) -> void:
	print("interacted")
