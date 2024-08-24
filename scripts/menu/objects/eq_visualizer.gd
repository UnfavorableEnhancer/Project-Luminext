extends Node2D

enum MAGNITUDE {AVERAGE, MAX}

const FREQ : Array[float] = [16,31.5,63,125,200,300,400,500,600,800,1000,1100,1200,1300,1400,1500,1600] # All frequencies to scan
const DELIMETER : int = 200 # Devides converted to db amplitude which makes result energy to display
const MULTIPLYER : int = 1500 # Multiplyes raw amplitude before converting to db
const UPDATE_FREQ : float = 0.01 # Update frequency
const ANIMATION_SPEED : float = 0.1 # Sticks animation speed

var spectrum : AudioEffectSpectrumAnalyzerInstance


func _ready() -> void:
	spectrum = AudioServer.get_bus_effect_instance(0,0)
	$Timer.start(UPDATE_FREQ)


func _on_Timer_timeout() -> void:
	if AudioServer.is_bus_effect_enabled(0,0): 
		visible = true
	else: 
		visible = false
		return
	
	var tween : Tween = create_tween().set_parallel(true)
	
	for num : int in 16:
		var stick : TextureRect = get_node("stik" + str(num+1))
		var magnitude : float = snappedf(spectrum.get_magnitude_for_frequency_range(FREQ[num], FREQ[num+1], AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX).length_squared(),0.00001)
		var energy : float = -1 * (linear_to_db(clampf(1.0 - magnitude * MULTIPLYER,0.0,1.0)) / DELIMETER)
		
		tween.tween_property(stick,"size:y",clampf(energy * 654.0 + 26.0,26.0,680.0),ANIMATION_SPEED) 
