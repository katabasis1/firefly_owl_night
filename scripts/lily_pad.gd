@tool
class_name LilyPad
extends Bush
## Кувшинка: прячет светлячка, пока она на поверхности. По таймеру уходит под воду.
## Цикл: [0, up) — на поверхности, [up, period) — под водой.

const SINK: float = 0.35   ## длительность погружения/всплытия (только анимация)

@export var period: float = 4.0
@export var up: float = 2.5
@export var offset: float = 0.0

@onready var ripples: Node2D = $Ripples


func surfaced(t: float) -> bool:
    return fposmod(t + offset, period) < up


func hides(p: Vector2, t: float) -> bool:
    return surfaced(t) and contains(p)


## 1 — на поверхности, 0 — под водой; плавно на краях цикла.
func _float_amount(t: float) -> float:
    var u: float = fposmod(t + offset, period)
    if u < up:
        return clampf(minf(u, up - u) / SINK + 0.35, 0.0, 1.0)
    return 0.0


func set_time(t: float) -> void:
    if not is_node_ready():
        return
    var k: float = _float_amount(t)
    var s: float = radius / 90.0
    visual.scale = Vector2.ONE * s * lerpf(0.55, 1.0, k)
    visual.modulate.a = lerpf(0.0, 1.0, k)
    # за 0.6 с до всплытия — круги на воде
    var u: float = fposmod(t + offset, period)
    var until_up: float = period - u
    ripples.visible = u >= up and until_up < 0.8
    ripples.scale = Vector2.ONE * s * (1.2 - until_up)
    ripples.modulate.a = 1.0 - until_up / 0.8
