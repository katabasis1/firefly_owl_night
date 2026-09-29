@tool
class_name Frog
extends Node2D
## Лягушка: по таймеру выстреливает языком в направлении angle.
## Всё зависит только от времени t, поэтому предпросмотр будущего точный.

const MOUTH: float = 26.0      ## расстояние от центра до рта
const TONGUE_R: float = 16.0   ## «толщина» опасной зоны языка
const WARN: float = 0.5        ## за сколько секунд до выстрела раздувается горло

@export_range(-180.0, 360.0) var angle: float = 0.0:
    set(v):
        angle = v
        _refresh()
@export var reach: float = 380.0:
    set(v):
        reach = v
        _refresh()
@export var period: float = 2.4    ## длина цикла, с
@export var active: float = 0.7    ## сколько длится выстрел (язык туда и обратно), с
@export var offset: float = 0.0    ## сдвиг цикла, с

@onready var body: Node2D = $Body
@onready var flip: Node2D = $Body/Flip
@onready var sac: Node2D = $Body/Flip/Sac
@onready var tongue: Line2D = $Tongue
@onready var tip: Node2D = $Tip
@onready var aim: Line2D = $Aim

var _t: float = 0.0


func _ready() -> void:
    _t = randf() * 5.0
    _refresh()
    set_time(0.0)


func _dir() -> Vector2:
    return Vector2.from_angle(deg_to_rad(angle))


func _refresh() -> void:
    if not is_node_ready():
        return
    body.rotation = deg_to_rad(angle)
    # глаза всегда сверху: если лягушка смотрит влево, отражаем её по вертикали
    flip.scale = Vector2(1.0, -1.0 if cos(deg_to_rad(angle)) < 0.0 else 1.0)
    var d: Vector2 = _dir()
    aim.points = PackedVector2Array([d * MOUTH, d * (MOUTH + reach)])


func tongue_length(t: float) -> float:
    var u: float = fposmod(t + offset, period)
    if u >= active:
        return 0.0
    return reach * sin(PI * u / active)


func hits(p: Vector2, t: float) -> bool:
    var ln: float = tongue_length(t)
    if ln <= 8.0:
        return false
    var d: Vector2 = _dir()
    var m: Vector2 = global_position + d * MOUTH
    var s: float = clampf((p - m).dot(d), 0.0, ln)
    return p.distance_to(m + d * s) < TONGUE_R


func set_time(t: float) -> void:
    var ln: float = tongue_length(t)
    var d: Vector2 = _dir()
    tongue.visible = ln > 1.0
    tip.visible = ln > 1.0
    tongue.points = PackedVector2Array([d * MOUTH * 0.6, d * (MOUTH + ln)])
    tip.position = d * (MOUTH + ln)
    var u: float = fposmod(t + offset, period)
    var warn: float = 0.0
    if u >= active:
        warn = clampf(1.0 - (period - u) / WARN, 0.0, 1.0)
    sac.scale = Vector2.ONE * (1.0 + 0.7 * warn)
    aim.modulate.a = 0.25 + 0.75 * warn


func alert() -> void:
    var tw: Tween = create_tween()
    tw.tween_property(body, "scale", Vector2(1.3, 0.8), 0.08)
    tw.tween_property(body, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
    if Engine.is_editor_hint():
        return
    _t += delta * WorldClock.scale
    flip.position.y = sin(_t * 3.2) * 1.2
