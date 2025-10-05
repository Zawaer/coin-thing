extends Node

signal rapid_fire_unlocked_signal

var rapid_fire_unlocked: bool = false

func unlock_rapid_fire():
	if rapid_fire_unlocked:
		return
	rapid_fire_unlocked = true
	emit_signal("rapid_fire_unlocked_signal")
