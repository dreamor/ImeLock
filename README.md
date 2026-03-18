# ImeLock

ImeLock 是一个 macOS 输入法锁定工具，可以锁定当前输入法，防止在使用不同应用时被意外切换。

## 功能特性

- **输入法锁定**：锁定当前输入法，阻止系统自动或手动切换
- **状态栏菜单**：简洁的状态栏界面，显示锁定状态（锁图标）
- **开机自启动**：支持配置为登录项，开机自动启动
- **输入法列表**：显示所有可用的输入法，可快速切换并锁定
- **右键菜单**：右键点击状态栏图标可快速锁定/解锁或退出应用

## 系统要求

- macOS 13.0 (Ventura) 或更高版本
- Apple Silicon (M1/M2/M3) 或 Intel Mac
- Xcode 15.0 或更高版本（用于编译）

## 编译方法

### 使用 Xcode

1. 打开 `ImeLock.xcodeproj`
2. 选择 Build Scheme (ImeLock)
3. 按 `Cmd + B` 编译

### 命令行编译

```bash
xcodebuild -project ImeLock.xcodeproj -scheme ImeLock -configuration Release build
```

编译产物位于 `build/Release/ImeLock.app`

## 使用说明

### 启动应用

1. 运行 `ImeLock.app`
2. 应用会隐藏在 Dock 中，仅显示在状态栏
3. 状态栏图标显示锁的状态：
   - 🔒 闭合锁：输入法已锁定
   - 🔓 打开锁：输入法未锁定

### 锁定/解锁输入法

1. 点击状态栏图标打开菜单
2. 点击"锁定"按钮锁定当前输入法
3. 再次点击"解锁"按钮解除锁定

### 切换输入法

1. 点击状态栏图标打开菜单
2. 在输入法列表中选择一个输入法
3. 如果当前处于锁定状态，会自动锁定到新选择的输入法

### 开机自启动

1. 点击状态栏图标打开菜单
2. 勾选"开机启动"复选框

### 退出应用

- 点击状态栏图标，点击"退出"按钮
- 或右键点击状态栏图标，选择"退出"

## 项目结构

```
ImeLock/
├── AppDelegate.swift         # 应用代理，负责状态栏和菜单管理
├── InputMethodManager.swift  # 输入法管理核心逻辑（加载、切换、锁定）
├── ContentView.swift         # SwiftUI 主界面
├── LoginServiceKit.swift     # 登录项管理封装（SMAppService API）
├── Info.plist               # 应用配置
├── ImeLock.entitlements     # 权限配置
└── Assets.xcassets          # 资源文件（图标等）
```

## 技术实现

### 输入法切换

使用 Carbon.framework 的 TIS (Text Input Source) API：
- `TISCopyCurrentKeyboardInputSource()` - 获取当前输入法
- `TISSelectInputSource()` - 切换输入法
- `TISCreateInputSourceList()` - 获取输入法列表

### 输入法变化监听

使用 DistributedNotificationCenter 监听输入法变化通知：
- `kTISNotifySelectedKeyboardInputSourceChanged` - 输入法切换通知

### 登录项管理

使用 ServiceManagement.framework 的 SMAppService API（macOS 13+）：
- `SMAppService.mainApp.register()` - 注册登录项
- `SMAppService.mainApp.unregister()` - 注销登录项

## 与 SwitchKey 的关系

本项目灵感来源于 [SwitchKey](https://github.com/itsuhane/SwitchKey)，但进行了简化重命名：
- 移除了基于应用的自动切换功能
- 专注于输入法锁定功能
- 使用纯 Swift 实现

| 特性 | SwitchKey | ImeLock |
|------|-----------|---------|
| 最低 macOS 版本 | 10.11 | 13.0 |
| 处理器支持 | Intel | Intel + Apple Silicon |
| 登录项 API | LSSharedFileList (已废弃) | SMAppService (现代 API) |
| 代码语言 | Swift + Objective-C | 纯 Swift |

## 许可证

本项目采用 GPL-3.0 许可证。

## 致谢

- 原始灵感 [SwitchKey](https://github.com/itsuhane/SwitchKey) by itsuhane