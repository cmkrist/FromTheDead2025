extends Control

@onready var UnrestBar := $Topbar/VBoxContainer/ProgressBar2
@onready var BloodBar := $Bottombar/VBoxContainer/ProgressBar
@onready var SprintBar := $AbilityContainer/Sprint
@onready var Player := get_tree().get_first_node_in_group("Player")
var is_summoning = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Player.summon.connect(_summon)
	UnrestBar.max_value = 100
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	BloodBar.value = Global.blood_level
	SprintBar.value = Player.sprint_timer
	UnrestBar.value = 100 - Global.total_NPCs
	if is_summoning:
		$SummonUI/ProgressBar.value = $SummonUI/ProgressBar.max_value - Player.casting_timer
		if Player.casting_timer <= 0:
			$SummonUI.hide()
			is_summoning = false
	pass

func _summon():
	is_summoning = true
	$SummonUI/ProgressBar.max_value = Player.casting_timer
	$SummonUI/ProgressBar.value = 0
	$SummonUI.show()
