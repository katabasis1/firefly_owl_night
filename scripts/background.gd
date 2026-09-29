extends Node2D
## Живой фон: дрейфующий туман и мерцающая луна.

@onready var fog1: Node2D = $Fog1
@onready var fog2: Node2D = $Fog2
@onready var moon_glow: Node2D = $MoonGlow
@onready var pollen: CPUParticles2D = $Pollen
@onready var fireflies: CPUParticles2D = $Fireflies

var _t := 0.0


func _process(delta: float) -> void:
    var k: float = WorldClock.scale
    _t += delta * k
    # Время остановлено — пыльца и светлячки фона почти замирают.
    pollen.speed_scale = maxf(k, 0.03)
    fireflies.speed_scale = maxf(k, 0.03)
    fog1.position.x = 360.0 + sin(_t * 0.12) * 120.0
    fog2.position.x = 360.0 + sin(_t * 0.09 + 2.0) * 160.0
    moon_glow.modulate.a = 0.32 + 0.08 * sin(_t * 0.8)
