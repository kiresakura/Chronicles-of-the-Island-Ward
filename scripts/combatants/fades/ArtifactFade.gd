# provides an artifact icon which fades over a combatant
extends Node2D
class_name ArtifactFade

@onready var animation_player = $Sprite/AnimationPlayer
@onready var sprite: TextureRect = $Sprite


func _ready():
	animation_player.animation_finished.connect(_on_fade_animation_finished)

## artifact_data 由呼叫端（_on_artifact_proc）直接傳入；貼圖經 CardArtRegistry
## 解析（res:// 打包素材優先、退回 FileLoader 載 external/ 圖），null 安全。
func init(artifact_data: ArtifactData) -> void:
	sprite.texture = CardArtRegistry.resolve_artifact_texture(artifact_data)
	animation_player.play("fade")

func _on_fade_animation_finished(_anim_name: String):
	queue_free()
