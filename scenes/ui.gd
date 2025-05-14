extends Control

@onready var UnrestBar := $Topbar/VBoxContainer/ProgressBar2
@onready var BloodBar := $Bottombar/VBoxContainer/ProgressBar
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	BloodBar.value = Global.blood_level
	UnrestBar.value = Global.unrest_level
	pass
