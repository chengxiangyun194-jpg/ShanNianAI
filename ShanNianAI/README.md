# 一闪AI — 闪念笔记，AI整理

> 抓住每个灵感，AI帮你整理

## 技术栈

- **SwiftUI** — 声明式 UI
- **SwiftData** — 本地持久化
- **OpenAI API** — AI 分类/摘要/洞察
- **WidgetKit** — 桌面小组件
- **iOS 17.0+**

## 项目结构

```
ShanNianAI/
├── project.yml                  # XcodeGen 项目配置
├── Sources/
│   ├── ShanNianAI/
│   │   ├── ShanNianAIApp.swift   # App 入口
│   │   ├── Models/
│   │   │   └── Note.swift        # SwiftData 数据模型
│   │   ├── CoreData/
│   │   │   └── NoteStore.swift   # 数据管理 + AI pipeline
│   │   ├── Services/
│   │   │   └── AIService.swift   # OpenAI API 封装
│   │   ├── Views/
│   │   │   ├── ContentView.swift      # 主 TabView
│   │   │   ├── CaptureView.swift      # 极速捕捉
│   │   │   ├── NoteListView.swift     # 笔记列表 + 回顾
│   │   │   ├── NoteDetailView.swift   # 笔记详情
│   │   │   ├── InsightsView.swift     # AI 周报
│   │   │   └── SettingsView.swift     # 设置
│   │   └── Resources/
│   │       └── Info.plist
│   └── WidgetExtension/
│       ├── ShanNianWidget.swift
│       └── Info.plist
└── AppStore/
    └── AppStoreListing.md        # App Store 上架素材
```

## 快速开始

### 1. 安装 Xcode

从 App Store 下载 Xcode（需要 macOS 14+）。

### 2. 生成项目

```bash
# 安装 xcodegen
brew install xcodegen

# 生成 .xcodeproj
cd ShanNianAI
xcodegen generate
```

### 3. 打开项目

```bash
open ShanNianAI.xcodeproj
```

选择 iOS 模拟器，按 Cmd+R 运行。

### 4. 配置 AI

在 App 的设置页面输入你的 OpenAI API Key。

## App Store 上架流程

1. 注册 Apple Developer Program ($99/年)
2. 在 App Store Connect 创建 App
3. 在 Xcode 中配置 Bundle ID 和签名
4. 准备截屏（5张，iPhone 6.7" + 6.5" + 5.5"）
5. Archive → 上传至 App Store Connect
6. 填写审核信息（隐私政策、App 描述等）
7. 提交审核

## 定价策略

- 免费：每月 50 条笔记 + AI 分类
- 一闪Pro 月度：¥12/月
- 一闪Pro 年度：¥88/年（推荐）

## License

All rights reserved.
