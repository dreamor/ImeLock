//
//  AppDelegate.swift
//  ImeLock
//
//  应用程序委托 - 管理菜单栏图标、弹出窗口和应用程序生命周期
//

import SwiftUI
import ServiceManagement
import Combine

/// 应用程序委托类
///
/// 负责:
/// - 创建和管理菜单栏状态图标
/// - 管理弹出窗口 (Popover)
/// - 处理用户交互 (左键点击、右键点击)
/// - 监听输入法锁定状态变化
class AppDelegate: NSObject, NSApplicationDelegate {
    /// 菜单栏状态图标
    var statusItem: NSStatusItem!

    /// 弹出窗口，用于显示输入法选择界面
    var popover: NSPopover!

    /// 输入法管理器实例
    var inputManager = InputMethodManager.shared

    /// Combine 取消令牌集合，用于管理生命周期
    private var cancellables = Set<AnyCancellable>()

    /// 应用程序启动完成后的初始化
    ///
    /// 设置:
    /// - 隐藏 Dock 图标 (纯菜单栏应用)
    /// - 创建状态栏图标
    /// - 设置弹出窗口
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 隐藏 Dock 图标 - 纯菜单栏应用模式
        NSApp.setActivationPolicy(.accessory)

        setupStatusBar()
        setupPopover()
    }

    // MARK: - 状态栏设置

    /// 设置菜单栏状态图标
    ///
    /// 配置:
    /// - 使用系统标准宽度，与其他应用图标保持一致
    /// - 绑定点击事件 (支持左键和右键)
    /// - 监听锁定状态变化以更新图标
    func setupStatusBar() {
        // 使用系统标准宽度，避免自定义宽度导致的间距不一致
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            updateStatusBarIcon()
            button.action = #selector(togglePopover)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // 监听锁定状态变化，自动更新图标
        inputManager.$isLocked
            .receive(on: RunLoop.main)
            .sink { [weak self] (_: Bool) in
                self?.updateStatusBarIcon()
            }
            .store(in: &cancellables)
    }

    /// 更新状态栏图标
    ///
    /// 根据锁定状态显示不同的图标:
    /// - 已锁定：lock.fill (实心锁)
    /// - 未锁定：lock.open (打开的锁)
    func updateStatusBarIcon() {
        if let button = statusItem.button {
            let symbolName = inputManager.isLocked ? "lock.fill" : "lock.open"
            let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "ImeLock")!
            image.isTemplate = true
            // 使用系统标准图标尺寸 (macOS 菜单栏图标标准为 18x18 pt)
            image.size = NSSize(width: 18, height: 18)
            button.image = image
            button.imagePosition = .imageOnly
        }
    }

    // MARK: - 弹出窗口设置

    /// 设置弹出窗口
    ///
    /// 配置:
    /// - 内容尺寸：280x360
    /// - 行为：transient (点击外部自动关闭)
    /// - 内容：ContentView SwiftUI 视图
    func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 360)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView())
    }

    // MARK: - 用户交互处理

    /// 切换弹出窗口的显示状态
    ///
    /// - 左键点击：打开/关闭弹出窗口
    /// - 右键点击：显示上下文菜单
    @objc func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }

        if let event = NSApp.currentEvent {
            if event.type == .rightMouseUp {
                showContextMenu()
                return
            }
        }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            // 获取按钮在屏幕上的坐标位置
            let buttonRect = button.bounds
            popover.show(relativeTo: buttonRect, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    /// 显示右键上下文菜单
    ///
    /// 菜单选项:
    /// - 锁定/解锁输入法
    /// - 退出应用
    func showContextMenu() {
        let menu = NSMenu()

        // 根据当前状态动态显示菜单项
        let lockTitle = inputManager.isLocked ? "解锁输入法" : "锁定当前输入法"
        let lockItem = NSMenuItem(
            title: lockTitle,
            action: #selector(toggleLock),
            keyEquivalent: ""
        )
        lockItem.target = self
        menu.addItem(lockItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        // 临时绑定菜单并触发点击
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    // MARK: - 菜单动作

    /// 切换输入法锁定状态
    @objc func toggleLock() {
        inputManager.toggle()
    }

    /// 退出应用程序
    @objc func quit() {
        NSApp.terminate(nil)
    }
}

// MARK: - 应用程序入口

/// SwiftUI 应用程序入口点
@main
struct ImeLockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}