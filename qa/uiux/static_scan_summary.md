# COTIW UI/UX static scan

## scripts/ui/menus/MainMenu.gd
lines=887
counts: {'position = Vector2': 26, 'size = Vector2': 24, 'offset_': 7, 'safe': 21, 'button_up': 27, 'button_down': 1, 'mouse_filter': 16, 'visible =': 8, 'CanvasLayer': 3, 'layer =': 1, 'z_index': 4, 'font_size': 2, 'text =': 11}
140: _pixel_bg.size = Vector2(1200, 700)
268: _mascot_panel.position = Vector2.ZERO
301: _pixel_bg.position = Vector2.ZERO
308: _pixel_altar.size = Vector2(altar_w, altar_h)
309: _pixel_altar.position = Vector2((stage_size.x - altar_w) * 0.5, stage_size.y * 0.12)
313: _mascot_panel.position = Vector2.ZERO
318: _hotspot_censer.position = Vector2(stage_size.x * 0.55, stage_size.y * 0.72)
319: _hotspot_censer.size = Vector2(stage_size.x * 0.10, stage_size.y * 0.14)
321: _hotspot_lantern.position = Vector2(stage_size.x * 0.72, stage_size.y * 0.06)
322: _hotspot_lantern.size = Vector2(stage_size.x * 0.08, stage_size.y * 0.12)
328: _activity_banner.size = Vector2(bw, bh)
329: _activity_banner.position = Vector2(stage_size.x - bw - 40,
333: _activity_banner_label.size = Vector2(bw, bh)
334: _activity_banner_label.position = Vector2.ZERO
337: child.size = Vector2(bw, bh)
338: child.position = Vector2.ZERO
347: _pixel_title.size = Vector2(title_w, title_h)
348: _pixel_title.position = Vector2((stage_size_t.x - title_w) * 0.5, stage_size_t.y * 0.02)
... 36 more

## scripts/ui/menus/NewRunMenu.gd
lines=447
counts: {'position = Vector2': 9, 'size = Vector2': 10, 'custom_minimum_size': 2, 'safe': 14, 'button_up': 6, 'mouse_filter': 4, 'visible =': 2, 'queue_free': 1, 'z_index': 2, 'font_size': 5, 'text =': 24}
139: _info_heading_label.add_theme_font_size_override("font_size", 16)
146: _run_heading_label.add_theme_font_size_override("font_size", 16)
154: _selection_bridge.add_theme_font_size_override("font_size", 13)
169: _start_hint_label.add_theme_font_size_override("font_size", 14)
207: _character_gallery.position = Vector2(gallery_x, gallery_y)
208: _character_gallery.size = Vector2(gallery_w, gallery_h)
210: _character_info_panel.position = Vector2(left_x - 8.0, info_y - 10.0)
211: _character_info_panel.size = Vector2(left_w + 16.0, info_h)
213: _run_guide_panel.position = Vector2(guide_x, guide_y)
214: _run_guide_panel.size = Vector2(guide_w, guide_h)
216: _info_heading_label.position = Vector2(left_x + 4.0, info_y - 6.0)
217: _info_heading_label.size = Vector2(left_w - 8.0, 24.0)
219: _run_heading_label.position = Vector2(guide_x + 16.0, guide_y + 10.0)
220: _run_heading_label.size = Vector2(160.0, 24.0)
222: _selection_bridge.position = Vector2(gallery_x - 12.0, gallery_y + gallery_h + 2.0)
223: _selection_bridge.size = Vector2(gallery_w + 24.0, 20.0)
225: _character_tags_flow.position = Vector2(left_x, info_y + 330.0)
226: _character_tags_flow.size = Vector2(left_w - 16.0, 72.0)
... 6 more

## scripts/ui/Combat.gd
lines=763
counts: {'position = Vector2': 2, 'size = Vector2': 2, 'offset_': 16, 'anchor_': 9, 'button_up': 10, 'mouse_filter': 3, 'visible =': 14, 'layer =': 3, 'font_size': 3, 'text =': 12}
557: bg.offset_left = 0.0
558: bg.offset_top = 0.0
559: bg.offset_right = 1200.0
560: bg.offset_bottom = 700.0
605: _combat_status_label.position = Vector2(420.0, 8.0)
606: _combat_status_label.size = Vector2(360.0, 34.0)
607: _combat_status_label.add_theme_font_size_override("font_size", 24)
637: _combat_toast.position = Vector2(400.0, 300.0)
638: _combat_toast.size = Vector2(400.0, 50.0)
639: _combat_toast.add_theme_font_size_override("font_size", 30)
685: _invoke_button.offset_left = -95.0
686: _invoke_button.offset_right = 95.0
688: _invoke_button.offset_top = 46.0
689: _invoke_button.offset_bottom = 80.0
690: _invoke_button.add_theme_font_size_override("font_size", 16)

## scripts/ui/Hand.gd
lines=1072
counts: {'position = Vector2': 4, 'size = Vector2': 1, 'offset_': 2, 'anchor_': 2, 'long_press': 2, 'button_up': 7, 'mouse_filter': 3, 'visible =': 9, 'queue_free': 4, 'z_index': 3, 'font_size': 1, 'text =': 2}
165: new_position = Vector2(middle + (CARD_WIDTH / 2), 0)
178: new_position = Vector2(card_x_offset, card_y_offset)
183: new_position = Vector2(middle + CARD_SEPERATION_WIDTH * CARD_PICK_POSITIONS[picked_card_count - 1][pick_index], CARD_PICK_Y_OFFSET)
330: _cancel_target_button.size = Vector2(160, 54)
332: _cancel_target_button.add_theme_font_size_override("font_size", 26)
336: _cancel_target_button.position = Vector2(520, 250)

## scripts/ui/Card.gd
lines=386
counts: {'offset_': 14, 'safe': 1, 'long_press': 5, 'button_up': 4, 'button_down': 1, 'visible =': 4, 'queue_free': 5, 'layer =': 2, 'text =': 4}
127: card_name.offset_top    = 102.0
128: card_name.offset_bottom = 118.0
131: desc_bg.offset_top    = 107.0
132: desc_bg.offset_bottom = 180.0
135: card_description.offset_top = 122.0
137: card_type.offset_left  = 82.0
138: card_type.offset_top   = 3.0
139: card_type.offset_right = 140.0
140: card_type.offset_bottom = 14.0
160: card_color.offset_top    = 0.0
161: card_color.offset_left   = 0.0
162: card_color.offset_right  = 144.0
163: card_color.offset_bottom = 107.0

## scripts/ui/Map.gd
lines=349
counts: {'position = Vector2': 5, 'size = Vector2': 6, 'custom_minimum_size': 1, 'offset_': 2, 'anchor_': 6, 'button_up': 6, 'mouse_filter': 8, 'visible =': 2, 'queue_free': 4, 'layer =': 10, 'z_index': 4, 'font_size': 1, 'text =': 1}
195: holder.position = Vector2(boss_center.x - 210.0, maxf(0.0, boss_center.y - 202.0))
196: holder.size = Vector2(420.0, 232.0)
203: shadow.position = Vector2(0.0, 12.0)
204: shadow.size = Vector2(420.0, 220.0)
212: pillar.position = Vector2(x_offset, 46.0)
213: pillar.size = Vector2(24.0, 110.0)
220: lintel.position = Vector2(70.0, 34.0)
221: lintel.size = Vector2(280.0, 22.0)
229: omen_label.position = Vector2(122.0, 0.0)
230: omen_label.size = Vector2(176.0, 30.0)
231: omen_label.add_theme_font_size_override("font_size", 16)
283: marker.size = Vector2(12, 12)

## scripts/ui/RewardOverlay.gd
lines=305
counts: {'position = Vector2': 4, 'size = Vector2': 4, 'custom_minimum_size': 1, 'offset_': 2, 'button_up': 5, 'mouse_filter': 2, 'visible =': 5, 'queue_free': 2, 'layer =': 1, 'z_index': 1, 'font_size': 2, 'text =': 2}
61: cloth.position = Vector2(18.0, 62.0)
62: cloth.size = Vector2(maxf(0.0, panel_size.x - 36.0), maxf(0.0, panel_size.y - 92.0))
70: title.position = Vector2(20.0, 14.0)
71: title.size = Vector2(maxf(0.0, panel_size.x - 40.0), 28.0)
72: title.add_theme_font_size_override("font_size", COTIW_UI_THEME.get_typography_size("h2", 28))
83: rule.position = Vector2(20.0, 42.0)
84: rule.size = Vector2(maxf(0.0, panel_size.x - 40.0), 22.0)
85: rule.add_theme_font_size_override("font_size", COTIW_UI_THEME.get_typography_size("caption", 18))
113: cloth.position = Vector2(18.0, 62.0)
114: cloth.size = Vector2(maxf(0.0, _offering_table_panel.size.x - 36.0), maxf(0.0, _offering_table_panel.size.y - 92.0))

## scripts/ui/ShopOverlay.gd
lines=171
counts: {'button_up': 2, 'visible =': 4, 'queue_free': 3, 'text =': 2}

## scripts/ui/theme/TouchFeedback.gd
lines=339
counts: {'position = Vector2': 4, 'size = Vector2': 4, 'long_press': 14, 'button_up': 3, 'button_down': 3, 'mouse_filter': 2, 'queue_free': 5, 'CanvasLayer': 4, 'layer =': 1, 'font_size': 2, 'text =': 2}
102: panel.size = Vector2(500, 260)
116: seal.position = Vector2(20, 18)
117: seal.size = Vector2(58, 92)
124: title.position = Vector2(96, 24)
125: title.size = Vector2(360, 38)
127: title.add_theme_font_size_override("font_size", 25)
133: label.position = Vector2(96, 76)
134: label.size = Vector2(370, 146)
137: label.add_theme_font_size_override("font_size", 18)
338: overlay.position = Vector2(390, 240)

## scripts/ui/theme/CombatHudOverlay.gd
lines=461
counts: {'position = Vector2': 10, 'size = Vector2': 14, 'custom_minimum_size': 1, 'offset_': 6, 'anchor_': 4, 'safe': 15, 'mouse_filter': 5, 'visible =': 1, 'queue_free': 2, 'CanvasLayer': 4, 'layer =': 2, 'font_size': 7, 'text =': 9}
210: energy_num.position = Vector2(0, 24)
211: energy_num.size = Vector2(RING_SIZE.x, 60)
215: energy_num.add_theme_font_size_override("font_size", 52)
224: energy_sub.position = Vector2(0, 80)
225: energy_sub.size = Vector2(RING_SIZE.x, 20)
228: energy_sub.add_theme_font_size_override("font_size", 15)
234: energy_max_label.position = Vector2(0, 98)
235: energy_max_label.size = Vector2(RING_SIZE.x, 18)
238: energy_max_label.add_theme_font_size_override("font_size", 12)
282: slot.position = Vector2(x, 0)
285: holder.size = Vector2(maxf(1.0, x - 8.0), 54.0)
290: slot.size = Vector2(60, 54)
295: bg.size = Vector2(60, 54)
307: icon.position = Vector2(3, 2)
308: icon.size = Vector2(38, 38)
315: fallback.position = Vector2(3, 2)
316: fallback.size = Vector2(38, 38)
319: fallback.add_theme_font_size_override("font_size", 22)
... 13 more

## scripts/ui/theme/CotiwUiTheme.gd
lines=437
counts: {'size = Vector2': 1, 'custom_minimum_size': 2, 'offset_': 4, 'safe': 8, 'mouse_filter': 1, 'visible =': 3, 'font_size': 3, 'text =': 1}
217: button.custom_minimum_size = Vector2(320, 112)
222: button.add_theme_font_size_override("font_size", get_typography_size("h2", 24))
286: price_label.add_theme_font_size_override("font_size", get_typography_size("caption", 18))
336: label.add_theme_font_size_override("font_size", get_typography_size("micro", 16))

## scenes/Root.tscn
lines=2372
counts: {'position = Vector2': 1, 'size = Vector2': 5, 'custom_minimum_size': 5, 'offset_': 595, 'anchor_': 125, 'mouse_filter': 24, 'visible =': 46, 'z_index': 10, 'font_size': 48, 'text =': 87}
315: offset_right = 1200.0
316: offset_bottom = 700.0
322: offset_right = 1200.0
323: offset_bottom = 700.0
328: offset_right = 40.0
329: offset_bottom = 40.0
334: offset_right = 1200.0
335: offset_bottom = 700.0
341: offset_right = 1200.0
342: offset_bottom = 700.0
350: offset_left = 80.0
351: offset_top = 6.0
352: offset_right = 280.0
353: offset_bottom = 40.0
359: theme_override_font_sizes/font_size = 24
365: offset_left = 80.0
366: offset_top = 42.0
367: offset_right = 280.0
... 601 more

## scenes/ui/Combat.tscn
MISSING

## scenes/ui/MainMenu.tscn
MISSING

## scenes/ui/NewRunMenu.tscn
MISSING

## scenes/ui/Map.tscn
MISSING

## scenes/ui/RewardOverlay.tscn
MISSING

## scenes/ui/ShopOverlay.tscn
MISSING
