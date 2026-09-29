extends Node
## Автозагрузка «Sfx» (сцена audio.tscn): все звуки — узлы AudioStreamPlayer в сцене.


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    $Music.finished.connect($Music.play)
    apply_sound()
    $Music.play()


const MUSIC_DB := -7.0

## Поток времени 0..1: когда время стоит, музыка «плывёт» вниз и затихает (как плёнка).
func set_flow(flow: float) -> void:
    var m: AudioStreamPlayer = $Music as AudioStreamPlayer
    m.pitch_scale = lerpf(0.7, 1.0, flow)
    m.volume_db = MUSIC_DB + lerpf(-7.0, 0.0, flow)


func play(sound: String, pitch: float = 1.0) -> void:
    var p: AudioStreamPlayer = get_node_or_null(sound) as AudioStreamPlayer
    if p == null:
        return
    p.pitch_scale = pitch
    p.play()


func apply_sound() -> void:
    AudioServer.set_bus_mute(0, not Progress.sound_on)


func _notification(what: int) -> void:
    # Глушим звук, когда вкладка/окно теряет фокус (требование площадок).
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        AudioServer.set_bus_mute(0, true)
    elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
        apply_sound()
