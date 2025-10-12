extends Control


@export var parent_screen : MenuScreen

var preview_player : AudioStreamPlayer ## Skin preview audio stream player node
var preview_tween : Tween = null ## Tween used for controlling skin preview audio player volume


## Stops skin preview
func _stop_skin_preview() -> void:
	if preview_tween : preview_tween.kill()
	preview_tween = create_tween()
	
	if is_music_playing: preview_tween.parallel().tween_property(music_player,"volume_db",0.0,1.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	
	preview_tween.parallel().tween_property(preview_player,"volume_db",-40.0,1.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	preview_tween.tween_callback(preview_player.stop)


## Starts skin preview with given audio sample
func _start_skin_preview(sample : AudioStream) -> void:
	if not Player.config.audio["skin_preview"] : return
	
	preview_player.stream = sample
	preview_player.play()
	
	if preview_tween : preview_tween.kill()
	preview_tween = create_tween()
	
	if is_music_playing : preview_tween.parallel().tween_property(music_player,"volume_db",-40.0,1.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	preview_tween.parallel().tween_property(preview_player,"volume_db",0.0,1.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
