extends Node

onready var fps_label = $UI/fps_label

func _ready():
	set_process(true)

func _process(delta):
	fps_label.set_text(str(Engine.get_frames_per_second()))
