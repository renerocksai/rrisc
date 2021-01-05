extends Node2D

onready var button = $Button
onready var video = $VideoPlayer



# Called when the node enters the scene tree for the first time.
func _ready():
    video.stream_position = 1.0





func _on_Button_pressed():
    video.stop()
    video.play()



func _on_TouchScreenButton_pressed():
    print("Touch!")
    video.stop()
    video.play()

