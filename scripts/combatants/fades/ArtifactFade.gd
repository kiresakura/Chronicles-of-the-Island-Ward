# provides an artifact icon which fades over a combatant
extends Node2D
class_name ArtifactFade

@onready var animation_player = $Sprite/AnimationPlayer
@onready var sprite: TextureRect = $Sprite


func _ready():
	animation_player.animation_finished.connect(_on_fade_animation_finished)

## artifact_data 由呼叫端（_on_artifact_proc）直接傳入 —— 不再以 object_id
## 反查 Global.get_artifact_data()，該反查對執行期生成 / 未註冊的 artifact
## 會回 null 而於此崩潰。
func init(artifact_data: ArtifactData) -> void:
	if artifact_data != null:
		sprite.texture = FileLoader.load_texture(artifact_data.artifact_texture_path)

	animation_player.play("fade")

func _on_fade_animation_finished(_anim_name: String):
	queue_free()
