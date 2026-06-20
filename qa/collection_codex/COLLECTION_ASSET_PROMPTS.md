# 鎮島錄收藏頁 QA：素材缺口與 PixelLab Prompt 全表
產出時間：2026-06-08 21:36（Godot 4.6.1）。測試路徑：主畫面 → 收藏 → 卡牌收藏 / 家將圖鑑 / 神明好感。
## 截圖證據
- `/Users/crimson/Developer/COTIW/qa/collection_codex/01_main_menu.png`
- `/Users/crimson/Developer/COTIW/qa/collection_codex/02_collection_cards.png`
- `/Users/crimson/Developer/COTIW/qa/collection_codex/03_collection_jiajiang.png`
- `/Users/crimson/Developer/COTIW/qa/collection_codex/04_collection_deities.png`

## QA 摘要
- 收藏入口可進入，三個分頁可切換，沒有直接崩潰。
- `CodexMenu.gd` 的卡牌分頁目前把 `Global._id_to_card_data` 全部塞進收藏：實測顯示 100 張卡，包含大量 Slay-The-Robot legacy/debug 卡。這是最大污染源，醜得很準確。
- 卡牌截圖中前幾列仍是藍/綠/紅/橘純色底 + Godot 機器人 icon，且有英文描述，與鎮島錄美術語言完全斷裂。
- JSON/registry 稽核：86 張 JSON 卡中，68 張沒有可用 `cards_v3` / `card_texture_path` 正式素材；其中 active COTIW 角色缺 16 張（道士 8、家將 8），legacy/STR 可見卡缺 52 張。
- 家將與神明分頁的圖像都有載入，但文字只有「紅黑面 / 天后娘娘」等薄副標，沒有背景、職能、技能幻想；像展品標籤被砍到只剩價格牌。
- 神明分頁硬編 `mazu/guanyin/wangye/chenghuang/tudi/huye`，但資料檔只有 `deity_mazu/deity_chenghuang/deity_tudigong/deity_tiger_god` 四個；觀音/王爺只有 Codex 顯示，沒有資料源。
- 外部 deity JSON 的 `deity_texture_path` 指向 `assets/generated/deities/*.png`，實際不存在；現畫面靠 `deities_v3` registry 才沒破。日後資料驅動會踩雷。

## P0 建議
1. 收藏卡牌先過濾：只顯示 active COTIW packs/角色卡，不要把 `external/data/cards/str` debug 卡公開。若要保留 legacy，至少放到「開發/原型」隱藏分頁。
2. 立即補 `assets/generated/cards_v3/`：道士 8、家將 8 是玩家會直接看到的 active 缺口。
3. Codex 文本改資料驅動：卡牌顯示中文名 + 中文描述；家將/神明補 1 句 lore + 1 句戰鬥職能。
4. 統一路徑：把 deity JSON 指到 `assets/generated/deities_v3/{id}.png` 或建立 alias，否則匯出/資料驅動會破。

## Active COTIW 缺圖 Prompt（優先生成）
### card_daoshi_curse_seal｜咒封
- 建議輸出：`res://assets/generated/cards_v3/card_daoshi_curse_seal.png`
- 描述：施加 3 層邪氣於目標。
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 咒封 (card_daoshi_curse_seal), 道士, blue-white robe, Taoist hat, talismans, ritual authority, thunder and seals. Gameplay mood: 施加 3 層邪氣於目標。. Visual motifs: 黑紫咒氣、陰影符文、邪氣纏繞. Card type skill, rarity basic, energy cost 1. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_daoshi_fire_talisman｜火符
- 建議輸出：`res://assets/generated/cards_v3/card_daoshi_fire_talisman.png`
- 描述：造成 4 點傷害兩次。
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 火符 (card_daoshi_fire_talisman), 道士, blue-white robe, Taoist hat, talismans, ritual authority, thunder and seals. Gameplay mood: 造成 4 點傷害兩次。. Visual motifs: 神火、赤橙火舌、香灰火星. Card type attack, rarity basic, energy cost 1. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_daoshi_heavy_seal｜重符
- 建議輸出：`res://assets/generated/cards_v3/card_daoshi_heavy_seal.png`
- 描述：造成 12 點傷害。
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 重符 (card_daoshi_heavy_seal), 道士, blue-white robe, Taoist hat, talismans, ritual authority, thunder and seals. Gameplay mood: 造成 12 點傷害。. Visual motifs: 符紙飛散、硃砂符線、黃符靈光. Card type attack, rarity basic, energy cost 2. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_daoshi_open_altar｜開壇
- 建議輸出：`res://assets/generated/cards_v3/card_daoshi_open_altar.png`
- 描述：獲得 2 點神威。
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 開壇 (card_daoshi_open_altar), 道士, blue-white robe, Taoist hat, talismans, ritual authority, thunder and seals. Gameplay mood: 獲得 2 點神威。. Visual motifs: 符紙飛散、硃砂符線、黃符靈光. Card type power, rarity basic, energy cost 1. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_daoshi_summon_seal｜引符
- 建議輸出：`res://assets/generated/cards_v3/card_daoshi_summon_seal.png`
- 描述：抽 2 張牌。
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 引符 (card_daoshi_summon_seal), 道士, blue-white robe, Taoist hat, talismans, ritual authority, thunder and seals. Gameplay mood: 抽 2 張牌。. Visual motifs: 符紙飛散、硃砂符線、黃符靈光. Card type skill, rarity basic, energy cost 1. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_daoshi_talisman_bolt｜符箭
- 建議輸出：`res://assets/generated/cards_v3/card_daoshi_talisman_bolt.png`
- 描述：造成 6 點傷害。
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 符箭 (card_daoshi_talisman_bolt), 道士, blue-white robe, Taoist hat, talismans, ritual authority, thunder and seals. Gameplay mood: 造成 6 點傷害。. Visual motifs: 符紙飛散、硃砂符線、黃符靈光. Card type attack, rarity basic, energy cost 1. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_daoshi_thunder_talisman｜雷符
- 建議輸出：`res://assets/generated/cards_v3/card_daoshi_thunder_talisman.png`
- 描述：造成 14 點傷害。
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 雷符 (card_daoshi_thunder_talisman), 道士, blue-white robe, Taoist hat, talismans, ritual authority, thunder and seals. Gameplay mood: 造成 14 點傷害。. Visual motifs: 神火、赤橙火舌、香灰火星. Card type attack, rarity basic, energy cost 2. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_daoshi_ward_seal｜鎮符
- 建議輸出：`res://assets/generated/cards_v3/card_daoshi_ward_seal.png`
- 描述：獲得 6 點護身符。
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 鎮符 (card_daoshi_ward_seal), 道士, blue-white robe, Taoist hat, talismans, ritual authority, thunder and seals. Gameplay mood: 獲得 6 點護身符。. Visual motifs: 符紙飛散、硃砂符線、黃符靈光. Card type skill, rarity basic, energy cost 1. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_jiajiang_array_slam｜陣裂
- 建議輸出：`res://assets/generated/cards_v3/card_jiajiang_array_slam.png`
- 描述：造成 5 點傷害。
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 陣裂 (card_jiajiang_array_slam), 家將 martial temple guardian, opera face paint, red-gold armor, spear/flag/bell/formation power. Gameplay mood: 造成 5 點傷害。. Visual motifs: 陣法地紋、八卦線、隊列壓迫. Card type attack, rarity basic, energy cost 1. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_jiajiang_bell_purify｜淨鈴
- 建議輸出：`res://assets/generated/cards_v3/card_jiajiang_bell_purify.png`
- 描述：造成 5 點傷害，給予目標 1 層驚嚇。
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 淨鈴 (card_jiajiang_bell_purify), 家將 martial temple guardian, opera face paint, red-gold armor, spear/flag/bell/formation power. Gameplay mood: 造成 5 點傷害，給予目標 1 層驚嚇。. Visual motifs: 法鈴音波、金色震紋、淨化鈴光. Card type attack, rarity basic, energy cost 1. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_jiajiang_bell_ward｜鈴護
- 建議輸出：`res://assets/generated/cards_v3/card_jiajiang_bell_ward.png`
- 描述：獲得 7 點護身符。
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 鈴護 (card_jiajiang_bell_ward), 家將 martial temple guardian, opera face paint, red-gold armor, spear/flag/bell/formation power. Gameplay mood: 獲得 7 點護身符。. Visual motifs: 法鈴音波、金色震紋、淨化鈴光. Card type skill, rarity basic, energy cost 1. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_jiajiang_deploy｜列陣
- 建議輸出：`res://assets/generated/cards_v3/card_jiajiang_deploy.png`
- 描述：獲得 2 點神威。
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 列陣 (card_jiajiang_deploy), 家將 martial temple guardian, opera face paint, red-gold armor, spear/flag/bell/formation power. Gameplay mood: 獲得 2 點神威。. Visual motifs: 陣法地紋、八卦線、隊列壓迫. Card type power, rarity basic, energy cost 1. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_jiajiang_grand_formation｜大陣
- 建議輸出：`res://assets/generated/cards_v3/card_jiajiang_grand_formation.png`
- 描述：造成 10 點傷害。
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 大陣 (card_jiajiang_grand_formation), 家將 martial temple guardian, opera face paint, red-gold armor, spear/flag/bell/formation power. Gameplay mood: 造成 10 點傷害。. Visual motifs: 陣法地紋、八卦線、隊列壓迫. Card type attack, rarity basic, energy cost 2. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_jiajiang_heavy_fist｜重拳
- 建議輸出：`res://assets/generated/cards_v3/card_jiajiang_heavy_fist.png`
- 描述：造成 13 點傷害。
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 重拳 (card_jiajiang_heavy_fist), 家將 martial temple guardian, opera face paint, red-gold armor, spear/flag/bell/formation power. Gameplay mood: 造成 13 點傷害。. Visual motifs: 拳法衝擊、肉身破煞、金紅拳風. Card type attack, rarity basic, energy cost 2. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_jiajiang_vanguard_strike｜前鋒擊
- 建議輸出：`res://assets/generated/cards_v3/card_jiajiang_vanguard_strike.png`
- 描述：造成 7 點傷害。
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 前鋒擊 (card_jiajiang_vanguard_strike), 家將 martial temple guardian, opera face paint, red-gold armor, spear/flag/bell/formation power. Gameplay mood: 造成 7 點傷害。. Visual motifs: 拳法衝擊、肉身破煞、金紅拳風. Card type attack, rarity basic, energy cost 1. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_jiajiang_war_drum｜戰鼓
- 建議輸出：`res://assets/generated/cards_v3/card_jiajiang_war_drum.png`
- 描述：抽 2 張牌。
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 戰鼓 (card_jiajiang_war_drum), 家將 martial temple guardian, opera face paint, red-gold armor, spear/flag/bell/formation power. Gameplay mood: 抽 2 張牌。. Visual motifs: 法鈴音波、金色震紋、淨化鈴光. Card type skill, rarity basic, energy cost 1. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```

## Codex 家將 / 神明再生成或補一致性 Prompt
> 目前不缺圖，但若要統一風格/重生 cohort，請用下列 prompt。
### gan_general｜甘將軍
- 建議輸出：`res://assets/generated/jiajiang_v3/gan_general.png`
```text
pixel art anime full-body collectible codex portrait, 16-bit chunky shading, centered transparent/dark simple background, Taiwanese temple guardian aesthetic, consistent feet baseline, no text, no logo, no frame, mobile game readability. Subject: 甘將軍, red-black face general holding command flag and ritual blade. Subtitle mood: 紅黑面. Dramatic temple lantern lighting, strong silhouette, same canvas and scale as other eight generals. NO text, NO logo, NO frame.
```
### liu_general｜柳將軍
- 建議輸出：`res://assets/generated/jiajiang_v3/liu_general.png`
```text
pixel art anime full-body collectible codex portrait, 16-bit chunky shading, centered transparent/dark simple background, Taiwanese temple guardian aesthetic, consistent feet baseline, no text, no logo, no frame, mobile game readability. Subject: 柳將軍, green-faced scholar-warrior general with long beard and twin blades. Subtitle mood: 綠面儒將. Dramatic temple lantern lighting, strong silhouette, same canvas and scale as other eight generals. NO text, NO logo, NO frame.
```
### xie_general｜謝將軍
- 建議輸出：`res://assets/generated/jiajiang_v3/xie_general.png`
```text
pixel art anime full-body collectible codex portrait, 16-bit chunky shading, centered transparent/dark simple background, Taiwanese temple guardian aesthetic, consistent feet baseline, no text, no logo, no frame, mobile game readability. Subject: 謝將軍, white impermanence general, tall pale guardian with chain and fan. Subtitle mood: 白無常. Dramatic temple lantern lighting, strong silhouette, same canvas and scale as other eight generals. NO text, NO logo, NO frame.
```
### fan_general｜范將軍
- 建議輸出：`res://assets/generated/jiajiang_v3/fan_general.png`
```text
pixel art anime full-body collectible codex portrait, 16-bit chunky shading, centered transparent/dark simple background, Taiwanese temple guardian aesthetic, consistent feet baseline, no text, no logo, no frame, mobile game readability. Subject: 范將軍, black impermanence general, straw hat, fan, stern guardian. Subtitle mood: 黑無常. Dramatic temple lantern lighting, strong silhouette, same canvas and scale as other eight generals. NO text, NO logo, NO frame.
```
### spring_god｜春神
- 建議輸出：`res://assets/generated/jiajiang_v3/spring_god.png`
```text
pixel art anime full-body collectible codex portrait, 16-bit chunky shading, centered transparent/dark simple background, Taiwanese temple guardian aesthetic, consistent feet baseline, no text, no logo, no frame, mobile game readability. Subject: 春神, spring deity with peach blossoms and pink ribbons. Subtitle mood: 桃花面. Dramatic temple lantern lighting, strong silhouette, same canvas and scale as other eight generals. NO text, NO logo, NO frame.
```
### summer_god｜夏神
- 建議輸出：`res://assets/generated/jiajiang_v3/summer_god.png`
```text
pixel art anime full-body collectible codex portrait, 16-bit chunky shading, centered transparent/dark simple background, Taiwanese temple guardian aesthetic, consistent feet baseline, no text, no logo, no frame, mobile game readability. Subject: 夏神, summer deity with fire torch and blazing sun aura. Subtitle mood: 烈日面. Dramatic temple lantern lighting, strong silhouette, same canvas and scale as other eight generals. NO text, NO logo, NO frame.
```
### autumn_god｜秋神
- 建議輸出：`res://assets/generated/jiajiang_v3/autumn_god.png`
```text
pixel art anime full-body collectible codex portrait, 16-bit chunky shading, centered transparent/dark simple background, Taiwanese temple guardian aesthetic, consistent feet baseline, no text, no logo, no frame, mobile game readability. Subject: 秋神, autumn deity with golden armor and maple leaves. Subtitle mood: 金楓面. Dramatic temple lantern lighting, strong silhouette, same canvas and scale as other eight generals. NO text, NO logo, NO frame.
```
### winter_god｜冬神
- 建議輸出：`res://assets/generated/jiajiang_v3/winter_god.png`
```text
pixel art anime full-body collectible codex portrait, 16-bit chunky shading, centered transparent/dark simple background, Taiwanese temple guardian aesthetic, consistent feet baseline, no text, no logo, no frame, mobile game readability. Subject: 冬神, winter deity with frost-blue armor and snow branches. Subtitle mood: 雪霜面. Dramatic temple lantern lighting, strong silhouette, same canvas and scale as other eight generals. NO text, NO logo, NO frame.
```
### mazu｜媽祖
- 建議輸出：`res://assets/generated/deities_v3/mazu.png`
```text
pixel art anime full-body collectible codex portrait, 16-bit chunky shading, centered transparent/dark simple background, Taiwanese temple guardian aesthetic, consistent feet baseline, no text, no logo, no frame, mobile game readability. Subject: 媽祖, sea-protecting goddess with blue ocean aura and red-gold crown. Subtitle mood: 天后娘娘. Sacred aura, distinct iconography, same canvas and scale as deity cohort. NO text, NO logo, NO frame.
```
### guanyin｜觀音
- 建議輸出：`res://assets/generated/deities_v3/guanyin.png`
```text
pixel art anime full-body collectible codex portrait, 16-bit chunky shading, centered transparent/dark simple background, Taiwanese temple guardian aesthetic, consistent feet baseline, no text, no logo, no frame, mobile game readability. Subject: 觀音, white-robed bodhisattva with willow vase and moonlit compassion. Subtitle mood: 慈悲菩薩. Sacred aura, distinct iconography, same canvas and scale as deity cohort. NO text, NO logo, NO frame.
```
### wangye｜王爺
- 建議輸出：`res://assets/generated/deities_v3/wangye.png`
```text
pixel art anime full-body collectible codex portrait, 16-bit chunky shading, centered transparent/dark simple background, Taiwanese temple guardian aesthetic, consistent feet baseline, no text, no logo, no frame, mobile game readability. Subject: 王爺, royal plague-expelling deity, purple gold robes, command tablet. Subtitle mood: 代天巡狩. Sacred aura, distinct iconography, same canvas and scale as deity cohort. NO text, NO logo, NO frame.
```
### chenghuang｜城隍
- 建議輸出：`res://assets/generated/deities_v3/chenghuang.png`
```text
pixel art anime full-body collectible codex portrait, 16-bit chunky shading, centered transparent/dark simple background, Taiwanese temple guardian aesthetic, consistent feet baseline, no text, no logo, no frame, mobile game readability. Subject: 城隍, city god judge, dark blue robes, spirit court aura. Subtitle mood: 陰陽判官. Sacred aura, distinct iconography, same canvas and scale as deity cohort. NO text, NO logo, NO frame.
```
### tudi｜土地公
- 建議輸出：`res://assets/generated/deities_v3/tudi.png`
```text
pixel art anime full-body collectible codex portrait, 16-bit chunky shading, centered transparent/dark simple background, Taiwanese temple guardian aesthetic, consistent feet baseline, no text, no logo, no frame, mobile game readability. Subject: 土地公, smiling earth god elder with staff, ingot, local shrine. Subtitle mood: 福德正神. Sacred aura, distinct iconography, same canvas and scale as deity cohort. NO text, NO logo, NO frame.
```
### huye｜虎爺
- 建議輸出：`res://assets/generated/deities_v3/huye.png`
```text
pixel art anime full-body collectible codex portrait, 16-bit chunky shading, centered transparent/dark simple background, Taiwanese temple guardian aesthetic, consistent feet baseline, no text, no logo, no frame, mobile game readability. Subject: 虎爺, anthropomorphic tiger guardian, crouched temple beast, gold-red aura. Subtitle mood: 鎮殿神獸. Sacred aura, distinct iconography, same canvas and scale as deity cohort. NO text, NO logo, NO frame.
```

## Legacy / STR 可見卡缺圖 Prompt（若不過濾，就必須生成；否則請隱藏）
### add_health_card｜加元神
- 建議輸出：`res://assets/generated/cards_v3/add_health_card.png`
- 描述：+元神
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 加元神 (add_health_card), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: +元神. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### add_to_draw_from_discard_card｜添抽牌
- 建議輸出：`res://assets/generated/cards_v3/add_to_draw_from_discard_card.png`
- 描述：從棄牌堆加一張到抽牌堆
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 添抽牌 (add_to_draw_from_discard_card), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 從棄牌堆加一張到抽牌堆. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### attack_increase_cost_on_damage_taken_card｜受傷攻擊
- 建議輸出：`res://assets/generated/cards_v3/attack_increase_cost_on_damage_taken_card.png`
- 描述：受傷後神力消耗 +1
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 受傷攻擊 (attack_increase_cost_on_damage_taken_card), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 受傷後神力消耗 +1. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### attack_lower_cost_on_discard_card｜降費攻擊
- 建議輸出：`res://assets/generated/cards_v3/attack_lower_cost_on_discard_card.png`
- 描述：棄牌後神力消耗 -1
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 降費攻擊 (attack_lower_cost_on_discard_card), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 棄牌後神力消耗 -1. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### attack_with_conditional_block_card｜護擊
- 建議輸出：`res://assets/generated/cards_v3/attack_with_conditional_block_card.png`
- 描述：造成傷害並獲得護身符
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 護擊 (attack_with_conditional_block_card), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 造成傷害並獲得護身符. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### attack_with_conditional_draw_card｜抽牌攻擊
- 建議輸出：`res://assets/generated/cards_v3/attack_with_conditional_draw_card.png`
- 描述：造成傷害並抽牌
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 抽牌攻擊 (attack_with_conditional_draw_card), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 造成傷害並抽牌. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### block_if_exhaust_card｜消除護身符
- 建議輸出：`res://assets/generated/cards_v3/block_if_exhaust_card.png`
- 描述：消除時獲得護身符
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 消除護身符 (block_if_exhaust_card), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 消除時獲得護身符. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_attack_basic｜基礎攻擊
- 建議輸出：`res://assets/generated/cards_v3/card_attack_basic.png`
- 描述：造成 [damage] 點傷害 [number_of_attacks] 次
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 基礎攻擊 (card_attack_basic), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 造成 [damage] 點傷害 [number_of_attacks] 次. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_attack_big｜重攻擊
- 建議輸出：`res://assets/generated/cards_v3/card_attack_big.png`
- 描述：造成大量傷害
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 重攻擊 (card_attack_big), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 造成大量傷害. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_attack_heal_unblocked_damage｜癒擊
- 建議輸出：`res://assets/generated/cards_v3/card_attack_heal_unblocked_damage.png`
- 描述：造成傷害並回復未阻擋的傷害
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 癒擊 (card_attack_heal_unblocked_damage), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 造成傷害並回復未阻擋的傷害. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_attack_in_center｜陣前擊
- 建議輸出：`res://assets/generated/cards_v3/card_attack_in_center.png`
- 描述：中央敵人多 +傷害
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 陣前擊 (card_attack_in_center), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 中央敵人多 +傷害. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_attack_rng｜隨機攻擊
- 建議輸出：`res://assets/generated/cards_v3/card_attack_rng.png`
- 描述：隨機造成 [damage] - [damage_random] 點傷害
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 隨機攻擊 (card_attack_rng), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 隨機造成 [damage] - [damage_random] 點傷害. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_banish_attack｜驅逐攻擊
- 建議輸出：`res://assets/generated/cards_v3/card_banish_attack.png`
- 描述：造成傷害並驅逐
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 驅逐攻擊 (card_banish_attack), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 造成傷害並驅逐. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_block_big｜重護身符
- 建議輸出：`res://assets/generated/cards_v3/card_block_big.png`
- 描述：獲得大量護身符，消除
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 重護身符 (card_block_big), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 獲得大量護身符，消除. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_block_initial｜護身符卡
- 建議輸出：`res://assets/generated/cards_v3/card_block_initial.png`
- 描述：獲得 [block] 點護身符
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 護身符卡 (card_block_initial), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 獲得 [block] 點護身符. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_block_without_attacks｜守心
- 建議輸出：`res://assets/generated/cards_v3/card_block_without_attacks.png`
- 描述：不攻擊則獲得護身符
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 守心 (card_block_without_attacks), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 不攻擊則獲得護身符. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_cycle_enemy_intent｜驅意
- 建議輸出：`res://assets/generated/cards_v3/card_cycle_enemy_intent.png`
- 描述：改變敵人意圖
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 驅意 (card_cycle_enemy_intent), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 改變敵人意圖. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_debug_log｜除錯印
- 建議輸出：`res://assets/generated/cards_v3/card_debug_log.png`
- 描述：輸出 console 訊息
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 除錯印 (card_debug_log), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 輸出 console 訊息. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_discard_attacks_from_draw｜棄抽攻擊
- 建議輸出：`res://assets/generated/cards_v3/card_discard_attacks_from_draw.png`
- 描述：從抽牌堆棄所有攻擊
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 棄抽攻擊 (card_discard_attacks_from_draw), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 從抽牌堆棄所有攻擊. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_discard_block｜棄牌護身符
- 建議輸出：`res://assets/generated/cards_v3/card_discard_block.png`
- 描述：棄牌獲得護身符
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 棄牌護身符 (card_discard_block), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 棄牌獲得護身符. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_discard_hand｜棄全手
- 建議輸出：`res://assets/generated/cards_v3/card_discard_hand.png`
- 描述：棄掉所有手牌
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 棄全手 (card_discard_hand), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 棄掉所有手牌. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_draft_random_attack｜選張攻擊
- 建議輸出：`res://assets/generated/cards_v3/card_draft_random_attack.png`
- 描述：選一張攻擊加入牌組
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 選張攻擊 (card_draft_random_attack), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 選一張攻擊加入牌組. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_draft_random_player_pool｜亂抽
- 建議輸出：`res://assets/generated/cards_v3/card_draft_random_player_pool.png`
- 描述：從牌池隨機選一張
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 亂抽 (card_draft_random_player_pool), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 從牌池隨機選一張. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_draft_red_card｜選張紅卡
- 建議輸出：`res://assets/generated/cards_v3/card_draft_red_card.png`
- 描述：選一張紅色卡加入牌組
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 選張紅卡 (card_draft_red_card), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 選一張紅色卡加入牌組. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_energy_on_discard｜棄牌生力
- 建議輸出：`res://assets/generated/cards_v3/card_energy_on_discard.png`
- 描述：棄牌時 +神力
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 棄牌生力 (card_energy_on_discard), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 棄牌時 +神力. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_energy_on_draw｜抽中力
- 建議輸出：`res://assets/generated/cards_v3/card_energy_on_draw.png`
- 描述：抽到時 +神力
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 抽中力 (card_energy_on_draw), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 抽到時 +神力. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_generate_shoves｜震天舞
- 建議輸出：`res://assets/generated/cards_v3/card_generate_shoves.png`
- 描述：產生震開卡
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 震天舞 (card_generate_shoves), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 產生震開卡. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_grant_energy｜予力
- 建議輸出：`res://assets/generated/cards_v3/card_grant_energy.png`
- 描述：獲得 1 點神力
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 予力 (card_grant_energy), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 獲得 1 點神力. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_improving_attack｜進攻
- 建議輸出：`res://assets/generated/cards_v3/card_improving_attack.png`
- 描述：每次使用後傷害提升
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 進攻 (card_improving_attack), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 每次使用後傷害提升. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_improving_block｜強化護身符
- 建議輸出：`res://assets/generated/cards_v3/card_improving_block.png`
- 描述：每次使用後護身符量提升
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 強化護身符 (card_improving_block), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 每次使用後護身符量提升. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_law｜律令
- 建議輸出：`res://assets/generated/cards_v3/card_law.png`
- 描述：施加狀態效果
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 律令 (card_law), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 施加狀態效果. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_pick_from_discard｜拾棄牌
- 建議輸出：`res://assets/generated/cards_v3/card_pick_from_discard.png`
- 描述：從棄牌堆選一張回手
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 拾棄牌 (card_pick_from_discard), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 從棄牌堆選一張回手. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_play_from_discard｜棄堆出牌
- 建議輸出：`res://assets/generated/cards_v3/card_play_from_discard.png`
- 描述：從棄牌堆使用一張牌
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 棄堆出牌 (card_play_from_discard), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 從棄牌堆使用一張牌. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_play_random_from_hand｜亂出
- 建議輸出：`res://assets/generated/cards_v3/card_play_random_from_hand.png`
- 描述：隨機出一張手牌
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 亂出 (card_play_random_from_hand), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 隨機出一張手牌. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_requires_adjacency｜鄰擊
- 建議輸出：`res://assets/generated/cards_v3/card_requires_adjacency.png`
- 描述：敵人有鄰居才能出
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 鄰擊 (card_requires_adjacency), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 敵人有鄰居才能出. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_restart_combat｜重戰
- 建議輸出：`res://assets/generated/cards_v3/card_restart_combat.png`
- 描述：重置戰鬥
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 重戰 (card_restart_combat), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 重置戰鬥. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_right_click_transform_mode_a｜模式 A
- 建議輸出：`res://assets/generated/cards_v3/card_right_click_transform_mode_a.png`
- 描述：可右鍵變換
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 模式 A (card_right_click_transform_mode_a), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 可右鍵變換. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_right_click_transform_mode_b｜模式 B
- 建議輸出：`res://assets/generated/cards_v3/card_right_click_transform_mode_b.png`
- 描述：可右鍵變換
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 模式 B (card_right_click_transform_mode_b), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 可右鍵變換. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_shove｜震開
- 建議輸出：`res://assets/generated/cards_v3/card_shove.png`
- 描述：震退敵人
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 震開 (card_shove), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 震退敵人. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_special_discard｜特別棄牌
- 建議輸出：`res://assets/generated/cards_v3/card_special_discard.png`
- 描述：棄一張牌並獲得效果
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 特別棄牌 (card_special_discard), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 棄一張牌並獲得效果. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### card_upgrade_card｜升級卡
- 建議輸出：`res://assets/generated/cards_v3/card_upgrade_card.png`
- 描述：升級一張手牌
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 升級卡 (card_upgrade_card), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 升級一張手牌. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### cards_played_attack_card｜牌效攻擊
- 建議輸出：`res://assets/generated/cards_v3/cards_played_attack_card.png`
- 描述：傷害取決於本回合出牌數
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 牌效攻擊 (cards_played_attack_card), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 傷害取決於本回合出牌數. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### custom_block_card｜自訂護身符
- 建議輸出：`res://assets/generated/cards_v3/custom_block_card.png`
- 描述：獲得護身符
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 自訂護身符 (custom_block_card), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 獲得護身符. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### end_turn_card｜結束回合
- 建議輸出：`res://assets/generated/cards_v3/end_turn_card.png`
- 描述：立刻結束回合
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 結束回合 (end_turn_card), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 立刻結束回合. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### improving_retain_block_card｜持續護身符
- 建議輸出：`res://assets/generated/cards_v3/improving_retain_block_card.png`
- 描述：護身符不結算消失
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 持續護身符 (improving_retain_block_card), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 護身符不結算消失. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### randomize_hand_card｜亂費
- 建議輸出：`res://assets/generated/cards_v3/randomize_hand_card.png`
- 描述：隨機重設手牌神力
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 亂費 (randomize_hand_card), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 隨機重設手牌神力. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### retain_hand_card｜持手
- 建議輸出：`res://assets/generated/cards_v3/retain_hand_card.png`
- 描述：本回合保留手牌
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 持手 (retain_hand_card), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 本回合保留手牌. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### self_attaching_attack_card｜纏身攻擊
- 建議輸出：`res://assets/generated/cards_v3/self_attaching_attack_card.png`
- 描述：黏附於敵人造成持續傷害
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 纏身攻擊 (self_attaching_attack_card), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 黏附於敵人造成持續傷害. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### set_hand_energy_card｜歸零神力
- 建議輸出：`res://assets/generated/cards_v3/set_hand_energy_card.png`
- 描述：本回合所有手牌神力 0
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 歸零神力 (set_hand_energy_card), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 本回合所有手牌神力 0. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### transform_hand_card｜變換手牌
- 建議輸出：`res://assets/generated/cards_v3/transform_hand_card.png`
- 描述：變換所有手牌
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 變換手牌 (transform_hand_card), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 變換所有手牌. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### upgrade_entire_deck_card｜升級全戰場
- 建議輸出：`res://assets/generated/cards_v3/upgrade_entire_deck_card.png`
- 描述：升級戰鬥所有卡
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 升級全戰場 (upgrade_entire_deck_card), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 升級戰鬥所有卡. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
### variable_cost_attack_card｜變費攻擊
- 建議輸出：`res://assets/generated/cards_v3/variable_cost_attack_card.png`
- 描述：消耗所有神力造成等量傷害
- Prompt:
```text
pixel art anime game card illustration, 16-bit chunky shading, crisp silhouette, Taiwanese temple supernatural roguelike, dark night-market shrine atmosphere, red gold teal palette, no text, no logo, no UI frame, centered composition, high readability at small mobile card size, 2:3 vertical card art. Subject: 變費攻擊 (variable_cost_attack_card), 鎮島錄 converted legacy card, Taiwanese temple ritual object replacing generic robot prototype. Gameplay mood: 消耗所有神力造成等量傷害. Visual motifs: ritual energy and temple incense. Card type unknown, rarity unknown, energy cost None. Dynamic action pose, strong foreground object, readable value fantasy. NO text, NO English words, NO card border, NO watermark, NO blurry painterly poster, NO photorealism, NO generic sci-fi robot, NO extra fingers
```
