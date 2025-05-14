extends CharacterBody2D

var SPEED = 1000.0
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
	update_sprite()
	move_and_slide()

func update_sprite() -> void:
	# Determine current state based on velocity and facing direction
	var previous_state = current_state
	
	if velocity.length() < 10.0:  # Small threshold to detect idle state
		current_state = STATE.IDLE
	elif abs(velocity.x) > abs(velocity.y):
		# Horizontal movement is dominant
		current_state = STATE.WALK_LEFT if velocity.x < 0 else STATE.WALK_RIGHT
	else:
		# Vertical movement is dominant
		current_state = STATE.WALK_UP if velocity.y < 0 else STATE.WALK_DOWN
	
	# Only update animation if state changed
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
