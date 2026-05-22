# 一闪AI — 闪念笔记，AI整理

> 抓住每个灵感，AI帮你整理

## 功能特性

- ⚡ **极速捕捉** — 一键输入，瞬间保存，支持 500 字
- 🎤 **语音输入** — 说话转文字，释放双手
- 🤖 **AI 智能整理** — 自动分类、生成摘要、发现关联笔记
- 📊 **数据洞察** — AI 周报、分类分布、情绪趋势
- 🔥 **连续记录** — 每日打卡，追踪连续记录天数
- 📌 **置顶笔记** — 重要笔记固定到列表顶部
- ☑️ **批量操作** — 多选删除，效率翻倍
- 🔍 **搜索筛选** — 全文搜索 + 8 种分类筛选
- 🕐 **定时回顾** — 1/3/7/14/30 天间隔回顾
- 🔔 **智能提醒** — 每日记录提醒 + 定时回顾推送
- ☁️ **iCloud 同步** — SwiftData + CloudKit 多设备同步
- 📝 **Markdown 渲染** — 支持标题、列表、代码块
- 🧩 **桌面小组件** — 今日统计 + 快速捕捉入口
- 📱 **首次引导** — 4 步引导，优雅配置 AI 服务
- 💰 **Pro 订阅** — StoreKit 2 内购，月度/年度方案
- ♿ **无障碍适配** — VoiceOver 标签 + 触觉反馈

## 技术栈

- **SwiftUI** — 声明式 UI
- **SwiftData** — 本地持久化 + CloudKit
- **OpenAI API** — AI 分类/摘要/洞察
- **WidgetKit** — 桌面小组件
- **StoreKit 2** — 内购订阅
- **Speech** — 语音识别
- **UserNotifications** — 本地通知
- **iOS 17.0+**

## 项目结构

```
ShanNianAI/
├── project.yml
├── Sources/
│   ├── ShanNianAI/
│   │   ├── ShanNianAIApp.swift
│   │   ├── Models/Note.swift
│   │   ├── CoreData/NoteStore.swift
│   │   ├── Services/AIService.swift
│   │   ├── Utilities/
│   │   │   ├── HapticManager.swift
│   │   │   ├── NotificationManager.swift
│   │   │   ├── SpeechRecognizer.swift
│   │   │   └── StoreManager.swift
│   │   ├── Views/
│   │   │   ├── ContentView.swift
│   │   │   ├── OnboardingView.swift
│   │   │   ├── CaptureView.swift
│   │   │   ├── NoteListView.swift
│   │   │   ├── NoteDetailView.swift
│   │   │   ├── InsightsView.swift
│   │   │   ├── SettingsView.swift
│   │   │   └── ProSubscriptionView.swift
│   │   └── Resources/Info.plist
│   └── WidgetExtension/
│       └── ShanNianWidget.swift
└── Tests/ShanNianAITests/
```

## 快速开始

```bash
brew install xcodegen
cd ShanNianAI
xcodegen generate
open ShanNianAI.xcodeproj
```

### Xcode 配置要点

| Capability | Target | 说明 |
|-----------|--------|------|
| App Groups | ShanNianAI + Widget | group.com.shanian.flashai |
| iCloud → CloudKit | ShanNianAI | iCloud.com.shanian.flashai |
| Push Notifications | ShanNianAI | 远程推送（CloudKit 同步需要）|
| Background Modes → Remote Notifications | ShanNianAI | CloudKit 推送同步 |
| URL Types | ShanNianAI | shanian:// |

## StoreKit 配置

在 App Store Connect 创建以下内购项目：

| Product ID | 类型 |
|-----------|------|
| com.shanian.flashai.pro.monthly | 自动续期订阅 ¥6/月 |
| com.shanian.flashai.pro.yearly | 自动续期订阅 ¥50/年 |

## 定价

- 免费：每月 30 条笔记 + 30 次 AI 分类
- 一闪Pro 月度：¥6/月
- 一闪Pro 年度：¥50/年

## License

All rights reserved.
