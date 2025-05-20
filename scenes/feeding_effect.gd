extends Node2D

signal feeding_completed

@onready var progress_bar = $ProgressBar
@onready var blur_rect = $BlurRect
@onready var timer = $Timer

var player_ref: Node2D
var target_ref: Node2D
var feed_duration: float = 1.0
var feed_progress: float = 0.0
var blood_increase: float

func _ready():
	timer.timeout.connect(_on_feeding_completed)
	visible = false
	
func start_feeding(player: Node2D, target: Node2D):
	player_ref = player
	target_ref = target
	
	# Position the effect between player and target
	global_position = (player.global_position + target.global_position) / 2
	
	# Size the blur rect to cover both entities
	var distance = player.global_position.distance_to(target.global_position)
	blur_rect.size = Vector2(distance + 80, 80)
	blur_rect.position = -blur_rect.size / 2
	
	# Position progress bar above
	progress_bar.position.y = -blur_rect.size.y / 2 - 30
	progress_bar.position.x = -progress_bar.size.x / 2
	
	# Reset progress
	feed_progress = 0.0
	progress_bar.value = 0.0
	
	# Calculate blood increase (20-30%)
	blood_increase = randf_range(20.0, 30.0)
	
	# Show effect
	visible = true
	
	# Start timer
	timer.wait_time = feed_duration
	timer.start()

func _process(delta):
	if visible:
		if player_ref and target_ref:
			# Update position to stay between player and target
			global_position = (player_ref.global_position + target_ref.global_position) / 2
			
			# Update progress
			feed_progress += delta / feed_duration
			progress_bar.value = feed_progress
			
			# If entities move too far apart, cancel feeding
			if player_ref.global_position.distance_to(target_ref.global_position) > 30:
				_cancel_feeding()
		else:
			_cancel_feeding()

func _on_feeding_completed():
	if player_ref and target_ref:
		# Increase blood level by 20-30%
		Global.blood_level = min(Global.blood_level + blood_increase, 100.0)
		
		# Emit completion signal
		emit_signal("feeding_completed")
		
		# Hide effect
		visible = false
		
		# Apply any additional effects to the target (could make them scared, etc.)
		if target_ref.has_method("scare"):
			target_ref.scare(player_ref)
	else:
		_cancel_feeding()

func _cancel_feeding():
	visible = false
	timer.stop()
