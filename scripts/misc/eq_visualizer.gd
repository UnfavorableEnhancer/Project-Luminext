# Project Luminext - an advanced open-source Lumines spiritual successor
# Copyright (C) <2024-2025> <unfavorable_enhancer>
# Contact : <random.likes.apes@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.


extends Node2D

##-----------------------------------------------------------------------
## Visualises master bus audio frequencies amplitudes
##-----------------------------------------------------------------------

enum MAGNITUDE {AVERAGE, MAX}

const FREQ : Array[float] = [50,75,100,125,150,200,300,400,500,600,700,800,900,1000,1100,1200,1400] ## All frequencies to scan
const MULTIPLYER : Array[float] = [4,4,4,4,8,8,8,16,16,64,64,64,64,128,128,128,128]

const UPDATE_FREQ : float = 1.0 / 60.0 ## Update frequency
const INTERPOLATION : float = 0.35

var prev_energy : Array[float] = [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]

var spectrum : AudioEffectSpectrumAnalyzerInstance


func _ready() -> void:
	spectrum = AudioServer.get_bus_effect_instance(0,0)
	$Timer.start(UPDATE_FREQ)


func _on_Timer_timeout() -> void:
	if not AudioServer.is_bus_effect_enabled(0,0): 
		visible = false
		return
	
	visible = true
	
	for num : int in 16:
		var stick : TextureRect = get_node("stik" + str(num + 1))
		var magnitude : float = snappedf(spectrum.get_magnitude_for_frequency_range(FREQ[num], FREQ[num+1], AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE).length_squared(),0.001)
		#var energy : float = -1 * (linear_to_db(clampf(1.0 - magnitude * MULTIPLYER, 0.0, 1.0)) / DELIMETER)

		var energy : float = -1 * linear_to_db(clampf(1.0 - magnitude * MULTIPLYER[num], 0.0, 1.0))

		energy = lerp(prev_energy[num], energy, INTERPOLATION)
		stick.size.y = clampf(energy * 654.0 + 26.0, 26.0, 680.0)
		prev_energy[num] = energy
