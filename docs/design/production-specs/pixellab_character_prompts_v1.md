# PixelLab 角色 Prompt 規格 v1 — 鎮島錄 COTIW

> 目的：把目前角色選單 / PRD / 現有立繪整理成可直接丟給 PixelLab 的角色圖與戰鬥動畫 prompt。
> 這份不是「差不多能看」的廢紙；它是約束身份、輪廓、動作與輸出規格的生產稿。

## 共通輸出規格

- Canvas：512 × 512
- 背景：透明
- 方向：角色面向右側 / east，前 3/4 戰鬥姿態
- 用途：Godot 橫向手機戰鬥，必須 0.3 秒讀得出輪廓
- 動畫狀態：idle / attack / defend / hit / death
- 幀數建議：idle 6、attack 6、defend 4、hit 4、death 6
- 命名：`assets/generated/pixellab/anim/<actor_id>/<state>.png` 或拆幀後 `<actor_id>__<state>__fNN.png`

### Common style prompt

```text
Temple Neon Pixel, bright chibi Taiwanese folk roguelike card battler, HD-2D 16-bit pixel art with chunky readable shapes, red temple lacquer, incense gold rim light, neon cyan spirit accents, crisp silhouette, front three-quarter combat pose, mobile-game readability, no text, no UI frame, transparent background, single centered full-body character, consistent floor baseline, 512x512 canvas
```

### Negative prompt

```text
no western medieval armor, no Japanese shrine maiden drift, no photorealism, no soft painterly poster, no tiny unreadable details, no background scene, no logo, no text, no card frame, no cropped body, no extra characters, no gore
```

## 乩童（Tongji / Spirit Medium）

- ID：`character_tongji`
- 參考圖：`assets/generated/portraits_v3/tongji.png`
- 狀態：已實作 / 預設解鎖
- 機制幻想：附體、爆發、自傷換傷害；玩家一眼要讀成近戰狂戰士。
- 身份鎖：red headband, bare torso or open ritual vest, red-gold ritual sash, temple talismans, possessed warrior eyes, explosive low-center stance
- 色彩：festival red, incense gold, hot orange divine aura, small cyan spirit sparks

### Base description

```text
Temple Neon Pixel, bright chibi Taiwanese folk roguelike card battler, HD-2D 16-bit pixel art with chunky readable shapes, red temple lacquer, incense gold rim light, neon cyan spirit accents, crisp silhouette, front three-quarter combat pose, mobile-game readability, no text, no UI frame, transparent background, single centered full-body character, consistent floor baseline, 512x512 canvas. A young Taiwanese spirit medium warrior possessed by a temple god, red headband, ritual sash, talismans whipping in divine wind, bare powerful arms, fierce but chibi-readable expression, explosive forward stance. Identity lock: red headband, bare torso or open ritual vest, red-gold ritual sash, temple talismans, possessed warrior eyes, explosive low-center stance. Palette: festival red, incense gold, hot orange divine aura, small cyan spirit sparks.
```

### Animation actions

#### `idle`

```text
Low ritual stance, feet planted like a temple palanquin step, chest breathing, talismans and red sash subtly flutter, divine aura pulsing around fists.
```

#### `attack`

```text
Explosive short dash punch or elbow strike, red-gold divine afterimage, talismans streak backward, impact arc clear and readable.
```

#### `defend`

```text
Crouched bracing stance, crossed forearms, paper talisman shield blooming in front, body compact but silhouette still recognizable.
```

#### `hit`

```text
Upper body snaps back from impact, sash and talismans thrown upward, one foot sliding, expression strained but not comedic.
```

#### `death`

```text
Divine possession leaves the body, knees drop to ground, red-gold aura extinguishes into incense ash, still dignified not grotesque.
```

## 鸞女（Luannu / Oracle Maiden）

- ID：`character_luannu`
- 參考圖：`assets/generated/portraits_v3/luannu.png`
- 狀態：已實作 / 預設解鎖
- 機制幻想：靈符、聖火、祈福續航；要優雅穩定，但不是柔弱花瓶。
- 身份鎖：black hair, red-gold ceremonial crown, jade accent, oracle maiden silhouette, spirit brush, talisman sleeves, sacred flame
- 色彩：temple red, old gold, jade green, holy flame orange, controlled cyan glow

### Base description

```text
Temple Neon Pixel, bright chibi Taiwanese folk roguelike card battler, HD-2D 16-bit pixel art with chunky readable shapes, red temple lacquer, incense gold rim light, neon cyan spirit accents, crisp silhouette, front three-quarter combat pose, mobile-game readability, no text, no UI frame, transparent background, single centered full-body character, consistent floor baseline, 512x512 canvas. A Taiwanese oracle maiden from a luan hall, black hair, red-gold ceremonial crown with jade accent, flowing talisman sleeves, spirit brush and holy fire, calm sacred authority, elegant full-body combat silhouette. Identity lock: black hair, red-gold ceremonial crown, jade accent, oracle maiden silhouette, spirit brush, talisman sleeves, sacred flame. Palette: temple red, old gold, jade green, holy flame orange, controlled cyan glow.
```

### Animation actions

#### `idle`

```text
Upright calm stance, spirit brush held near chest, talismans and small holy flames orbit slowly, robe hem breathing gently.
```

#### `attack`

```text
Brush stroke sends a talisman flame forward, clear sweeping arm motion, golden-orange fire trail, composed face and readable casting silhouette.
```

#### `defend`

```text
Circular talisman array opens like a protective fire shield, both hands guiding the ward, jade-gold light rim around her body.
```

#### `hit`

```text
Steps back half a pace, sleeves and talismans jolted open, sacred flame flickers but does not vanish, expression briefly shocked.
```

#### `death`

```text
Holy fire dims, brush lowers, she kneels or folds gracefully as talismans fall like ash, solemn and elegant.
```

## 道士（Daoshi / Taoist Priest）

- ID：`character_daoshi`
- 參考圖：`assets/generated/portraits_v3/daoshi.png`
- 狀態：累計 3 勝後開壇 / 未接 JSON
- 機制幻想：符陣、buff/debuff、控場組合技；看起來要像操盤者，不是近戰砍人。
- 身份鎖：Taoist hat, blue-white robe, wooden sword or staff, yellow talismans, bagua charm, ritual authority, scholar-warlock posture
- 色彩：blue-white robe, yellow talisman paper, incense gold, cyan ghost-light, dark lacquer shadows

### Base description

```text
Temple Neon Pixel, bright chibi Taiwanese folk roguelike card battler, HD-2D 16-bit pixel art with chunky readable shapes, red temple lacquer, incense gold rim light, neon cyan spirit accents, crisp silhouette, front three-quarter combat pose, mobile-game readability, no text, no UI frame, transparent background, single centered full-body character, consistent floor baseline, 512x512 canvas. A Taiwanese Taoist priest strategist, traditional Taoist hat, blue-white ritual robe, wooden sword and yellow talismans, bagua charm glow, calm tactical eyes, mid-range spellcaster stance, strong game-unit silhouette. Identity lock: Taoist hat, blue-white robe, wooden sword or staff, yellow talismans, bagua charm, ritual authority, scholar-warlock posture. Palette: blue-white robe, yellow talisman paper, incense gold, cyan ghost-light, dark lacquer shadows.
```

### Animation actions

#### `idle`

```text
Balanced spellcaster stance, wooden sword angled downward, talismans floating in a small orbit, bagua glow breathing under feet.
```

#### `attack`

```text
Snaps a talisman forward with wooden sword guidance, cyan-gold spell line shoots outward, robe sleeve creates clean diagonal motion.
```

#### `defend`

```text
Raises wooden sword and forms a bagua ward, yellow talismans lock into octagon shield, posture disciplined and compact.
```

#### `hit`

```text
Robe and hat jolt, one talisman burns out, body slides back while sword remains in hand, silhouette stays readable.
```

#### `death`

```text
Bagua formation collapses, talismans fall unlit, priest sinks to one knee with wooden sword touching ground, quiet ritual failure.
```

## 家將（Jiajiang / Family General）

- ID：`character_jiajiang`
- 參考圖：`assets/generated/portraits_v3/jiajiang.png`
- 狀態：累計 8 勝後開壇 / 未接 JSON
- 機制幻想：陣型、前線壓場、高風險連擊；要像陣頭神將壓上來。
- 身份鎖：Eight Generals face paint, flaming headdress, red-gold armor cloth, spear or ritual weapon, guardian stance, procession energy
- 色彩：lacquer red, incense gold, black face-paint lines, flame orange, cyan omen rim

### Base description

```text
Temple Neon Pixel, bright chibi Taiwanese folk roguelike card battler, HD-2D 16-bit pixel art with chunky readable shapes, red temple lacquer, incense gold rim light, neon cyan spirit accents, crisp silhouette, front three-quarter combat pose, mobile-game readability, no text, no UI frame, transparent background, single centered full-body character, consistent floor baseline, 512x512 canvas. A chibi but powerful Taiwanese Eight Generals temple guardian, dramatic opera face paint, flaming headdress, red-gold ritual armor cloth, spear and shield stance, procession warrior energy, bold intimidating silhouette. Identity lock: Eight Generals face paint, flaming headdress, red-gold armor cloth, spear or ritual weapon, guardian stance, procession energy. Palette: lacquer red, incense gold, black face-paint lines, flame orange, cyan omen rim.
```

### Animation actions

#### `idle`

```text
Wide guardian stance, spear grounded, shoulder ornaments and flame headdress flicker, face paint readable, heavy rhythmic breathing.
```

#### `attack`

```text
Surging spear thrust or shield bash, red-gold flame trail, procession-step footwork, large clear impact shape for mobile readability.
```

#### `defend`

```text
Plants shield or ritual weapon forward, body square to enemy, guardian ward flare around armor, unwavering stance.
```

#### `hit`

```text
Armor cloth snaps from impact, head turns slightly but stance resists collapse, sparks and face-paint lines remain clear.
```

#### `death`

```text
Guardian flame gutters out, spear drops, heavy kneel with procession ornaments falling still, heroic defeat not ragdoll.
```

## PixelLab API payload 位置

完整 JSON batch 已輸出：`assets/generated/pixellab/character_prompt_batch_v1.json`

## 美術判斷

- 乩童要最粗暴，低重心和紅金殘影是核心；別讓模型畫成普通少年劍士。
- 鸞女要穩、神聖、可戰鬥；漂亮不等於能用，袖口與符火要支撐動作輪廓。
- 道士必須讀成「操盤控場」，法器與八卦陣是主語，不是配件。
- 家將要大輪廓、大面具、大步伐；小細節可以犧牲，陣頭壓迫感不能丟。