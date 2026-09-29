class_name Level
extends Node2D
## Корень сцены уровня. Объекты уровня (совы, кусты, роса…) — дочерние инстансы сцен.
## Уровень сам находит их и отвечает на вопрос: «безопасна ли точка p в момент времени t?»

@export var max_ink: float = 2400.0
## Норма света для третьей звезды («Экономно»).
@export var par_ink: float = 2000.0
## Глава: 0 — Ночной лес, 1 — Болото, 2 — Грибная поляна (фон).
@export var chapter: int = 0
@export_multiline var hint: String = ""

var owls: Array[Owl] = []
var dews: Array[Dew] = []
var bushes: Array[Bush] = []      ## кусты, камыши и кувшинки (LilyPad наследует Bush)
var thorns: Array[Thorns] = []
var spiders: Array[Spider] = []
var frogs: Array[Frog] = []
var webs: Array[Web] = []
var shrooms: Array[GlowShroom] = []
var jar: Jar
var tutorial: Tutorial


func _ready() -> void:
    for n: Node in find_children("*", "", true, false):
        if n is Owl:
            owls.append(n as Owl)
        elif n is Dew:
            dews.append(n as Dew)
        elif n is Bush:
            bushes.append(n as Bush)
        elif n is Thorns:
            thorns.append(n as Thorns)
        elif n is Spider:
            spiders.append(n as Spider)
        elif n is Frog:
            frogs.append(n as Frog)
        elif n is Web:
            webs.append(n as Web)
        elif n is GlowShroom:
            shrooms.append(n as GlowShroom)
        elif n is Jar:
            jar = n as Jar
        elif n is Tutorial:
            tutorial = n as Tutorial
    set_time(0.0)


func start_pos() -> Vector2:
    return ($Start as Node2D).global_position


## Перевести весь мир в момент времени t (детерминированно).
func set_time(t: float) -> void:
    for o: Owl in owls:
        o.set_time(t)
    for s: Spider in spiders:
        s.set_time(t)
    for f: Frog in frogs:
        f.set_time(t)
    for b: Bush in bushes:
        b.set_time(t)
    for g: GlowShroom in shrooms:
        g.set_time(t)


## Во сколько раз быстрее идёт время в точке p (паутина).
func time_rate(p: Vector2) -> float:
    var r: float = 1.0
    for w: Web in webs:
        if w.contains(p):
            r = maxf(r, w.rate)
    return r


func bush_at(p: Vector2, t: float) -> Bush:
    for b: Bush in bushes:
        if b.hides(p, t):
            return b
    return null


func shroom_at(p: Vector2, t: float) -> GlowShroom:
    for g: GlowShroom in shrooms:
        if g.lights(p, t):
            return g
    return null


## Спрятан ли светлячок: в укрытии и не в свете светогриба.
func is_hidden(p: Vector2, t: float) -> bool:
    return bush_at(p, t) != null and shroom_at(p, t) == null


func any_owl_awake(t: float) -> bool:
    for o: Owl in owls:
        if o.is_awake(t):
            return true
    return false


## Возвращает {} если безопасно, иначе {"reason": ..., "node": ...}.
func check(p: Vector2, t: float) -> Dictionary:
    for th: Thorns in thorns:
        if th.hits(p):
            return {"reason": "thorns", "node": th}
    for s: Spider in spiders:
        if s.hits(p, t):
            return {"reason": "spider", "node": s}
    for f: Frog in frogs:
        if f.hits(p, t):
            return {"reason": "frog", "node": f}
    var shroom: GlowShroom = shroom_at(p, t)
    if shroom != null and any_owl_awake(t):
        return {"reason": "light", "node": shroom}
    if bush_at(p, t) == null:
        for o: Owl in owls:
            if o.sees(p, t):
                return {"reason": "owl", "node": o}
    return {}


func update_alarms(p: Vector2, t: float) -> void:
    var hidden: bool = is_hidden(p, t)
    var lit: bool = shroom_at(p, t) != null
    for o: Owl in owls:
        o.set_alarm((lit and o.is_awake(t)) or (not hidden and o.sees(p, t)))


func clear_alarms() -> void:
    for o: Owl in owls:
        o.set_alarm(false)


## Эффектное появление объектов уровня по очереди.
func intro() -> void:
    var i: int = 0
    for c: Node in get_children():
        if c is Node2D and c.name != "Start" and not (c is Tutorial):
            var node: Node2D = c as Node2D
            var target: Vector2 = node.scale
            node.scale = Vector2.ZERO
            var tw: Tween = create_tween()
            tw.tween_interval(0.035 * i)
            tw.tween_property(node, "scale", target, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
            i += 1
