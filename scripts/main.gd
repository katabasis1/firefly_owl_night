extends Node
## Главная сцена: состояния игры, рисование линии и проигрывание полёта.
##
## ФИШКА: время в лесу идёт ТОЛЬКО пока растёт линия (механика из шутера Superhot).
## Пока ведёшь палец, ты видишь будущее: совы и пауки двигаются туда, где окажутся
## в момент, когда светлячок долетит до кончика линии. Длина линии = время = запас света.

enum State { MENU, READY, DRAWING, RUNNING, DONE }

const SPEED := 260.0        # скорость полёта в px/сек (= скорость «времени»)
const STEP := 6.0           # шаг дискретизации линии
const PLAY_SPEED := 1.5     # ускорение проигрывания полёта (время мира масштабируется так же)
const START_RADIUS := 95.0
const ERASE_RADIUS := 24.0   # насколько близко к линии надо вести палец назад, чтобы стирать
const ERASE_LOOKBACK := 30   # сколько точек с конца линии проверяется за одно движение
const STILL_TIME := 0.14     # через сколько секунд неподвижного пальца «время встаёт»
const AREA := Rect2(20, 150, 680, 1110)
const FAIL_TEXT := {
    "owl": "Сова тебя заметила!",
    "spider": "Паук поймал светлячка!",
    "thorns": "Ай! Колючки!",
    "frog": "Лягушка слизнула светлячка!",
    "light": "Светогриб выдал тебя сове!",
}

@export var levels: Array[PackedScene] = []

@onready var holder: Node2D = $World/LevelHolder
@onready var world: Node2D = $World
@onready var path_line: Line2D = $World/Path
@onready var path_glow: Line2D = $World/PathGlow
@onready var danger_line: Line2D = $World/PathDanger
@onready var ghost: Node2D = $World/Ghost
@onready var start_hint: Node2D = $World/StartHint
@onready var firefly: Firefly = $World/Firefly
@onready var camera: Camera2D = $Camera2D
@onready var flash: ColorRect = $Overlay/Flash
@onready var fade: ColorRect = $Fade/Rect
@onready var hud: Hud = $HUD
@onready var menu: MainMenu = $Menu
@onready var win_panel: WinPanel = $Popups/WinPanel
@onready var lose_panel: LosePanel = $Popups/LosePanel
@onready var time_freeze: ColorRect = $World/TimeFreeze
@onready var backgrounds: Node2D = $Backgrounds

var state: State = State.MENU
var level: Level
var level_index := 0
var pts := PackedVector2Array()
var tms := PackedFloat32Array()   # время леса в каждой точке линии (в паутине растёт быстрее)
var drawn := 0.0
var fail_index := -1
var fail_info: Dictionary = {}
var dew_marks: Dictionary = {}   # индекс точки -> Dew
var run_time: float = 0.0
var run_i: int = 0
var next_event := 0
var collected := 0
var launch_delay := 0.0
var shake := 0.0
var tick_acc := 0.0
var hidden_now := false
var token := 0
var _cancel_tw: Tween
var _rewind_tw: Tween
var flow := 1.0            # 1 — время идёт, 0 — стоит (палец неподвижен)
var _applied_flow := -1.0
var _still := 0.0
var _moved := false
var _ink_warned := false
var erase_acc := 0.0
var _hint_level: int = -1   # для какого уровня подсказка уже открыта (до смены уровня)


func _ready() -> void:
    hud.menu_pressed.connect(open_menu)
    hud.restart_pressed.connect(_restart)
    hud.hint_pressed.connect(_on_hint_pressed)
    win_panel.next_pressed.connect(func() -> void: load_level(level_index + 1))
    win_panel.retry_pressed.connect(_restart)
    lose_panel.retry_pressed.connect(_restart)
    menu.level_chosen.connect(_on_level_chosen)
    fade.color.a = 0.0
    level_index = clampi(Progress.unlocked - 1, 0, levels.size() - 1)
    open_menu()


# ---------------------------------------------------------------- навигация

func open_menu() -> void:
    token += 1
    _load_level_now(level_index, false)
    hud.set_shown(false)
    menu.open()


func _on_level_chosen(i: int) -> void:
    menu.close()
    hud.set_shown(true)
    load_level(i)


func _restart() -> void:
    if state == State.MENU:
        return
    load_level(level_index)


func load_level(i: int) -> void:
    if i >= levels.size():
        open_menu()
        return
    token += 1
    state = State.DONE
    var tw: Tween = create_tween()
    tw.tween_property(fade, "color:a", 1.0, 0.22)
    tw.tween_callback(_load_level_now.bind(i, true))
    tw.tween_property(fade, "color:a", 0.0, 0.3)


func _load_level_now(i: int, play: bool) -> void:
    for c in holder.get_children():
        holder.remove_child(c)
        c.queue_free()
    if i != level_index or not play:
        _hint_level = -1
    level_index = i
    level = levels[i].instantiate() as Level
    holder.add_child(level)
    _set_chapter_background(level.chapter)
    win_panel.hide_panel()
    lose_panel.hide_panel()
    _clear_path()
    firefly.reset_visual()
    firefly.position = level.start_pos()
    start_hint.position = firefly.position
    start_hint.visible = true
    hud.set_level(i)
    hud.show_hint(level.hint)
    hud.set_par(level.par_ink / level.max_ink)
    level.intro()
    firefly.pop_in()
    state = State.READY if play else State.MENU
    if level.tutorial:
        level.tutorial.time_changed.connect(_on_tutorial_time)
        level.tutorial.set_active(play and _guide_wanted())
    hud.set_hint_available(play and level.tutorial != null and not _guide_wanted())


## Показывать ли маршрут руки: обучение (auto_play) или уже открытая подсказка.
func _guide_wanted() -> bool:
    if level == null or level.tutorial == null:
        return false
    return level.tutorial.auto_play or _hint_level == level_index


func _set_chapter_background(chapter: int) -> void:
    var n: int = backgrounds.get_child_count()
    for k: int in n:
        var bg: CanvasItem = backgrounds.get_child(k) as CanvasItem
        bg.visible = k == clampi(chapter, 0, n - 1)


## Кнопка-лампочка. Здесь удобно показать rewarded-рекламу Яндекс Игр
## и вызвать _grant_hint() в колбэке награды.
func _on_hint_pressed() -> void:
    if state != State.READY or level == null or level.tutorial == null:
        return
    _grant_hint()


func _grant_hint() -> void:
    _hint_level = level_index
    hud.set_hint_available(false)
    hud.show_toast("Смотри, как пройти!")
    level.tutorial.replay()


## Обучающая рука «рисует» линию — лес показывает будущее так же, как при игре.
func _on_tutorial_time(t: float) -> void:
    if state == State.READY and level:
        level.set_time(t)


# ---------------------------------------------------------------- ввод

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        var p: Vector2 = world.get_global_mouse_position()
        if event.pressed:
            if state == State.READY:
                if p.distance_to(firefly.position) < START_RADIUS:
                    _begin_draw()
                else:
                    hud.show_toast("Начни линию от светлячка!")
                    firefly.wiggle()
        elif state == State.DRAWING:
            _cancel_draw("Доведи линию до банки!")
    elif event is InputEventMouseMotion and state == State.DRAWING:
        _extend_to(world.get_global_mouse_position())


# ---------------------------------------------------------------- рисование

func _reset_lines() -> void:
    for l in [path_line, path_glow, danger_line]:
        l.clear_points()
        l.modulate.a = 1.0


func _clear_path() -> void:
    if _cancel_tw:
        _cancel_tw.kill()
    if _rewind_tw:
        _rewind_tw.kill()
    _reset_lines()
    pts.clear()
    tms.clear()
    drawn = 0.0
    fail_index = -1
    fail_info = {}
    dew_marks.clear()
    tick_acc = 0.0
    ghost.visible = false
    if level:
        for d in level.dews:
            d.reset()
        level.clear_alarms()
        level.set_time(0.0)
    hud.set_dews(0)
    hud.set_ink(1.0)
    hud.set_time(0.0)


func _begin_draw() -> void:
    _clear_path()
    state = State.DRAWING
    pts.append(firefly.position)
    tms.append(0.0)
    path_line.add_point(firefly.position)
    path_glow.add_point(firefly.position)
    ghost.visible = true
    ghost.position = firefly.position
    ghost.modulate = Color.WHITE
    start_hint.visible = false
    hud.hide_hint()
    _ink_warned = false
    erase_acc = 0.0
    if level.tutorial:
        level.tutorial.set_active(false)
    Sfx.play("Tick", 0.8)


func _extend_to(target: Vector2) -> void:
    target = target.clamp(AREA.position, AREA.end)
    if _try_erase(target):
        _moved = true
    else:
        var last: Vector2 = pts[pts.size() - 1]
        var guard := 0
        while state == State.DRAWING and last.distance_to(target) >= STEP and guard < 400:
            guard += 1
            if drawn + STEP > level.max_ink:
                _out_of_ink()
                break
            last = last + (target - last).normalized() * STEP
            _add_point(last)
            _moved = true
        if state != State.DRAWING:
            return
    _refresh_draw_state()


func _refresh_draw_state() -> void:
    var last: Vector2 = pts[pts.size() - 1]
    var t: float = _tip_time()
    level.set_time(t)
    level.update_alarms(last, t)
    ghost.position = last
    var tint: Color = Color(1.0, 0.35, 0.4) if fail_index >= 0 else Color.WHITE
    tint.a = 0.45 if level.is_hidden(last, t) else 1.0
    ghost.modulate = tint
    hud.set_ink(1.0 - drawn / level.max_ink, drawn <= level.par_ink)
    hud.set_time(t)


## Палец ведут назад вдоль линии — стираем её хвост, время отматывается.
func _try_erase(target: Vector2) -> bool:
    var n: int = pts.size()
    if n < 3:
        return false
    var tip: Vector2 = pts[n - 1]
    var dir: Vector2 = tip - pts[n - 2]
    if (target - tip).dot(dir) >= 0.0:
        return false   # палец движется вперёд — это рисование, а не стирание
    var best := -1
    var best_d: float = ERASE_RADIUS
    var lo: int = maxi(0, n - 1 - ERASE_LOOKBACK)
    for j in range(n - 2, lo - 1, -1):
        var d: float = target.distance_to(pts[j])
        if d < best_d:
            best_d = d
            best = j
        elif best >= 0 and d > ERASE_RADIUS * 1.5:
            break
    if best < 0:
        return false
    while pts.size() - 1 > best:
        _pop_point()
    _ink_warned = false
    return true


func _pop_point() -> void:
    var idx: int = pts.size() - 1
    if dew_marks.has(idx):
        var d: Dew = dew_marks[idx]
        d.set_preview(false)
        dew_marks.erase(idx)
        hud.set_dews(dew_marks.size())
    if fail_index >= 0:
        if idx == fail_index:
            fail_index = -1
            fail_info = {}
            danger_line.clear_points()
        elif danger_line.get_point_count() > 0:
            danger_line.remove_point(danger_line.get_point_count() - 1)
    else:
        path_line.remove_point(path_line.get_point_count() - 1)
        path_glow.remove_point(path_glow.get_point_count() - 1)
    pts.remove_at(idx)
    tms.remove_at(idx)
    drawn -= STEP
    erase_acc += STEP
    if erase_acc >= 60.0:
        erase_acc = 0.0
        Sfx.play("Tick", 0.5 + 0.5 * drawn / level.max_ink)


## Свет кончился: линия дальше не растёт, но её можно стереть назад.
func _out_of_ink() -> void:
    if _ink_warned:
        return
    _ink_warned = true
    hud.show_toast("Свет закончился! Сотри часть линии")
    Sfx.play("Fail", 1.5)
    _shake(4.0)


func _add_point(p: Vector2) -> void:
    var t: float = _tip_time() + STEP / SPEED * level.time_rate(p)
    pts.append(p)
    tms.append(t)
    drawn += STEP
    var idx: int = pts.size() - 1
    if fail_index < 0:
        path_line.add_point(p)
        path_glow.add_point(p)
        var info: Dictionary = level.check(p, t)
        if not info.is_empty():
            fail_index = idx
            fail_info = info
            danger_line.add_point(pts[idx - 1])
            danger_line.add_point(p)
            Sfx.play("Alert", 1.2)
            _shake(5.0)
        else:
            for d in level.dews:
                if not d.previewed and d.contains(p):
                    d.set_preview(true)
                    dew_marks[idx] = d
                    hud.set_dews(dew_marks.size())
                    Sfx.play("Pop", 1.0 + 0.15 * dew_marks.size())
    else:
        danger_line.add_point(p)
    tick_acc += STEP
    if tick_acc >= 72.0:
        tick_acc = 0.0
        Sfx.play("Tick", 0.9 + 0.8 * drawn / level.max_ink)
    if level.jar and level.jar.contains(p):
        _launch()


func _cancel_draw(msg: String) -> void:
    state = State.READY
    hud.show_toast(msg)
    hud.show_hint(level.hint)
    Sfx.play("Rewind")
    level.clear_alarms()
    ghost.visible = false
    start_hint.visible = true
    for d in level.dews:
        d.set_preview(false)
    hud.set_dews(0)
    hud.set_ink(1.0)
    _rewind(0.45)
    if _guide_wanted():
        level.tutorial.set_active(true)
    pts.clear()
    tms.clear()
    drawn = 0.0
    fail_index = -1
    fail_info = {}
    dew_marks.clear()
    if _cancel_tw:
        _cancel_tw.kill()
    _cancel_tw = create_tween().set_parallel(true)
    for l in [path_line, path_glow, danger_line]:
        _cancel_tw.tween_property(l, "modulate:a", 0.0, 0.35)
    _cancel_tw.chain().tween_callback(_reset_lines)


## Эффект «перемотки времени» назад к нулю.
func _rewind(dur: float) -> void:
    if _rewind_tw:
        _rewind_tw.kill()
    _rewind_tw = create_tween()
    _rewind_tw.tween_method(_set_world_time, _tip_time(), 0.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _tip_time() -> float:
    if tms.is_empty():
        return 0.0
    return tms[tms.size() - 1]


func _set_world_time(t: float) -> void:
    if level:
        level.set_time(t)
    hud.set_time(t)


# ---------------------------------------------------------------- полёт

func _launch() -> void:
    state = State.RUNNING
    level.clear_alarms()
    ghost.visible = false
    for d in level.dews:
        d.set_preview(false)
    hud.set_dews(0)
    collected = 0
    run_time = 0.0
    run_i = 0
    next_event = 0
    hidden_now = level.is_hidden(pts[0], 0.0)
    launch_delay = 0.5
    _rewind(0.4)
    Sfx.play("Rewind", 1.3)
    hud.show_toast("Полетели!")
    firefly.set_flying(true)


func _process(delta: float) -> void:
    _update_shake(delta)
    _update_flow(delta)
    if state != State.RUNNING:
        return
    if launch_delay > 0.0:
        launch_delay -= delta
        if launch_delay <= 0.0:
            Sfx.play("Whoosh")
        return
    # Полёт идёт по времени леса: в паутине светлячок вязнет и летит медленнее.
    run_time += PLAY_SPEED * delta
    var last_i: int = pts.size() - 1
    while run_i < last_i and tms[run_i + 1] <= run_time:
        run_i += 1
    var i: int = run_i
    var frac: float = 0.0
    if i < last_i:
        frac = clampf((run_time - tms[i]) / maxf(tms[i + 1] - tms[i], 0.0001), 0.0, 1.0)
    while next_event <= i:
        var k: int = next_event
        next_event += 1
        if dew_marks.has(k):
            _collect(dew_marks[k])
        if k == fail_index:
            _fail(k)
            return
    if i >= last_i:
        firefly.position = pts[last_i]
        _win()
        return
    var a: Vector2 = pts[i]
    var b: Vector2 = pts[i + 1]
    var p: Vector2 = a.lerp(b, frac)
    firefly.position = p
    firefly.face(b - a)
    var t: float = run_time
    level.set_time(t)
    hud.set_time(t)
    var end: int = fail_index + 1 if fail_index >= 0 else pts.size()
    var burn: PackedVector2Array = pts.slice(i + 1, end)
    burn.insert(0, p)
    path_line.points = burn
    path_glow.points = burn
    var hid: bool = level.is_hidden(p, t)
    if hid != hidden_now:
        hidden_now = hid
        if hid:
            var bush: Bush = level.bush_at(p, t)
            if bush:
                bush.rustle()
            Sfx.play("Rustle")
        firefly.set_hidden(hid)


func _collect(d: Dew) -> void:
    d.collect()
    collected += 1
    hud.set_dews(collected)
    Sfx.play("Dew", 1.0 + 0.12 * collected)


func _fail(k: int) -> void:
    state = State.DONE
    var my: int = token
    level.set_time(tms[k])
    firefly.position = pts[k]
    firefly.set_flying(false)
    var node: Object = fail_info.get("node")
    if node and node.has_method("alert"):
        node.call("alert")
    firefly.caught()
    Sfx.play("Alert")
    Sfx.play("Fail")
    _shake(18.0)
    _flash(Color(1.0, 0.15, 0.3, 0.45))
    await get_tree().create_timer(1.0).timeout
    if my != token:
        return
    lose_panel.show_lose(FAIL_TEXT.get(fail_info.get("reason", ""), "Попался!"))


func _win() -> void:
    state = State.DONE
    var my: int = token
    firefly.set_flying(false)
    level.jar.celebrate()
    firefly.celebrate(level.jar.global_position)
    path_line.clear_points()
    path_glow.clear_points()
    Sfx.play("Win")
    _shake(6.0)
    _flash(Color(1.0, 0.9, 0.5, 0.35))
    # Звёзды: дом, вся роса, экономия света (уложился в норму уровня).
    var got: Array = [true, collected >= level.dews.size(), drawn <= level.par_ink + 0.5]
    var count := 0
    for g in got:
        if g:
            count += 1
    Progress.complete(level_index, count)
    await get_tree().create_timer(1.1).timeout
    if my != token:
        return
    win_panel.show_win(got, collected, int(drawn), int(level.par_ink), level_index >= levels.size() - 1)


# ---------------------------------------------------------------- эффекты

## «Время стоит»: пока палец неподвижен, лес сереет, музыка плывёт, фон замирает.
func _update_flow(delta: float) -> void:
    var target := 1.0
    if state == State.DRAWING:
        _still = 0.0 if _moved else _still + delta
        target = 0.0 if _still > STILL_TIME else 1.0
    _moved = false
    flow = move_toward(flow, target, delta * (9.0 if target > flow else 3.5))
    if is_equal_approx(flow, _applied_flow):
        return
    _applied_flow = flow
    var f: float = 1.0 - flow
    WorldClock.scale = flow
    time_freeze.visible = f > 0.01
    (time_freeze.material as ShaderMaterial).set_shader_parameter("amount", f)
    Sfx.set_flow(flow)
    hud.set_frozen(f)


func _shake(amount: float) -> void:
    shake = maxf(shake, amount)


func _update_shake(delta: float) -> void:
    if shake > 0.05:
        camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake
        shake = move_toward(shake, 0.0, 50.0 * delta)
    else:
        camera.offset = Vector2.ZERO


func _flash(c: Color) -> void:
    flash.color = c
    create_tween().tween_property(flash, "color:a", 0.0, 0.5)
