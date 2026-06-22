# 神示供桌 — 素材生成 prompt 集（Temple Neon Pixel）

> 給美術管線（pixellab / recraft / 同級像素圖模型）。**每個 prompt 都先貼 §0 共用風格前綴**,確保全套視覺一致。尺寸後綴 `@2x` 表示可出兩倍解析度再縮。路徑沿用 repo 既有 `assets/generated/...` 慣例。

## 0. 共用風格前綴（貼在每個 prompt 最前面）
```
[STYLE] Pixel art, Taiwanese folk-temple (廟會/宮廟) aesthetic. Palette: deep lacquer
red #8e2a1c, incense gold #e8c46a, warm paper cream #f0e4c8, ink-lacquer black #1a0f0d,
jade #46c99a accent. Candle-lit, atmospheric, slightly sacred and tense. Hand-shaded
pixels, crisp edges, no blur/anti-alias. Restrained warm glow ONLY on sacred/rare items.
[NEGATIVE] no text, no letters, no watermark, no signature, no modern UI, no flat vector,
no photoreal, no bright daylight, no cartoon outline.
```

## 1. 供桌主背景（取代洗白的 run_start_offering_bg_v2）
- **用途:** RSO 神示供桌全幕底圖;中央須**淨空**留給四支籤詩並立。
- **尺寸/底:** 1200×700 @2x,不透明。**路徑:** `assets/generated/scenes_v2/run_start_offering_bg_v3.png`
```
[STYLE…] A dim night temple interior. A heavy carved wooden offering table draped with a
deep-red embroidered cloth runs across the lower third. On the table: a tall bamboo
fortune-stick cylinder (籤筒) packed with slips, a brass incense burner with thin curling
smoke, two red candles with soft glowing flames, a pair of red crescent divination blocks
(筊杯). Behind: a shadowed shrine niche, hanging red lanterns, faint gold deity silhouette.
Composition: CENTER and upper-middle kept dark and empty (negative space) for UI cards;
warm light pools at table and candles; deep vignette at edges. Moody, reverent.
```

## 2. 籤筒（道具,可獨立疊用）
- **尺寸/底:** 256×384 @2x,透明。**路徑:** `assets/generated/props/prop_fortune_cylinder.png`
```
[STYLE…] A single tall cylindrical bamboo fortune-stick holder (籤筒), weathered red
lacquer body with faint gold rim, packed with many thin numbered bamboo slips fanning
slightly. Soft candle rim-light on the left. Standalone object, transparent background.
```

## 3. 籤詩直條框 — 五籤運各一（最重要,決定「稀有被慶祝」）
- **用途:** 四選一籤卡的底框,依籤運換框。可做 9-slice。
- **尺寸/底:** 200×420 @2x,透明。**路徑:** `assets/generated/ui/qian_frame_{tier}.png`
- 五個 tier 各跑一次,把下面 `{TIER}` 段替換:

| tier 檔名 | `{TIER}` 替換內容 |
|---|---|
| `qian_frame_shangshang`（上上） | radiant gold frame, glowing engraved filigree, a small sunburst crest at top, faint warm halo bleeding past the border |
| `qian_frame_shangji`（上吉） | jade-green lacquer frame with gold inlay, gentle clean glow |
| `qian_frame_zhongping`（中平） | warm cream paper slip in a plain bronze-gold frame, calm, no glow |
| `qian_frame_zhongxia`（中下） | dull bronze frame, slightly worn paper, muted |
| `qian_frame_xiaxia`（下下） | ashen grey weathered frame, hairline cracks, dim, a whisper of cold shadow |
```
[STYLE…] A vertical temple oracle paper slip (籤) shaped like a tall narrow tablet, empty
center (no text), ornate header band at top in vermilion, twin gold rule lines near the
bottom. Frame style: {TIER}. Standalone, transparent background, symmetrical, 9-slice safe.
```

## 4. 擲筊筊杯（三態,呼應 JiaoBeiFX）
- **尺寸/底:** 96×96 @2x,透明。**路徑:** `assets/generated/fx/jiaobei_{state}.png`
- 三態:`sheng`(一凸一平=聖筊)、`xiao`(雙平=笑筊)、`yin`(雙凸=陰筊)。
```
[STYLE…] A pair of crescent moon-shaped wooden divination blocks (筊杯), red lacquer with
worn gold edges, lying on dark ground. State: {一凸一平 / 雙平面朝上 / 雙凸面朝上}. Soft
candle rim-light, small contact shadow. Transparent background.
```

## 5. 神示金光 v2（取代 offering_omen_glow_v1,更亮更聖）
- **尺寸/底:** 512×512 @2x,透明,additive 用。**路徑:** `assets/generated/fx/offering_omen_glow_v2.png`
```
[STYLE…] A radiant burst of warm golden divine light, soft rays and floating embers/incense
motes, concentric faint halo, brightest at center fading to transparent edges. For additive
blending over a dark scene. No object, just light. Transparent background.
```

## 6. 香煙 + 燭火（氣氛 VFX sprite sheet）
- 香煙:128×512 @2x 直向 4-frame 循環,透明。**路徑:** `assets/generated/fx/incense_smoke_sheet.png`
- 燭火:64×96 @2x 4-frame 循環,透明。**路徑:** `assets/generated/fx/candle_flame_sheet.png`
```
[STYLE…] (香煙) Four vertical frames of a single thin wisp of incense smoke curling and
drifting upward, translucent grey-blue, loopable. Transparent background.
[STYLE…] (燭火) Four frames of a small warm candle flame flickering, soft glow, loopable.
Transparent background.
```

## 7. 籤運印章/飾章 ×5（籤首角標,可選增量）
- **尺寸/底:** 64×64 @2x,透明。**路徑:** `assets/generated/ui/qian_seal_{tier}.png`
```
[STYLE…] A small circular temple seal/stamp emblem for a fortune tier, vermilion and gold,
ornamental. Tier mood: {上上=radiant sunburst gold / 上吉=jade auspicious / 中平=plain
bronze / 中下=muted / 下下=ashen cracked}. Transparent background, no text.
```

## 8. 利/忌 資源圖示組（一秒讀懂的關鍵）
- **尺寸/底:** 48×48 @2x,透明,2–3 色高辨識。**路徑:** `assets/generated/icons_v2/res_{name}.png`
- 一次出一組,風格一致:
  - `res_silver`（銀兩）— a stack of old Chinese silver sycee/coins
  - `res_yuanshen`（元神）— a glowing soul ember / spirit flame in cupped form
  - `res_yuanshen_cap`（元神上限）— the soul ember inside a ring/gauge
  - `res_incense`（香火）— an incense stick with rising ember
  - `res_card`（普通卡）— a single talisman paper card (符)
  - `res_relic`（大醮遺物）— an ornate ritual relic/amulet
  - `res_shop`（商店）— a small night-market stall lantern
  - `res_node`（地圖節點）— a temple gate waypoint marker
```
[STYLE…] A single small game resource icon: {上面該項描述}. Centered, bold readable
silhouette, 2–3 colors, warm temple palette, gold rim. Transparent background, no text.
```

## 9. 乩童反應立繪 ×2（可選,提升臨場感）
- **尺寸/底:** 252×432（對齊 RSO presenter 尺寸）@2x,透明。**路徑:** `assets/generated/portraits_v3/tongji_{mood}.png`
```
[STYLE…] Full-body pixel portrait of the existing 乩童 character (bare-chested martial
medium, red trousers, head cloth), standing beside an offering table, gesturing toward it.
Mood: {振奮=elated, eyes lit, presenting a great omen / 凝重=solemn, braced for an ill omen}.
Match existing character design. Transparent background.
```

---
**整合備註(給 Claude Code):** 生成後丟對應路徑、在 `RunStartOptions.gd` 換掉 `OFFERING_BG_PATH`→v3、`OMEN_GLOW`→v2、依籤運套 `qian_frame_{tier}`;所有路徑字串集中、走 `ResourceLoader.exists` 找不到就回退(沿用現有寫法)。風格一致性以 §0 前綴保證。
