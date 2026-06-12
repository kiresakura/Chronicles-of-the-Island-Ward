// UI 重修 P1-6 — 鎖定按鈕灰階（canvas_item）。
// 對「貼圖 × 頂點色」整體去飽和 — StyleBoxFlat 走頂點色、icon 走 TEXTURE，
// 兩者都要灰；desaturate 控制混合量（1.0 = 全灰）。
shader_type canvas_item;

uniform float desaturate : hint_range(0.0, 1.0) = 0.85;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(c.rgb, vec3(g), desaturate), c.a);
}
