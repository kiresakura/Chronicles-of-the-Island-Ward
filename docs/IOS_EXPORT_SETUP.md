# iOS Export 設定指引

> **狀態**：Templates 已安裝、Team ID 已查到、preset 結構就位；CLI export 還有 config 錯誤需在 Godot 編輯器內精修。

## 已完成

- Godot 4.6.1 export templates 安裝在 `~/Library/Application Support/Godot/export_templates/4.6.1.stable/`
- 包含 `ios.zip`, `android_debug.apk`, `android_release.apk`, `macos.zip`
- iOS Simulator preset 已寫到本機 `export_presets.cfg`（已在 .gitignore，不入版控）
- Apple Developer 簽署身分已查到：`Apple Development: johnny963214@gmail.com (B6A4N5Z3Q9)`
- Team ID：`B6A4N5Z3Q9`
- Bundle ID 暫定：`com.kiresakura.cotiw`

## 已遇到的問題

CLI export 在配置檢查時失敗，但 Godot 錯誤訊息不夠明確：

```text
ERROR: Cannot export project with preset "iOS Simulator" due to configuration errors:
```

已修正：
- `min_ios_version` 13.0 → 14.0（Metal renderer 需要）
- `app_store_team_id` 設為 `B6A4N5Z3Q9`
- `code_sign_identity_debug` 設為實際簽署身分名

仍待 Godot 編輯器內互動確認的欄位（CLI 看不到完整 hint）：
- iOS Provisioning profile：未產生 profile（首次 Xcode 連真機時 Apple 才會發）
- launch screen storyboard 或 icon 路徑可能需要 placeholder
- `architectures/arm64`、`targeted_device_family=1` 等細節

## 下一步（在 Godot 編輯器內完成）

1. 啟動 Godot 編輯器：`cd /Users/crimson/Developer/COTIW && godot --editor`
2. 開啟「Project → Export...」
3. 應該會看到 `iOS Simulator` preset（已從 `export_presets.cfg` 載入）
4. 按 preset 底下的 **Configure...** 修剩餘紅字欄位
5. 若 icon 缺：可暫時拖一張 `icon.svg` 來放
6. 試 **Export PCK/Zip** 而非完整 Export Project 來繞過簽署

## 真機部署（Apple Developer Account 已有）

1. iPhone 用 USB 接 Mac，在 Xcode → Window → Devices and Simulators 註冊裝置
2. Xcode 會自動產生 provisioning profile
3. Godot 編輯器內 Export → iOS（不是 Simulator）→ Export Project（產出 `.xcodeproj`）
4. 用 Xcode 開該 `.xcodeproj`，選真機，Cmd+R 安裝執行

## Android 部署

需要：
- Android Studio + Android SDK
- 在 Godot 設定 `editor/export/android/android_sdk_path`
- 設定 keystore（debug keystore 可用 `keytool` 自動生成）

```bash
# 一鍵建 debug keystore
keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12
```

## CI 整合

`.github/workflows/ci.yml` 已預備 ios/android build job（目前 `if: false` 停用），等本機 export 通了再啟用：

1. 把 keystore / signing 用 base64 編碼存進 GH Secrets（`ANDROID_KEYSTORE_B64`, `IOS_CERT_B64`, etc.）
2. 在 workflow 內 `base64 -d` 還原
3. 啟用 `if: true`

## 風險

- Xcode 26.5（macOS 26）相對新，Godot 4.6.1 iOS export 對 Xcode 26 完整相容性尚未廣泛驗證
- 若遇問題可考慮：
  - 降版 Godot 至 4.4.1（CLAUDE.md 原指定）
  - 或在 Godot 編輯器內 export → Xcode 開啟 → 手動修 Xcode project 設定
