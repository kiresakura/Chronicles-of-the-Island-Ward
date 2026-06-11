## Force the Godot export pipeline to include cards_v3 / portraits_v3 / scenes_v3 / etc.
## NBP-generated assets are referenced only by JSON strings (CardData.card_texture_path),
## so without an explicit preload they're stripped from the APK. We keep a constant Dictionary
## of preload() expressions so they're treated as hard dependencies.
##
## 鐵律 3 友善: 完全 additive — 沒有人依賴這個 file 也不會壞，只是 export-time hint.
extends RefCounted
class_name CardArtRegistry

const TONGJI_CARDS: Dictionary = {
	"card_tongji_charge": preload("res://assets/generated/cards_v3/card_tongji_charge.png"),
	"card_tongji_double_strike": preload("res://assets/generated/cards_v3/card_tongji_double_strike.png"),
	"card_tongji_draw_charm": preload("res://assets/generated/cards_v3/card_tongji_draw_charm.png"),
	"card_tongji_evil_curse": preload("res://assets/generated/cards_v3/card_tongji_evil_curse.png"),
	"card_tongji_exorcise": preload("res://assets/generated/cards_v3/card_tongji_exorcise.png"),
	"card_tongji_fury_strike": preload("res://assets/generated/cards_v3/card_tongji_fury_strike.png"),
	"card_tongji_great_talisman": preload("res://assets/generated/cards_v3/card_tongji_great_talisman.png"),
	"card_tongji_heavy_strike": preload("res://assets/generated/cards_v3/card_tongji_heavy_strike.png"),
	"card_tongji_possession": preload("res://assets/generated/cards_v3/card_tongji_possession.png"),
	"card_tongji_punch": preload("res://assets/generated/cards_v3/card_tongji_punch.png"),
	"card_tongji_talisman": preload("res://assets/generated/cards_v3/card_tongji_talisman.png"),
}

const PORTRAITS: Dictionary = {
	"tongji": preload("res://assets/generated/portraits_v3/tongji.png"),
	"daoshi": preload("res://assets/generated/portraits_v3/daoshi.png"),
	"jiajiang": preload("res://assets/generated/portraits_v3/jiajiang.png"),
}

const SCENES: Dictionary = {
	"act1_mountain_temple": preload("res://assets/generated/scenes_v3/act1_mountain_temple.png"),
	"act2_water_temple": preload("res://assets/generated/scenes_v3/act2_water_temple.png"),
	"act3_evil_underworld": preload("res://assets/generated/scenes_v3/act3_evil_underworld.png"),
}

const JIAJIANG: Dictionary = {
	"gan_general": preload("res://assets/generated/jiajiang_v3/gan_general.png"),
	"liu_general": preload("res://assets/generated/jiajiang_v3/liu_general.png"),
	"xie_general": preload("res://assets/generated/jiajiang_v3/xie_general.png"),
	"fan_general": preload("res://assets/generated/jiajiang_v3/fan_general.png"),
	"spring_god": preload("res://assets/generated/jiajiang_v3/spring_god.png"),
	"summer_god": preload("res://assets/generated/jiajiang_v3/summer_god.png"),
	"autumn_god": preload("res://assets/generated/jiajiang_v3/autumn_god.png"),
	"winter_god": preload("res://assets/generated/jiajiang_v3/winter_god.png"),
}

const DEITIES: Dictionary = {
	"mazu": preload("res://assets/generated/deities_v3/mazu.png"),
	"guanyin": preload("res://assets/generated/deities_v3/guanyin.png"),
	"wangye": preload("res://assets/generated/deities_v3/wangye.png"),
	"chenghuang": preload("res://assets/generated/deities_v3/chenghuang.png"),
	"tudi": preload("res://assets/generated/deities_v3/tudi.png"),
	"huye": preload("res://assets/generated/deities_v3/huye.png"),
}

const ENEMIES: Dictionary = {
	"enemy_chair_girl": preload("res://assets/generated/enemies_v3/enemy_chair_girl.png"),
	"enemy_lost_soul": preload("res://assets/generated/enemies_v3/enemy_lost_soul.png"),
	"enemy_mountain_boar": preload("res://assets/generated/enemies_v3/enemy_mountain_boar.png"),
	"enemy_tiger_god": preload("res://assets/generated/enemies_v3/enemy_tiger_god.png"),
	"enemy_tree_spirit": preload("res://assets/generated/enemies_v3/enemy_tree_spirit.png"),
	"enemy_white_snake": preload("res://assets/generated/enemies_v3/enemy_white_snake.png"),
}

const ARTIFACTS: Dictionary = {
	"artifact_white": preload("res://assets/generated/artifacts_v3/artifact_white.png"),
	"artifact_add_money": preload("res://assets/generated/artifacts_v3/artifact_add_money.png"),
	"artifact_block_on_attacks": preload("res://assets/generated/artifacts_v3/artifact_block_on_attacks.png"),
	"artifact_draw_on_combat_start": preload("res://assets/generated/artifacts_v3/artifact_draw_on_combat_start.png"),
	"artifact_draw_on_kill": preload("res://assets/generated/artifacts_v3/artifact_draw_on_kill.png"),
	"artifact_full_heal": preload("res://assets/generated/artifacts_v3/artifact_full_heal.png"),
	"artifact_heal_on_combat_ended": preload("res://assets/generated/artifacts_v3/artifact_heal_on_combat_ended.png"),
	"artifact_incense_burner": preload("res://assets/generated/artifacts_v3/artifact_incense_burner.png"),
	"artifact_increase_attack_on_rest": preload("res://assets/generated/artifacts_v3/artifact_increase_attack_on_rest.png"),
	"artifact_red_string": preload("res://assets/generated/artifacts_v3/artifact_red_string.png"),
	"artifact_retain_hand": preload("res://assets/generated/artifacts_v3/artifact_retain_hand.png"),
	"artifact_right_click_shuffle_deck": preload("res://assets/generated/artifacts_v3/artifact_right_click_shuffle_deck.png"),
	"artifact_see_top_of_draw_pile": preload("res://assets/generated/artifacts_v3/artifact_see_top_of_draw_pile.png"),
	"artifact_temple_drum": preload("res://assets/generated/artifacts_v3/artifact_temple_drum.png"),
	"artifact_tiger_token": preload("res://assets/generated/artifacts_v3/artifact_tiger_token.png"),
	"artifact_tongji_amulet": preload("res://assets/generated/artifacts_v3/artifact_tongji_amulet.png"),
}


static func get_card_art(card_object_id: String) -> Texture2D:
	return TONGJI_CARDS.get(card_object_id, null)


static func get_portrait(character_id: String) -> Texture2D:
	return PORTRAITS.get(character_id, null)


static func get_scene_bg(act_id: String) -> Texture2D:
	return SCENES.get(act_id, null)


static func get_jiajiang(jiajiang_id: String) -> Texture2D:
	return JIAJIANG.get(jiajiang_id, null)


static func get_deity(deity_id: String) -> Texture2D:
	return DEITIES.get(deity_id, null)


static func get_enemy(enemy_id: String) -> Texture2D:
	return ENEMIES.get(enemy_id, null)


static func get_artifact(artifact_object_id: String) -> Texture2D:
	return ARTIFACTS.get(artifact_object_id, null)


## 解析 artifact 貼圖：先查 registry（res:// 打包素材，含本批去背圖），
## 找不到再退回 FileLoader（external/ 圖）。artifact_data 為 null 時回 null。
static func resolve_artifact_texture(artifact_data: ArtifactData) -> Texture2D:
	if artifact_data == null:
		return null
	var tex: Texture2D = get_artifact(artifact_data.object_id)
	if tex == null:
		# Q0：object_id miss 時以檔名 stem 反查 preload（如共用 fallback artifact_white），
		# 避免 FileLoader 原始載圖在 export 失效 + 噴警告
		tex = get_by_texture_path(artifact_data.artifact_texture_path)
	if tex == null:
		tex = FileLoader.load_texture(artifact_data.artifact_texture_path)
	return tex


## 由 texture_path 反查（取檔名去副檔名當 key）— 給 Player/Enemy 用 path 載圖時走 registry。
static func get_by_texture_path(texture_path: String) -> Texture2D:
	if texture_path.is_empty():
		return null
	var key: String = texture_path.get_file().get_basename()
	for d in [TONGJI_CARDS, PORTRAITS, SCENES, JIAJIANG, DEITIES, ENEMIES, ARTIFACTS]:
		if d.has(key):
			return d[key]
	return null
