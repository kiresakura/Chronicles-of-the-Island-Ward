#!/usr/bin/env ruby
# scripts/rename_apple_dev_team.rb
#
# 用法：
#   cd scripts && bundle install
#   APPLE_ID=johnny963214@gmail.com ruby rename_apple_dev_team.rb "新的顯示名字"
#
# 目的：
# - 連 Apple Developer Portal 印出當前 team 資訊
# - 對 Individual 帳號（Team Name = Apple ID 姓名），自動引導到 appleid.apple.com 改姓名
# - 對 Organization 帳號，嘗試呼叫 Apple 私有 endpoint 改 team name
#
# 為什麼不能直接用 Ruby API 改 Individual 帳號 team name？
# Apple Developer Portal 的個人帳號 team name 是從 Apple ID 個人資料 (firstName + lastName)
# 同步來的。fastlane/spaceship 沒提供改名 API（Apple 未公開）。
# 唯一改法是改 Apple ID 姓名，之後 Portal 同步（幾分鐘到幾小時）。

require "spaceship"
require "io/console"

APPLE_ID = ENV["APPLE_ID"] || "johnny963214@gmail.com"
NEW_NAME = ARGV[0]

if NEW_NAME.nil? || NEW_NAME.strip.empty?
  abort <<~USAGE
    用法：ruby rename_apple_dev_team.rb "新的顯示名字"
    例：  APPLE_ID=#{APPLE_ID} ruby rename_apple_dev_team.rb "Crimson"
  USAGE
end

puts "═" * 60
puts "Apple Developer Team Name 改名工具"
puts "═" * 60
puts "Apple ID：#{APPLE_ID}"
puts "目標名稱：#{NEW_NAME}"
puts

# 互動式取得密碼，避免進入 shell 歷史
if ENV["FASTLANE_PASSWORD"].to_s.empty?
  print "Apple ID 密碼（輸入時不顯示）："
  ENV["FASTLANE_PASSWORD"] = STDIN.noecho(&:gets).chomp
  puts
end

# 登入 Apple Developer Portal（會問 2FA SMS / device code）
puts "登入 Apple Developer Portal..."
begin
  Spaceship::Portal.login(APPLE_ID)
  Spaceship::Portal.select_team
rescue => e
  abort "登入失敗：#{e.message}\n（檢查密碼/2FA 是否輸入正確）"
end

# 讀 team info
teams = Spaceship::Portal.client.teams
if teams.empty?
  abort "找不到任何 team。"
end

team = teams.first
team_id = team["teamId"]
current_name = team["name"]
team_type = team.dig("type")
status = team.dig("status")

puts
puts "─" * 60
puts "Team 資訊"
puts "─" * 60
puts "  ID：     #{team_id}"
puts "  名稱：    #{current_name}"
puts "  類型：    #{team_type || '(unknown)'}"
puts "  狀態：    #{status || '(unknown)'}"
puts "─" * 60

# Type 為 "In House" 或 "Company/Organization" 才能改 team name
# Individual 帳號 = "Individual" 或 type 為個人帳號 metadata
is_org = team_type.to_s.match?(/company|organization|in.?house|business/i)

if is_org
  puts
  puts "看起來是 Organization 帳號。嘗試呼叫 Apple 私有 endpoint 改名..."
  client = Spaceship::Portal.client
  begin
    response = client.send(:request, :post, "account/updateTeamName.action") do |req|
      req.body = { teamId: team_id, name: NEW_NAME }.to_json
      req.headers["Content-Type"] = "application/json"
    end
    puts "回應：#{response.body.to_s[0..200]}"
    puts "✅ 若 Apple Server 接受，請到 https://developer.apple.com/account 確認"
  rescue => e
    puts "❌ API 呼叫失敗：#{e.message}"
    puts "Apple 未公開此 endpoint，可能需到 https://developer.apple.com/account 手動改"
    system("open https://developer.apple.com/account")
  end
else
  puts
  puts "⚠️  此為 Individual 帳號 — Team Name 等於 Apple ID 姓名。"
  puts "Apple 沒提供 API 直接改個人 Team Name。要改必須改 Apple ID 姓名："
  puts
  puts "  方法 A：網頁  https://appleid.apple.com"
  puts "         → Sign-In and Security → Name"
  puts
  puts "  方法 B：iPhone Settings → [你的名字] → Name, Phone Numbers, Email"
  puts
  puts "  方法 C：Mac System Settings → Apple ID → 點頭像 → Personal Information"
  puts
  puts "改完之後 Apple Developer Portal 會自動同步（通常幾分鐘，最多 24h）。"
  puts "Xcode 內 Apple Accounts 按 Try Again / 重新登入即可看到新名字。"
  puts
  puts "現在自動開啟 Apple ID 設定頁..."
  system("open https://appleid.apple.com")
end

puts
puts "═" * 60
puts "完成。"
puts "═" * 60
