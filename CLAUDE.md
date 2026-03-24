# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Xcode 命令行编译
xcodebuild -project ImeLock.xcodeproj -scheme ImeLock -configuration Release build

# 使用 Xcode 打开
open ImeLock.xcodeproj
# Cmd+B 编译
```

## Architecture

**无 UI 菜单栏应用**：应用隐藏在 Dock 中，仅显示状态栏图标。

### 核心组件

| 文件 | 职责 |
|------|------|
| `AppDelegate.swift` | NSApplicationDelegate，管理状态栏图标、Popover、右键菜单 |
| `InputMethodManager.swift` | 输入法管理单例，负责 TIS API 调用和输入法锁定逻辑 |
| `ContentView.swift` | SwiftUI 弹出窗口界面，包含输入法列表和设置 |

### 输入法锁定机制

1. 使用 Carbon.framework 的 TIS API (`TISCopyCurrentKeyboardInputSource`、`TISSelectInputSource`)
2. 通过 `DistributedNotificationCenter` 监听 `kTISNotifySelectedKeyboardInputSourceChanged` 通知
3. 锁定状态下检测到输入法变化时，自动恢复到锁定的输入法

### 开机启动

使用 `SMAppService.mainApp` (macOS 13+) 管理登录项，通过 `@AppStorage("launchAtLogin")` 持久化设置。

### 持久化存储

输入法锁定状态通过 `UserDefaults` 持久化：

| 键 | 类型 | 说明 |
|------|------|------|
| `isLocked` | Bool | 输入法锁定状态 |
| `lockedInputSourceID` | String | 锁定的输入法 ID |

- **保存**: 在 `isLocked` 和 `lockedInputSource` 的 `didSet` 中自动保存
- **恢复**: 初始化时调用 `restoreLockState()` 恢复到之前的锁定状态

## 系统要求

- **最低 macOS 版本**: 11.5 (Big Sur)
- **Xcode 版本**: 15.0+
- **Swift 版本**: 5.0+
- **依赖框架**:
  - `Carbon.framework` - TIS (Text Input Source) API
  - `ServiceManagement.framework` - SMAppService (macOS 13+)
  - `Combine` - 响应式状态绑定

## 设计规范 (ContentView.swift)

```swift
// 主题色
primaryColor   = #0D9488 (teal-600)
accentColor    = #22D3EE (cyan-400)
successColor   = #22C55E (green-500)
warningColor   = #F97316 (orange-500)

// 尺寸
popoverSize    = 280x360
borderRadius   = 12px
iconSize       = 18x18 (状态栏)
```

## 代码约定

- **语言**: 纯 Swift，无 Objective-C 混编
- **注释**: 中文注释，包含函数职责和参数说明
- **架构**: 单例模式 (`InputMethodManager.shared`) + SwiftUI `@ObservedObject`
- **动画**: Spring 动画，`dampingFraction: 0.7`, `response: 0.25`