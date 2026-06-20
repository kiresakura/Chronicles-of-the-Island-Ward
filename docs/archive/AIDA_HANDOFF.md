# Aida 開發交接說明

Aida，這不是讓你自由發揮審美的地方。

你現在要做的是把 `docs/design/` 裡的設計系統，穩定地落進 Godot UI。

## 你要先看
1. `docs/design/COTIW_UI_UX_ART_DIRECTION.md`
2. `docs/design/design_tokens.json`
3. `docs/design/asset_manifest.md`
4. `docs/design/production-specs/asset_naming_and_structure.md`
5. `docs/design/production-specs/card_system_spec.md`
6. `docs/design/production-specs/button_and_panel_spec.md`
7. `docs/design/production-specs/hud_and_map_spec.md`
8. `docs/design/production-specs/fx_spec.md`
9. `docs/design/production-specs/b2_component_specs.md`
10. `docs/design/production-specs/b2_ai_art_batch_v1.md`
11. `docs/design/production-specs/ui_asset_registry.json`
12. `docs/design/production-specs/templates/*.svg`
13. `docs/design/wireframes/*.svg`

## 實作順序
1. 建立共用 theme tokens / 常數
2. 實作共用按鈕與 panel
3. 完成主選單
4. 完成戰鬥 HUD
5. 完成地圖與節點
6. 完成 reward / shop / rest overlay
7. 補 tooltip / pause / summary

## 不要做的事
- 不要把畫面做成泛日系和風 RPG
- 不要改回 desktop 優先版面
- 不要在每個 scene 各自寫一套 style
- 不要讓金色字壓在花背景上看不清
- 不要為了炫技犧牲可讀性

## 驗收標準
- 1200×700 橫向下可用（2026-05-19 定案橫向）
- 小尺寸手機上字仍可讀
- 所有主要按鈕有明確 disabled / pressed / selected state
- 戰鬥資訊比特效優先
- 一眼看得出是台灣廟會題材
