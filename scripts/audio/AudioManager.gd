# Gestor de efectos de sonido sintetizados procedimentalmente
class_name AudioManager
extends Node


@export var bus_name: StringName = &"Master"
@export var pool_size: int = 24 # 24 canales concurrentes para combate masivo

# Streams de audio sintetizados
var _click_stream: AudioStreamWAV
var _chest_stream: AudioStreamWAV
var _hit_stream: AudioStreamWAV
var _death_stream: AudioStreamWAV
var _level_up_stream: AudioStreamWAV
var _evolution_stream: AudioStreamWAV

# Canal de audio para efectos de nivel y evolucion
var _priority_player: AudioStreamPlayer
var _players_pool: Array[AudioStreamPlayer] = []
var _pool_index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_generate_all_sfx()
	_create_players_pool()


func _create_players_pool() -> void:
	_priority_player = AudioStreamPlayer.new()
	_priority_player.bus = bus_name
	_priority_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_priority_player)

	_players_pool.clear()
	for i in range(pool_size):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = bus_name
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_players_pool.append(player)


func _get_available_player() -> AudioStreamPlayer:
	for player in _players_pool:
		if not player.playing:
			return player

	var recycled: AudioStreamPlayer = _players_pool[_pool_index]
	_pool_index = (_pool_index + 1) % _players_pool.size()
	return recycled


func play_click(pitch_mod: float = 1.0) -> void:
	var final_pitch: float = clampf(pitch_mod, 0.6, 2.0)
	_play_stream(_click_stream, final_pitch, -4.0)


func play_chest() -> void:
	_play_stream(_chest_stream, 1.0, -3.0)


func play_hit() -> void:
	var pitch: float = randf_range(0.94, 1.06)
	_play_stream(_hit_stream, pitch, -5.0)


func play_slash() -> void:
	var pitch: float = randf_range(1.15, 1.35)
	_play_stream(_hit_stream, pitch, -4.0)


func play_explosion() -> void:
	var pitch: float = randf_range(0.68, 0.82)
	_play_stream(_hit_stream, pitch, -2.0)


func play_death() -> void:
	var pitch: float = randf_range(0.96, 1.08)
	_play_stream(_death_stream, pitch, -5.0)


func play_level_up() -> void:
	_play_priority(_level_up_stream, 1.0, -1.0)


func play_evolution() -> void:
	_play_priority(_evolution_stream, 1.0, 0.5)


func _play_stream(stream: AudioStreamWAV, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if stream == null or _players_pool.is_empty():
		return

	var player: AudioStreamPlayer = _get_available_player()
	player.stream = stream
	player.pitch_scale = maxf(0.2, pitch)
	player.volume_db = volume_db
	player.play()


func _play_priority(stream: AudioStreamWAV, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	if _priority_player != null:
		_priority_player.stream = stream
		_priority_player.pitch_scale = pitch
		_priority_player.volume_db = volume_db
		_priority_player.play()
	else:
		_play_stream(stream, pitch, volume_db)


# ==============================================================================
# SÍNTESIS DE ALTA CALIDAD ACÚSTICA (CÁLIDA, ORGÁNICA, SENOIDAL PURA)
# ==============================================================================

func _generate_all_sfx() -> void:
	# 1. Clic táctil de madera/burbuja suave (280Hz -> 180Hz senoidal pura)
	_click_stream = _synth_soft_thump_click(0.028)

	# 2. Cofre: Tintineo de monedas de oro / cristal suave (659Hz y 1046Hz resonantes)
	_chest_stream = _synth_coin_chime(0.32)

	# 3. Hit: Thud contundente a 90 Hz con presencia de graves y micro-impacto
	_hit_stream = _synth_warm_thud_hit(0.060)

	# 4. Muerte: Disipación de aire / vacío percusivo suave
	_death_stream = _synth_air_dissipation(0.12)

	# 5. Level Up: Acorde Do Mayor de celesta orquestal (C4-E4-G4-C5-E5)
	_level_up_stream = _synth_celesta_fanfare(0.42)

	# 6. Evolución: Acorde solemne y etéreo en Fa Mayor 9 orquestal profundo
	_evolution_stream = _synth_orchestral_evolution_chord(1.10)


func _synth_soft_thump_click(duration: float, s_rate: int = 22050) -> AudioStreamWAV:
	var count: int = int(duration * s_rate)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(count * 2)

	var attack_time: float = 0.0015
	var phase: float = 0.0

	for i in range(count):
		var t: float = float(i) / float(s_rate)
		
		# Envolvente suave: subida sin pop digital, caída exponencial natural
		var env: float = 0.0
		if t < attack_time:
			env = t / attack_time
		else:
			env = exp(-(t - attack_time) * 110.0)

		# Pitch bend descendente sutil y cálido: 290 Hz -> 175 Hz
		var cur_freq: float = lerpf(290.0, 175.0, minf(1.0, t * 70.0))
		phase += TAU * cur_freq * (1.0 / float(s_rate))

		# Seno puro cálido con micro armónico dulce (15%) emulando madera/teclado táctil
		var tone: float = sin(phase) + 0.15 * sin(phase * 2.0)
		var sample: float = tone * env * 0.95

		var s16: int = clampi(int(sample * 29000.0), -32768, 32767)
		bytes.encode_s16(i * 2, s16)

	return _create_wav(bytes, s_rate)


func _synth_coin_chime(duration: float, s_rate: int = 22050) -> AudioStreamWAV:
	var count: int = int(duration * s_rate)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(count * 2)

	# Dos notas de moneda: primera a t=0.0s, segunda a t=0.07s
	var coin1_time: float = 0.0
	var coin2_time: float = 0.075

	for i in range(count):
		var t: float = float(i) / float(s_rate)
		var sample: float = 0.0

		# Primera moneda (E5 659.25Hz + C6 1046.5Hz)
		if t >= coin1_time:
			var dt1: float = t - coin1_time
			var env1: float = exp(-dt1 * 14.0)
			var chime1: float = sin(TAU * 659.25 * dt1) * 0.6 + sin(TAU * 1046.50 * dt1) * 0.4
			sample += chime1 * env1 * 0.55

		# Segunda moneda (G5 783.99Hz + E6 1318.5Hz)
		if t >= coin2_time:
			var dt2: float = t - coin2_time
			var env2: float = exp(-dt2 * 12.0)
			var chime2: float = sin(TAU * 783.99 * dt2) * 0.6 + sin(TAU * 1318.51 * dt2) * 0.4
			sample += chime2 * env2 * 0.65

		var s16: int = clampi(int(sample * 27000.0), -32768, 32767)
		bytes.encode_s16(i * 2, s16)

	return _create_wav(bytes, s_rate)


func _synth_warm_thud_hit(duration: float, s_rate: int = 22050) -> AudioStreamWAV:
	var count: int = int(duration * s_rate)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(count * 2)

	var phase: float = 0.0

	for i in range(count):
		var t: float = float(i) / float(s_rate)
		# Envolvente percusiva con cuerpo
		var env: float = exp(-t * 52.0)

		# Caída de tono concentrada en el rango grave (135 Hz -> 72 Hz, pasando por 90 Hz)
		var pitch_decay: float = exp(-t * 65.0)
		var cur_freq: float = lerpf(72.0, 135.0, pitch_decay)
		phase += TAU * cur_freq * (1.0 / float(s_rate))

		var thud: float = sin(phase)

		# Micro-chasquido orgánico en los primeros 3.5ms (atenuado y filtrado)
		var micro_tap: float = 0.0
		if t < 0.0035:
			micro_tap = randf_range(-0.25, 0.25) * (1.0 - t / 0.0035)

		var sample: float = (thud * 0.85 + micro_tap * 0.15) * env
		var s16: int = clampi(int(sample * 29000.0), -32768, 32767)
		bytes.encode_s16(i * 2, s16)

	return _create_wav(bytes, s_rate)


func _synth_air_dissipation(duration: float, s_rate: int = 22050) -> AudioStreamWAV:
	var count: int = int(duration * s_rate)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(count * 2)

	var phase: float = 0.0

	for i in range(count):
		var t: float = float(i) / float(s_rate)
		var progress: float = t / duration

		# Caída de frecuencia suave y redondeada: 220 Hz -> 55 Hz
		var cur_freq: float = lerpf(220.0, 55.0, pow(progress, 0.6))
		phase += TAU * cur_freq * (1.0 / float(s_rate))

		# Envolvente en campana suave
		var env: float = (1.0 - progress) * (1.0 - pow(progress, 1.8))
		var tone: float = sin(phase) * 0.75
		
		# Suave nube de aire atenuada
		var air: float = randf_range(-0.2, 0.2) * exp(-t * 24.0)

		var sample: float = (tone + air) * env * 0.8
		var s16: int = clampi(int(sample * 27000.0), -32768, 32767)
		bytes.encode_s16(i * 2, s16)

	return _create_wav(bytes, s_rate)


func _synth_celesta_fanfare(duration: float, s_rate: int = 22050) -> AudioStreamWAV:
	var count: int = int(duration * s_rate)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(count * 2)

	var notes: Array = [
		{"time": 0.00, "freq": 261.63, "weight": 0.5}, # C4
		{"time": 0.07, "freq": 329.63, "weight": 0.5}, # E4
		{"time": 0.14, "freq": 392.00, "weight": 0.6}, # G4
		{"time": 0.20, "freq": 523.25, "weight": 0.8}, # C5 (Acorde pleno)
		{"time": 0.20, "freq": 659.25, "weight": 0.6}, # E5
		{"time": 0.20, "freq": 783.99, "weight": 0.5}, # G5
	]

	for i in range(count):
		var t: float = float(i) / float(s_rate)
		var sample: float = 0.0

		for n in notes:
			var note_time: float = n["time"]
			if t >= note_time:
				var dt: float = t - note_time
				var env: float = exp(-dt * 7.5)
				var freq: float = n["freq"]
				var weight: float = n["weight"]
				# Senoidal pura + 2do armónico sutil (timbre celesta de concierto)
				var tone: float = sin(TAU * freq * dt) * 0.8 + sin(TAU * freq * 2.0 * dt) * 0.2
				sample += tone * env * weight * 0.35

		var s16: int = clampi(int(sample * 28000.0), -32768, 32767)
		bytes.encode_s16(i * 2, s16)

	return _create_wav(bytes, s_rate)


func _synth_orchestral_evolution_chord(duration: float, s_rate: int = 22050) -> AudioStreamWAV:
	var count: int = int(duration * s_rate)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(count * 2)

	# Frecuencias consonantes del acorde Fa Mayor 9
	var chord_freqs: Array[float] = [
		87.31,   # F2 (Bajo profundo de sala)
		130.81,  # C3 (Quinta base orquestal)
		174.61,  # F3 (Tónica media)
		220.00,  # A3 (Tercera mayor cálida)
		261.63,  # C4 (Quinta)
		329.63,  # E4 (Séptima mayor etérea)
		392.00,  # G4 (Novena luminosa)
		523.25   # C5 (Cúspide de celesta)
	]

	var attack_time: float = 0.09 # Swell orquestal suave

	for i in range(count):
		var t: float = float(i) / float(s_rate)

		# Envolvente sinfónica: crescendo suave de sala, decaimiento largo y cálido
		var env: float = 0.0
		if t < attack_time:
			env = t / attack_time
		else:
			env = exp(-(t - attack_time) * 2.4)

		var chord_sum: float = 0.0
		for idx in range(chord_freqs.size()):
			var f: float = chord_freqs[idx]
			var phase: float = TAU * f * t
			# Las notas graves tienen más amplitud que las agudas (equilibrio psicoacústico)
			var weight: float = 1.0 - (float(idx) / float(chord_freqs.size())) * 0.4
			chord_sum += sin(phase) * weight

		var sample: float = (chord_sum / float(chord_freqs.size())) * env * 1.3
		var s16: int = clampi(int(sample * 29000.0), -32768, 32767)
		bytes.encode_s16(i * 2, s16)

	return _create_wav(bytes, s_rate)


func _create_wav(bytes: PackedByteArray, s_rate: int) -> AudioStreamWAV:
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = s_rate
	wav.stereo = false
	wav.data = bytes
	return wav
