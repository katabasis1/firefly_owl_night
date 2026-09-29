class_name Tutorial
extends Path2D
## Обучающая «рука»: показывает, как вести линию. Маршрут — кривая этого Path2D
## (правится прямо в редакторе). Пока рука ведёт линию, лес «проигрывает» будущее:
## сигнал time_changed сообщает главной сцене время на кончике показанной линии.

signal time_changed(t: float)

const WORLD_SPEED := 260.0  ## как Main.SPEED: px линии -> секунды леса

## true — обучение (показывается само), false — подсказка (включается кнопкой-лампочкой).
@export var auto_play: bool = true
@export var hand_speed: float = 340.0
@export var start_delay: float = 0.9

@onready var hand: Node2D = $Hand
@onready var trail: Line2D = $Trail
@onready var trail_glow: Line2D = $TrailGlow
@onready var tap: Node2D = $Tap

enum Phase { IDLE, APPEAR, PRESS, MOVE, HOLD, FADE, WAIT }

var phase: Phase = Phase.IDLE
var active := false
var _pt := 0.0      ## время в текущей фазе
var _dist := 0.0
var _length := 0.0
var _last_trail := -999.0
var _times: PackedFloat32Array = PackedFloat32Array()   ## время леса на каждые SAMPLE px маршрута
const SAMPLE: float = 6.0


func _ready() -> void:
    _length = curve.get_baked_length() if curve else 0.0
    _hide_all()


func _hide_all() -> void:
    hand.visible = false
    tap.visible = false
    trail.clear_points()
    trail_glow.clear_points()
    trail.modulate.a = 1.0
    trail_glow.modulate.a = 1.0


## Запустить показ заново (кнопка подсказки).
func replay() -> void:
    active = false
    set_active(true)
    _pt = -0.2


func set_active(on: bool) -> void:
    if on == active:
        return
    active = on and _length > 0.0
    _hide_all()
    if active and _times.is_empty():
        _build_times()
    if active:
        _enter(Phase.WAIT)
        _pt = -start_delay
    else:
        phase = Phase.IDLE


## Время леса вдоль маршрута с учётом паутины (как у настоящей линии).
func _build_times() -> void:
    var lvl: Level = get_parent() as Level
    var t: float = 0.0
    _times.append(0.0)
    var d: float = SAMPLE
    while d < _length + SAMPLE:
        var rate: float = 1.0
        if lvl != null:
            rate = lvl.time_rate(to_global(curve.sample_baked(minf(d, _length))))
        t += SAMPLE / WORLD_SPEED * rate
        _times.append(t)
        d += SAMPLE


func _time_at(dist: float) -> float:
    if _times.size() < 2:
        return dist / WORLD_SPEED
    var f: float = dist / SAMPLE
    var i: int = clampi(int(f), 0, _times.size() - 2)
    return lerpf(_times[i], _times[i + 1], clampf(f - float(i), 0.0, 1.0))


func _enter(p: Phase) -> void:
    phase = p
    _pt = 0.0


func _process(delta: float) -> void:
    if not active:
        return
    _pt += delta
    match phase:
        Phase.WAIT:
            if _pt >= 0.5:
                _dist = 0.0
                _last_trail = -999.0
                trail.clear_points()
                trail_glow.clear_points()
                trail.modulate.a = 1.0
                trail_glow.modulate.a = 1.0
                time_changed.emit(0.0)
                hand.visible = true
                hand.position = curve.sample_baked(0.0)
                _enter(Phase.APPEAR)
        Phase.APPEAR:
            var k: float = minf(_pt / 0.35, 1.0)
            hand.modulate.a = k
            hand.scale = Vector2.ONE * lerpf(1.35, 1.0, ease(k, 0.4))
            if k >= 1.0:
                _enter(Phase.PRESS)
        Phase.PRESS:
            var k: float = minf(_pt / 0.22, 1.0)
            hand.scale = Vector2.ONE * lerpf(1.0, 0.86, k)
            tap.visible = true
            tap.position = hand.position
            tap.scale = Vector2.ONE * lerpf(0.4, 1.4, k)
            tap.modulate.a = 1.0 - k
            if k >= 1.0:
                tap.visible = false
                _enter(Phase.MOVE)
        Phase.MOVE:
            _dist = minf(_dist + hand_speed * delta, _length)
            var p: Vector2 = curve.sample_baked(_dist)
            hand.position = p
            if _dist - _last_trail >= 10.0 or _dist >= _length:
                trail.add_point(p)
                trail_glow.add_point(p)
                _last_trail = _dist
            time_changed.emit(_time_at(_dist))
            if _dist >= _length:
                _enter(Phase.HOLD)
        Phase.HOLD:
            if _pt >= 0.35:
                _enter(Phase.FADE)
        Phase.FADE:
            var k: float = minf(_pt / 0.45, 1.0)
            hand.modulate.a = 1.0 - k
            hand.scale = Vector2.ONE * lerpf(0.86, 1.2, k)
            trail.modulate.a = 1.0 - k
            trail_glow.modulate.a = 1.0 - k
            if k >= 1.0:
                _hide_all()
                time_changed.emit(0.0)
                _enter(Phase.WAIT)
