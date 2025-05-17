# scenes/creatures/character.gd
extends CharacterBody2D
class_name Character

# Health and movement properties
var health = 100.0
var SPEED = 5000.0
const SPRINT_MOD = 2.25
const BASE_SPEED = 1000.0
const DIAGONAL_SPEED_MODIFIER = 0.75

# States
enum STATE {
	IDLE,
	WALK_LEFT,
	WALK_RIGHT,
	WALK_UP,
	WALK_DOWN
}

var current_state = STATE.IDLE
var previous_state = STATE.IDLE

# Character dictionary for easy access to character sprites
const Characters = {
	"Male1": "res://assets/textures/male_1.png",
	"Male2": "res://assets/textures/male_2.png",
	"Female1": "res://assets/textures/female_1.png",
	"Female2": "res://assets/textures/female_2.png",
	"ConstructionWorker": "res://assets/textures/construction_worker.png",
	"OldMan": "res://assets/textures/old_man.png"
}

# Navigation
@export var Goal: Node

# Called when the node enters the scene tree for the first time
func _ready() -> void:
	# Override in child classes
	pass

func _physics_process(delta: float) -> void:
	# Override in child classes
	pass

# Set sprite based on resource location
func set_sprite(res_location: String) -> void:
	$HumanSprite.texture = load(res_location)
	$HumanSprite.frame = 1

# Core movement function - determines state based on velocity
func set_state() -> void:
	previous_state = current_state
	if velocity.length() < 1.0:
		current_state = STATE.IDLE
	elif abs(velocity.x) > abs(velocity.y):
		current_state = STATE.WALK_LEFT if velocity.x < 0 else STATE.WALK_RIGHT
	else:
		current_state = STATE.WALK_UP if velocity.y < 0 else STATE.WALK_DOWN

# Apply correct animation based on state
func update_sprite() -> void:
	match current_state:
		STATE.IDLE:
			$AnimationPlayer.stop()
			_set_idle_frame(previous_state)
		STATE.WALK_LEFT:
			if !($AnimationPlayer.is_playing() && $AnimationPlayer.current_animation == "human_animations/walk_left"):
				$AnimationPlayer.play("human_animations/walk_left")
		STATE.WALK_RIGHT:
			if !($AnimationPlayer.is_playing() && $AnimationPlayer.current_animation == "human_animations/walk_right"):
				$AnimationPlayer.play("human_animations/walk_right")
		STATE.WALK_UP:
			if !($AnimationPlayer.is_playing() && $AnimationPlayer.current_animation == "human_animations/walk_up"):
				$AnimationPlayer.play("human_animations/walk_up")
		STATE.WALK_DOWN:
			if !($AnimationPlayer.is_playing() && $AnimationPlayer.current_animation == "human_animations/walk_down"):
				$AnimationPlayer.play("human_animations/walk_down")

# Helper function to set the correct idle frame
func _set_idle_frame(previous_state: int) -> void:
	# Default implementation for human sprites
	match previous_state:
		STATE.WALK_LEFT:
			$HumanSprite.frame = 0
		STATE.WALK_RIGHT:
			$HumanSprite.frame = 3
		STATE.WALK_UP:
			$HumanSprite.frame = 2
		STATE.WALK_DOWN:
			$HumanSprite.frame = 1
		_:
			$HumanSprite.frame = 1

# Take damage function
func _take_damage(damage: float) -> void:
	health -= damage
	$Blood.emitting = true

# Get a new target from the goals group
func get_new_target() -> void:
	# Get all goals in level, then select one at random
	var goals = get_tree().get_nodes_in_group("goals")
	if goals.size() > 0:
		var random_goal = goals[randi_range(0, goals.size() - 1)]
		if has_node("NavigationAgent2D"):
			$NavigationAgent2D.target_position = random_goal.global_position
		Goal = random_goal
	else:
		# If no goals are available, set a random position
		var random_position = Vector2(randi_range(0, 1000), randi_range(0, 1000))
		if has_node("NavigationAgent2D"):
			$NavigationAgent2D.target_position = random_position
		Goal = null
