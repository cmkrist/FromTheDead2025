extends CharacterBody2D
class_name NPC

var health = 100.0
var SPEED = 5000.0
const SPRINT_MOD = 1.5
const BASE_SPEED = 1000.0
const DIAGONAL_SPEED_MODIFIER = 0.75

@export var Goal:Node

const Characters = {
	"Male1": "res://assets/textures/male_1.png",
	"Male2": "res://assets/textures/male_2.png",
	"Female1": "res://assets/textures/female_1.png",
	"Female2": "res://assets/textures/female_2.png",
	"ConstructionWorker": "res://assets/textures/construction_worker.png",
	"OldMan": "res://assets/textures/old_man.png"
}
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
var delta_time_diff = 0.0

func _ready() -> void:
	# Set default character sprite if none is set
	if $Sprite2D.texture == null:
		var keys = Characters.keys()
		set_sprite(Characters[keys[randi_range(0, keys.size() - 1)]])
	# Set initial Goal
	if Goal:
		$NavigationAgent2D.target_position = Goal.global_position

func _physics_process(delta: float) -> void:
	if !$NavigationAgent2D.is_target_reached():
		velocity = to_local($NavigationAgent2D.get_next_path_position()).normalized() * SPEED * delta
	else:
		get_new_target()
	set_state()
	update_sprite()
	move_and_slide()
	
	

func get_new_target():
	# Get all goals in level, then select one at random
	var goals = get_tree().get_nodes_in_group("goals")
	if goals.size() > 0:
		var random_goal = goals[randi_range(0, goals.size() - 1)]
		$NavigationAgent2D.target_position = random_goal.global_position
		Goal = random_goal
		$NavigationAgent2D.target_position = Goal.global_position
	else:
		# If no goals are available, set a random position
		var random_position = Vector2(randi_range(0, 1000), randi_range(0, 1000))
		$NavigationAgent2D.target_position = random_position
		Goal = null
		
func set_state():
	previous_state = current_state
	if velocity == Vector2.ZERO:
		current_state = STATE.IDLE
	elif abs(velocity.x) > abs(velocity.y):
		# Moving l/r
		if velocity.x > 0:
			current_state = STATE.WALK_RIGHT
		else:
			current_state = STATE.WALK_LEFT
	else:
		# Moving u/d
		if velocity.y > 0:
			current_state = STATE.WALK_DOWN
		else:
			current_state = STATE.WALK_UP

func update_sprite() -> void:

	match current_state:
		STATE.IDLE:
			$AnimationPlayer.stop()
			match previous_state:
				STATE.WALK_LEFT:
					$Sprite2D.frame = 0
				STATE.WALK_RIGHT:
					$Sprite2D.frame = 3
				STATE.WALK_UP:
					$Sprite2D.frame = 2
				STATE.WALK_DOWN:
					$Sprite2D.frame = 1
				_:
					$Sprite2D.frame = 0
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

func set_sprite(res_location):
	$Sprite2D.texture = load(res_location)
	$Sprite2D.frame = 1
	
# Setup function to be called when node is added to scene
