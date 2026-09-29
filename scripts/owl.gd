@tool
class_name Owl
extends Node2D
## Сова-страж. Всё её поведение — чистая функция от времени t,
## поэтому предпросмотр во время рисования в точности совпадает с полётом.
## Скрипт @tool: конус взгляда виден и настраивается прямо в редакторе.

const CALM := Color(1.0, 0.87, 0.45)
const ALARM := Color(1.0, 0.22, 0.3)

@export_group("Взгляд")
## Базовое направление взгляда в градусах (0 — вправо, 90 — вниз).
@export_range(-180.0, 360.0) var base_angle: float = 90.0:
    set(v):
        base_angle = v
        _refresh(false)
## Амплитуда поворота головы (градусы). 0 — сова смотрит в одну точку.
@export_range(0.0, 180.0) var sweep: float = 0.0:
    set(v):
        sweep = v
        _refresh(false)
## Период поворота головы (сек).
@export var period: float = 4.0
@export_range(0.0, 1.0) var phase: float = 0.0:
    set(v):
        phase = v
        _refresh(false)
@export var view_range: float = 420.0:
    set(v):
        view_range = v
        _refresh(true)
@export_range(10.0, 170.0) var view_fov: float = 50.0:
    set(v):
        view_fov = v
        _refresh(true)
@export_group("Сон")
## Сколько секунд сова спит в цикле (0 — никогда не спит).
@export var sleep_time: float = 0.0
@export var awake_time: float = 3.0
@export var cycle_offset: float = 0.0

@onready var cone: Node2D = $Cone
@onready var cone_fill: Polygon2D = $Cone/Fill
@onready var cone_edge: Line2D = $Cone/Edge
@onready var body: Node2D = $Body
@onready var eyes: Node2D = $Body/Eyes
@onready var pupils: Node2D = $Body/Eyes/Pupils
@onready var eyes_closed: Node2D = $Body/EyesClosed
@onready var eye_glow: Node2D = $Body/EyeGlow
@onready var zzz: Label = $Zzz
@onready var alert_label: Label = $Alert

var _alarm := false
var _idle := 0.0


func _ready() -> void:
    _build_cone()
    _apply_color(CALM, 0.3)
    alert_label.visible = false
    _idle = randf() * 10.0
    set_time(0.0)


func _refresh(rebuild: bool) -> void:
    if not is_node_ready():
        return
    if rebuild:
        _build_cone()
    set_time(0.0)


func _build_cone() -> void:
    var poly := PackedVector2Array()
    var cols: PackedColorArray = PackedColorArray()
    var edge := PackedVector2Array()
    poly.append(Vector2.ZERO)
    cols.append(Color(1, 1, 1, 0.55))
    edge.append(Vector2.ZERO)
    var half: float = deg_to_rad(view_fov) * 0.5
    var n := 28
    for i in n + 1:
        var a: float = -half + 2.0 * half * float(i) / float(n)
        var p: Vector2 = Vector2.from_angle(a) * view_range
        poly.append(p)
        cols.append(Color(1, 1, 1, 0.05))
        edge.append(p)
    edge.append(Vector2.ZERO)
    cone_fill.polygon = poly
    cone_fill.vertex_colors = cols
    cone_edge.points = edge


func _process(delta: float) -> void:
    if Engine.is_editor_hint():
        return
    _idle += delta * WorldClock.scale
    var b: float = 0.018 * sin(_idle * 2.2)
    body.scale = Vector2(1.0 + b, 1.0 - b)
    if zzz.visible:
        zzz.position.y = -110.0 + sin(_idle * 2.0) * 6.0
        zzz.modulate.a = 0.65 + 0.35 * sin(_idle * 3.0)


# ------------------------------------------------ поведение как функция времени

func angle_at(t: float) -> float:
    var a: float = base_angle
    if sweep != 0.0 and period > 0.0:
        a += sweep * sin(TAU * (t / period + phase))
    return deg_to_rad(a)


func _local(t: float) -> float:
    return fposmod(t + cycle_offset, sleep_time + awake_time)


func is_awake(t: float) -> bool:
    return sleep_time <= 0.0 or _local(t) >= sleep_time


## 0 — спит, 1 — бодрствует; за 0.6 с до пробуждения конус проступает как предупреждение.
func awake_amount(t: float) -> float:
    if is_awake(t):
        return 1.0
    var left: float = sleep_time - _local(t)
    if left < 0.6:
        return 0.35 * (1.0 - left / 0.6)
    return 0.0


func eye_pos() -> Vector2:
    return cone.global_position


func sees(p: Vector2, t: float) -> bool:
    if not is_awake(t):
        return false
    var d: Vector2 = p - eye_pos()
    if d.length() > view_range:
        return false
    var look: float = angle_at(t) + global_rotation
    return absf(angle_difference(d.angle(), look)) <= deg_to_rad(view_fov) * 0.5


func set_time(t: float) -> void:
    var a: float = angle_at(t)
    cone.rotation = a
    pupils.position = Vector2.from_angle(a) * 5.0
    var amount: float = awake_amount(t)
    cone.modulate.a = amount
    var awake: bool = is_awake(t)
    eyes.visible = awake
    eye_glow.visible = awake
    eyes_closed.visible = not awake
    zzz.visible = not awake and amount <= 0.0


# ------------------------------------------------ визуальные реакции

func _apply_color(c: Color, edge_alpha: float) -> void:
    cone_fill.color = c
    cone_edge.default_color = Color(c, edge_alpha)


func set_alarm(on: bool) -> void:
    if on == _alarm:
        return
    _alarm = on
    _apply_color(ALARM if on else CALM, 0.5 if on else 0.3)
    var tw: Tween = create_tween()
    tw.tween_property(eyes, "scale", Vector2.ONE * (1.25 if on else 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func alert() -> void:
    set_alarm(true)
    alert_label.visible = true
    alert_label.pivot_offset = alert_label.size * 0.5
    alert_label.scale = Vector2.ZERO
    var tw: Tween = create_tween()
    tw.tween_property(alert_label, "scale", Vector2.ONE * 1.4, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tw.tween_property(alert_label, "scale", Vector2.ONE, 0.15)
    var hop: Tween = create_tween()
    hop.tween_property(body, "position:y", -16.0, 0.1).set_ease(Tween.EASE_OUT)
    hop.tween_property(body, "position:y", 0.0, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
