extends CharacterBody2D

const SPEED = 300.0
const DIAGONAL_SPEED_MODIFIER = 0.75

var facing_left := false
var facing_up := false

# Animation frames
const FRAME_SIDE = 1
const FRAME_UP = 18

func _physics_process(delta: float) -> void:
	handle_movement()
	update_sprite()
	move_and_slide()

func handle_movement() -> void:
	var lr_direction := Input.get_axis("ui_left", "ui_right")
	var ud_direction := Input.get_axis("ui_up", "ui_down")
	
	# Update facing direction
	if lr_direction != 0.0:
		facing_left = lr_direction < 0
	if ud_direction != 0.0:
		facing_up = ud_direction < 0
	
	# Calculate velocity based on input
	if lr_direction != 0.0 and ud_direction != 0.0:
		# Moving diagonally - apply speed modifier
		velocity.x = lr_direction * SPEED * DIAGONAL_SPEED_MODIFIER
		velocity.y = ud_direction * SPEED * DIAGONAL_SPEED_MODIFIER
	elif lr_direction != 0.0:
		if facing_up:
			facing_up = false
		# Moving horizontally
		velocity.x = lr_direction * SPEED
		velocity.y = move_toward(velocity.y, 0, SPEED)
	elif ud_direction != 0.0:
		# Moving vertically
		velocity.y = ud_direction * SPEED
		velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		# Not moving - decelerate
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)

func update_sprite() -> void:
	# Update sprite direction
	$Sprite2D.flip_h = facing_left
	
	# Set appropriate animation frame
	if facing_up:
		$Sprite2D.frame = FRAME_UP
	else:
		$Sprite2D.frame = FRAME_SIDE
