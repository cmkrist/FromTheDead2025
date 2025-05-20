extends Node

var unrest_level := 0.0
var blood_level := 100.0
var total_NPCs = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _physics_process(d):
	blood_level -= d;
	pass
