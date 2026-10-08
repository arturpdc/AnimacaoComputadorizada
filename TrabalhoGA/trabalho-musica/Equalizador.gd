
extends Node3D

@export var barras: MeshInstance3D
@export var sensibilidade_db: float = -60.0
@export var volume_maximo_db: float = -20.0
@export var velocidade: float = 12.0

const FREQUENCIAS = [
	Vector2(40, 80),
	Vector2(80, 160),
	Vector2(160, 320),
	Vector2(320, 640),
	Vector2(640, 1000),
	Vector2(1000, 1600),
	Vector2(1600, 2500),
	Vector2(2500, 4000),
	Vector2(4000, 6000),
	Vector2(6000, 10000)
]

var analisador: AudioEffectSpectrumAnalyzerInstance
var valores: Array[float] = []


func _ready() -> void:
	if barras == null or barras.mesh == null:
		push_error("Conecte o MeshInstance3D das barras no Inspector.")
		set_process(false)
		return

	if barras.mesh.get_blend_shape_count() < 10:
		push_error("A malha precisa possuir 10 Blend Shapes.")
		set_process(false)
		return

	var bus_id: int = AudioServer.get_bus_index("Mic")

	if bus_id == -1:
		push_error("Barramento Mic nao encontrado.")
		set_process(false)
		return

	var efeito: AudioEffectSpectrumAnalyzer = AudioServer.get_bus_effect(
		bus_id, 0
	) as AudioEffectSpectrumAnalyzer

	if efeito == null:
		push_error("SpectrumAnalyzer nao encontrado no barramento Mic.")
		set_process(false)
		return

	analisador = AudioServer.get_bus_effect_instance(
		bus_id, 0
	) as AudioEffectSpectrumAnalyzerInstance

	if analisador == null:
		push_error("Nao foi possivel acessar o analisador.")
		set_process(false)
		return

	for i in range(10):
		valores.append(0.0)
		barras.set_blend_shape_value(i, 0.0)

	print("Equalizador iniciado com sucesso!")


func _process(delta: float) -> void:
	for i in range(10):
		var faixa: Vector2 = FREQUENCIAS[i]

		var magnitude: Vector2 = analisador.get_magnitude_for_frequency_range(
			faixa.x,
			faixa.y,
			AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX
		)

		var energia: float = (magnitude.x + magnitude.y) * 0.5

		var intensidade_db: float = linear_to_db(
			maxf(energia, 0.000001)
		)

		var objetivo: float = clampf(
			inverse_lerp(
				sensibilidade_db,
				volume_maximo_db,
				intensidade_db
			),
			0.0,
			1.0
		)

		var fator: float = 1.0 - exp(-velocidade * delta)

		valores[i] = lerpf(
			valores[i],
			objetivo,
			fator
		)

		barras.set_blend_shape_value(i, valores[i])
