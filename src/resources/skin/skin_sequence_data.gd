# Project Luminext - an ultimate block-stacking puzzle game
# Copyright (C) <2024-2026> <unfavorable_enhancer>
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

##
## Contains all sequence tracks which define skin music and background scenery animation playback.[br]
## Each track consists of several "samples" (each sample = 2 music bars), length of which depends on current BPM and time signature value.[br]
## There's always a single "master" track which defines playback rules and selects current "segment", which changes used by skin blocks, sfx and visual effects.
##
class_name SkinSequenceData

signal sample_length_updated(sample_length : float)

## Beats per minute (defines bar lenght)
var bpm : float = 120.0: 
	set(value): bpm = snappedf(value, 0.001); _update_sample_length()

## Amount of beats per bar (upper part of time signature notation)
var time_signature_upper : int = 4: 
	set(value): time_signature_upper = clamp(value, 1, 1000); _update_sample_length()

## Beat length (lower part of time signature notation)
var time_signature_lower : int = 4: 
	set(value): time_signature_lower = clamp(nearest_po2(value), 2, 128); _update_sample_length()

var sample_length : float = 2.0 ## Result sample length, which is equal to 2 music bars. Defines default animation lenghts.

## All tracks inside this sequence
var tracks : Dictionary[StringName, SequenceTrack] = {
	&"master" : MasterTrack.new()
	# track name : track instance
}

## Called when BPM or time signature is changed and updates sample length
func _update_sample_length() -> void:
	sample_length =  (480 / bpm) * (time_signature_upper / time_signature_lower)
	sample_length_updated.emit(sample_length)


## Returns array of all tracks samples at given position.
func get_samples_at_position(position : float) -> Array[SequenceSample]:
	var samples : Array[SequenceSample] = []
	
	for track : SequenceTrack in tracks.values():
		var sample : SequenceSample = track.get_sample_at_position(position)
		if sample == null : continue
		samples.append(sample)
	
	return []


## Loads required skin audio assets and animations into exsisting audio and animation tracks samples
func load_tracks_assets(asset_data : SkinAssetData, animation_data : SkinAnimationData) -> bool:
	for track : SequenceTrack in tracks.values():
		if track is AudioTrack : if not track.load_audio_assets(asset_data): return false
		elif track is AnimationTrack : if not track.load_animations(animation_data): return false
	
	return true

## Loads sequence data from passed FileAccess, which has valid skin file opened.
func load(file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK

## Saves sequence data to passed FileAccess, which has valid skin file opened.
func save(file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK



@abstract class SequenceSample:
	var parent_track : SequenceTrack ## Track which contains this bar
	var position : float = 0.0 ## Position on parent track
	var length : float = 1.0 ## Length of this sample


@abstract class SequenceTrack:
	var parent_sequence : SkinSequenceData ## Parent sequence data
	
	## Contains all animation samples
	var track : Dictionary[float, SequenceSample] = {
		# sample_position : sample
	}
	
	## Loads track from passed FileAccess, which has valid skin file opened
	@abstract func load(file : FileAccess) -> SkinConsts.IO_ERROR
	## Saves track to passed FileAccess, which has valid skin file opened
	@abstract func save(file : FileAccess) -> SkinConsts.IO_ERROR
	
	## Returns nearest sample at passed position (with rounding downwards).
	func get_sample_at_position(target_position : float) -> SequenceSample:
		var positions : Array = track.keys()
		positions.sort()
		
		for position : float in positions:
			if position >= target_position:
				return track[position]
		
		return null


## Master track defines skin playback rules and selects current segment, which defines currently used blocks, sfx and effects.
class MasterTrack extends SequenceTrack:
	## Loads master track from passed FileAccess, which has valid skin file opened.
	func load(file : FileAccess) -> SkinConsts.IO_ERROR: 
		return SkinConsts.IO_ERROR.OK
	
	## Saves master track to passed FileAccess, which has valid skin file opened.
	func save(file : FileAccess) -> SkinConsts.IO_ERROR:
		return SkinConsts.IO_ERROR.OK
	
	class Sample extends SequenceSample:
		var playback_mode : SkinConsts.PLAYBACK_STATE = SkinConsts.PLAYBACK_STATE.CONTINUE ## Current sample playback state
		var segment_id : int = 0 ## Current sample skin segment


## Audio track contains music samples which are played on skin playback.
class AudioTrack extends SequenceTrack:
	## Loads audio track from passed FileAccess, which has valid skin file opened.
	func load(file : FileAccess) -> SkinConsts.IO_ERROR: 
		return SkinConsts.IO_ERROR.OK
	
	## Saves audio track to passed FileAccess, which has valid skin file opened.
	func save(file : FileAccess) -> SkinConsts.IO_ERROR:
		return SkinConsts.IO_ERROR.OK
	
	## Loads required skin audio assets into own samples
	func load_audio_assets(asset_data : SkinAssetData) -> bool:
		for sample : Sample in track.values():
			if asset_data.audio.has(sample.animation_uid):
				sample.audio_asset = asset_data.audio[sample.audio_asset_uid]
			else:
				return false
		
		return true
	
	class Sample extends SequenceSample:
		var audio_asset_uid : StringName = &"" ## Audio asset UID this music sample uses
		## Audio asset this music sample uses
		var audio_asset : ModdableAsset.AudioAsset = null: 
			set(value) : audio_asset = value; length = value.stream.get_length()
		
		var volume : float = 0.0 ## Music sample volume in db
		var pitch : float = 0.0 ## Music sample pitch scale


## Animation track contains background scenery animations which are played on skin playback
class AnimationTrack extends SequenceTrack:
	## Loads animation track from passed FileAccess, which has valid skin file opened.
	func load(file : FileAccess) -> SkinConsts.IO_ERROR: 
		return SkinConsts.IO_ERROR.OK
	
	## Saves animation track to passed FileAccess, which has valid skin file opened.
	func save(file : FileAccess) -> SkinConsts.IO_ERROR:
		return SkinConsts.IO_ERROR.OK

	## Loads required skin animations into own samples
	func load_animations(animation_data : SkinAnimationData) -> bool:
		for sample : Sample in track.values():
			if animation_data.animations.has(sample.animation_uid):
				sample.animation = animation_data.animations[sample.animation_uid]
			else:
				return false
		
		return true
	
	class Sample extends SequenceSample:
		var animation_uid : StringName = &"" ## Animation UID this sample uses
		## Animation this sample uses
		var animation : Animation = null: 
			set(value) : animation = value; length = value.get_length()


## Tween track modifyes single node property on skin playback
class TweenTrack extends SequenceTrack:
	## Loads tween track from passed FileAccess, which has valid skin file opened.
	func load(file : FileAccess) -> SkinConsts.IO_ERROR: 
		return SkinConsts.IO_ERROR.OK
	
	## Saves tween track to passed FileAccess, which has valid skin file opened.
	func save(file : FileAccess) -> SkinConsts.IO_ERROR:
		return SkinConsts.IO_ERROR.OK

	class Sample extends SequenceSample:
		var target_node_path : NodePath
		var target_property_name : StringName
		var target_value : Variant
		var ease_type : Tween.EaseType
		var trans_type : Tween.TransitionType
