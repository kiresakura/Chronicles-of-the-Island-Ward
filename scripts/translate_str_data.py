#!/usr/bin/env python3
"""
Batch-generate JSON overrides to translate all STR add_test_*() default
strings to Traditional Chinese. Output goes to external/data/*/

Run once after schema changes; re-run safely overwrites.
"""
import json
import os
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
EXT = ROOT / "external" / "data"

# Each entry: (folder, object_id, properties_dict)
# properties only contain the keys we want to override (name/description).
OVERRIDES = []

def add(folder, object_id, **properties):
    OVERRIDES.append((folder, object_id, properties))

# ─────────── Run Modifiers ───────────
add("run_modifiers", "run_modifier_difficulty_1",
    run_modifier_name="難度 1 (敵人 HP 增加)")
add("run_modifiers", "run_modifier_difficulty_2",
    run_modifier_name="難度 2 (菁英 HP 增加)")
add("run_modifiers", "run_modifier_difficulty_3",
    run_modifier_name="難度 3 (Boss HP 增加)")
add("run_modifiers", "run_modifier_difficulty_4",
    run_modifier_name="難度 4")
add("run_modifiers", "run_modifier_difficulty_5",
    run_modifier_name="難度 5")
add("run_modifiers", "run_modifier_custom_easy_mode",
    run_modifier_name="易模式",
    run_modifier_description="所有敵人僅 1 HP")
add("run_modifiers", "run_modifier_custom_endless_mode",
    run_modifier_name="無盡模式",
    run_modifier_description="通關後繼續挑戰")
add("run_modifiers", "run_modifier_custom_1",
    run_modifier_name="自訂 1",
    run_modifier_description="自訂修正 1")
add("run_modifiers", "run_modifier_custom_2",
    run_modifier_name="自訂 2",
    run_modifier_description="自訂修正 2")
add("run_modifiers", "run_modifier_custom_prismatic",
    run_modifier_name="七彩",
    run_modifier_description="所有顏色卡牌可抽")

# ─────────── Status Effects ───────────
add("status_effects", "status_effect_corrosion", status_effect_name="邪氣")
add("status_effects", "status_effect_bomb", status_effect_name="炸彈")
add("status_effects", "status_effect_damage_increase", status_effect_name="神威")
add("status_effects", "status_effect_weaken", status_effect_name="怯戰")
add("status_effects", "status_effect_vulnerable", status_effect_name="驚嚇")
add("status_effects", "status_effect_attached_card", status_effect_name="附身卡")
add("status_effects", "status_effect_duplicate_card_plays", status_effect_name="重複出牌")
add("status_effects", "status_effect_duplicate_attacks", status_effect_name="重複攻擊")
add("status_effects", "status_effect_preserve_block", status_effect_name="保留護身符")
add("status_effects", "status_effect_negate_damage", status_effect_name="無視傷害")
add("status_effects", "status_effect_negate_debuffs", status_effect_name="無視 debuff")

# ─────────── Rest Actions ───────────
add("rest_actions", "rest_action_rest", rest_action_name="休息")
add("rest_actions", "rest_action_upgrade_card", rest_action_name="升級卡牌")
add("rest_actions", "rest_action_remove_cards", rest_action_name="移除卡牌")
add("rest_actions", "rest_action_add_random_consumable", rest_action_name="隨機\n消耗品")
add("rest_actions", "rest_action_increase_attack_on_rest", rest_action_name="增加傷害")

# ─────────── Consumables ───────────
add("consumables", "consumable_heal",
    consumable_name="符水", consumable_description="恢復 20% 元神")
add("consumables", "consumable_block",
    consumable_name="護身符", consumable_description="獲得 10 點護身符")
add("consumables", "consumable_damaging",
    consumable_name="符紙",   consumable_description="對一個目標造成 10 點傷害")
add("consumables", "consumable_multi_damaging",
    consumable_name="散符",   consumable_description="對所有敵人造成 10 點傷害")

# ─────────── Characters (STR robot placeholders) ───────────
add("characters", "character_red",
    character_name="道士 (未解鎖)",
    character_description="待開發 — 暫沿用 STR 紅角色資料。")
add("characters", "character_blue",
    character_name="家將 (未解鎖)",
    character_description="待開發 — 暫沿用 STR 藍角色資料。")
add("characters", "character_green",
    character_name="綠角色 (測試)",
    character_description="STR 測試角色，正式版會移除。")

# ─────────── Artifacts (STR test) ───────────
ART_TRANS = [
    ("artifact_add_money", "進財符", "獲得時加銀兩"),
    ("artifact_heal_on_combat_ended", "癒戰符", "戰鬥結束時 +5 元神"),
    ("artifact_full_heal", "回元符", "獲得時全滿元神"),
    ("artifact_draw_on_kill", "斬鬼符", "擊殺敵人時抽 1 張牌"),
    ("artifact_draw_on_combat_start", "啟戰符", "第一回合多抽 2 張牌"),
    ("artifact_easy_mode", "弱敵符", "所有敵人 HP 設為 1"),
    ("artifact_block_on_attacks", "頻護符", "每 3 次攻擊獲得 5 點護身符"),
    ("artifact_retain_hand", "存手符", "手牌結束回合不丟棄"),
    ("artifact_increase_attack_on_rest", "鍛魂符", "廟宇休息可永久提升攻擊力"),
    ("artifact_see_top_of_draw_pile", "見牌符", "可看見抽牌堆頂部卡牌"),
    ("artifact_top_deck_attack_card", "固牌符", "選一張攻擊卡使其每場戰鬥首抽出現"),
    ("artifact_right_click_shuffle_deck", "重洗符", "右鍵將棄牌堆洗回抽牌堆"),
    ("artifact_boss_red", "紅 Boss 遺物", "測試用紅色 Boss 遺物"),
    ("artifact_shop_red", "紅市集遺物", "測試用紅色商店遺物"),
    ("artifact_boss_blue", "藍 Boss 遺物", "測試用藍色 Boss 遺物"),
    ("artifact_shop_blue", "藍市集遺物", "測試用藍色商店遺物"),
    ("artifact_boss_green", "綠 Boss 遺物", "測試用綠色 Boss 遺物"),
    ("artifact_shop_green", "綠市集遺物", "測試用綠色商店遺物"),
    ("artifact_boss_orange", "橘 Boss 遺物", "測試用橘色 Boss 遺物"),
    ("artifact_shop_orange", "橘市集遺物", "測試用橘色商店遺物"),
    ("artifact_boss_white", "白 Boss 遺物", "測試用白色 Boss 遺物"),
    ("artifact_shop_white", "白市集遺物", "測試用白色商店遺物"),
]
for obj_id, name, desc in ART_TRANS:
    add("artifacts/str", obj_id, artifact_name=name, artifact_description=desc)

# ─────────── Cards (STR test) ───────────
CARD_TRANS = [
    ("card_attack_basic", "基礎攻擊", "造成 [damage] 點傷害 [number_of_attacks] 次"),
    ("card_attack_rng", "隨機攻擊", "隨機造成 [damage] - [damage_random] 點傷害"),
    ("card_attack_big", "重攻擊", "造成大量傷害"),
    ("card_attack_heal_unblocked_damage", "癒擊", "造成傷害並回復未阻擋的傷害"),
    ("card_improving_attack", "進攻", "每次使用後傷害提升"),
    ("improving_retain_block_card", "持續護身符", "護身符不結算消失"),
    ("self_attaching_attack_card", "纏身攻擊", "黏附於敵人造成持續傷害"),
    ("attack_with_conditional_draw_card", "抽牌攻擊", "造成傷害並抽牌"),
    ("attack_with_conditional_block_card", "護擊", "造成傷害並獲得護身符"),
    ("variable_cost_attack_card", "變費攻擊", "消耗所有神力造成等量傷害"),
    ("cards_played_attack_card", "牌效攻擊", "傷害取決於本回合出牌數"),
    ("card_block_initial", "護身符卡", "獲得 [block] 點護身符"),
    ("custom_block_card", "自訂護身符", "獲得護身符"),
    ("end_turn_card", "結束回合", "立刻結束回合"),
    ("card_block_big", "重護身符", "獲得大量護身符，消除"),
    ("card_improving_block", "強化護身符", "每次使用後護身符量提升"),
    ("card_law", "律令", "施加狀態效果"),
    ("card_discard_block", "棄牌護身符", "棄牌獲得護身符"),
    ("card_banish_attack", "驅逐攻擊", "造成傷害並驅逐"),
    ("card_special_discard", "特別棄牌", "棄一張牌並獲得效果"),
    ("card_pick_from_discard", "拾棄牌", "從棄牌堆選一張回手"),
    ("add_to_draw_from_discard_card", "添抽牌", "從棄牌堆加一張到抽牌堆"),
    ("set_hand_energy_card", "歸零神力", "本回合所有手牌神力 0"),
    ("transform_hand_card", "變換手牌", "變換所有手牌"),
    ("card_right_click_transform_mode_a", "模式 A", "可右鍵變換"),
    ("card_right_click_transform_mode_b", "模式 B", "可右鍵變換"),
    ("randomize_hand_card", "亂費", "隨機重設手牌神力"),
    ("card_generate_shoves", "震天舞", "產生震開卡"),
    ("card_shove", "震開", "震退敵人"),
    ("card_energy_on_discard", "棄牌生力", "棄牌時 +神力"),
    ("card_discard_hand", "棄全手", "棄掉所有手牌"),
    ("card_cycle_enemy_intent", "驅意", "改變敵人意圖"),
    ("card_block_without_attacks", "守心", "不攻擊則獲得護身符"),
    ("attack_lower_cost_on_discard_card", "降費攻擊", "棄牌後神力消耗 -1"),
    ("attack_increase_cost_on_damage_taken_card", "受傷攻擊", "受傷後神力消耗 +1"),
    ("block_if_exhaust_card", "消除護身符", "消除時獲得護身符"),
    ("card_attack_in_center", "陣前擊", "中央敵人多 +傷害"),
    ("card_requires_adjacency", "鄰擊", "敵人有鄰居才能出"),
    ("card_play_from_discard", "棄堆出牌", "從棄牌堆使用一張牌"),
    ("card_discard_attacks_from_draw", "棄抽攻擊", "從抽牌堆棄所有攻擊"),
    ("card_play_random_from_hand", "亂出", "隨機出一張手牌"),
    ("retain_hand_card", "持手", "本回合保留手牌"),
    ("card_upgrade_card", "升級卡", "升級一張手牌"),
    ("upgrade_entire_deck_card", "升級全戰場", "升級戰鬥所有卡"),
    ("card_draft_random_attack", "選張攻擊", "選一張攻擊加入牌組"),
    ("card_draft_red_card", "選張紅卡", "選一張紅色卡加入牌組"),
    ("card_draft_random_player_pool", "亂抽", "從牌池隨機選一張"),
    ("card_grant_energy", "予力", "獲得 1 點神力"),
    ("card_energy_on_draw", "抽中力", "抽到時 +神力"),
    ("add_health_card", "加元神", "+元神"),
    ("card_restart_combat", "重戰", "重置戰鬥"),
    ("card_debug_log", "除錯印", "輸出 console 訊息"),
]
for obj_id, name, desc in CARD_TRANS:
    add("cards/str", obj_id, card_name=name, card_description=desc)

# ─────────── Enemies (STR robot placeholders) ───────────
ENEMY_TRANS = [
    ("enemy_1", "紅機甲"),
    ("enemy_2", "藍機甲"),
    ("enemy_3", "綠機甲"),
    ("enemy_4", "橘機甲"),
    ("enemy_act_1_miniboss_1", "巨形機甲"),
    ("enemy_act_1_miniboss_2", "雙臂機甲"),
    ("enemy_act_1_boss_1", "終極機甲"),
]
for obj_id, name in ENEMY_TRANS:
    add("enemies/str", obj_id, enemy_name=name)

# ─────────── Run Start Options ───────────
add("run_start_options", "run_start_option_money_for_rare_card",
    run_start_option_name="銀兩換稀有卡")
add("run_start_options", "run_start_option_common_artifact",
    run_start_option_name="獲得普通遺物")

# ─────────── Write all files ───────────
written = 0
for folder, object_id, properties in OVERRIDES:
    out_dir = EXT / folder
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / f"{object_id}.json"
    payload = {"patch_data": {}, "properties": {"object_id": object_id, **properties}}
    out_file.write_text(json.dumps(payload, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")
    written += 1

print(f"✅ Wrote {written} translation override JSONs")
