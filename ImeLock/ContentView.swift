//
//  ContentView.swift
//  ImeLock
//
//  主视图组件 - 包含标题、输入法列表和底部设置的弹出窗口界面
//

import SwiftUI
import ServiceManagement
import Carbon

/// 主内容视图
///
/// 显示内容:
/// - 顶部标题栏：锁定状态、开关按钮
/// - 中间列表：所有可用的输入法
/// - 底部栏：开机启动、退出按钮
struct ContentView: View {
    @ObservedObject var inputManager = InputMethodManager.shared
    @AppStorage("launchAtLogin") var launchAtLogin = false

    // MARK: - 设计规范 (Design Tokens)
    private enum Design {
        // 主题色
        static let primaryColor = Color(red: 0.05, green: 0.57, blue: 0.67) // #0D9488
        static let accentColor = Color(red: 0.14, green: 0.72, blue: 0.93)  // #22D3EE
        static let successColor = Color(red: 0.13, green: 0.77, blue: 0.37) // #22C55E
        static let warningColor = Color(red: 0.98, green: 0.46, blue: 0.09) // #F97316

        // 背景色
        static let cardBackground = Color(NSColor.windowBackgroundColor)
        static let secondaryBackground = Color(NSColor.controlBackgroundColor)

        // 阴影与间距
        static let shadowColor = Color.black.opacity(0.1)
        static let borderRadius: CGFloat = 12
        static let itemSpacing: CGFloat = 8
        static let padding: CGFloat = 16

        // 动画时长
        static let transitionDuration = 0.25
    }

    var body: some View {
        VStack(spacing: 0) {
            // ===== 顶部标题栏 =====
            headerView
                .background(
                    LinearGradient(
                        colors: [
                            inputManager.isLocked ?
                                Design.primaryColor.opacity(0.15) : Design.secondaryBackground,
                            inputManager.isLocked ?
                                Design.primaryColor.opacity(0.05) : Design.secondaryBackground
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Divider()
                .padding(.horizontal, Design.padding)

            // ===== 输入法列表 =====
            inputSourceList

            Divider()
                .padding(.horizontal, Design.padding)

            // ===== 底部设置栏 =====
            footerView
        }
        .frame(width: 300)
        .background(Design.cardBackground)
    }

    // MARK: - Header View (顶部标题栏)

    /// 顶部标题栏组件
    ///
    /// 包含:
    /// - 状态图标和动画光晕效果
    /// - 状态文字描述
    /// - 锁定/解锁切换按钮
    var headerView: some View {
        VStack(spacing: 12) {
            // 状态图标和文字
            HStack(spacing: 10) {
                // 带发光效果的图标
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    inputManager.isLocked ? Design.primaryColor : Design.warningColor,
                                    inputManager.isLocked ? Design.accentColor : Design.warningColor.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: inputManager.isLocked ? Design.primaryColor.opacity(0.4) : Design.warningColor.opacity(0.3), radius: 8, x: 0, y: 2)

                    Image(systemName: inputManager.isLocked ? "lock.fill" : "lock.open")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 44, height: 44)
                .animation(.spring(response: Design.transitionDuration, dampingFraction: 0.7), value: inputManager.isLocked)

                // 状态文字
                VStack(alignment: .leading, spacing: 4) {
                    Text(inputManager.isLocked ? "输入法已锁定" : "输入法未锁定")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(inputManager.currentInputSourceName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(height: 42)

                Spacer()

                // 锁定/解锁按钮
                Button(action: {
                    withAnimation(.spring(response: Design.transitionDuration, dampingFraction: 0.7)) {
                        inputManager.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: inputManager.isLocked ? "lock.open" : "lock.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text(inputManager.isLocked ? "解锁" : "锁定")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .frame(height: 36)
                    .padding(.horizontal, 16)
                    .background(
                        LinearGradient(
                            colors: [
                                inputManager.isLocked ? Design.warningColor : Design.primaryColor,
                                inputManager.isLocked ? Design.warningColor.opacity(0.8) : Design.accentColor
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(color: inputManager.isLocked ? Design.warningColor.opacity(0.3) : Design.primaryColor.opacity(0.3), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Design.padding)
        .frame(height: 90)
    }

    // MARK: - Input Source List (输入法列表)

    /// 输入法列表组件
    ///
    /// 展示系统中所有可用的输入法:
    /// - 显示输入法图标和名称
    /// - 标记当前选中的输入法
    /// - 标记被锁定的输入法
    /// - 点击可选中并切换输入法
    var inputSourceList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: Design.itemSpacing) {
                ForEach(inputManager.availableInputSources, id: \.self) { source in
                    InputSourceRow(
                        source: source,
                        isSelected: isCurrentSource(source),
                        isLocked: isLockedSource(source),
                        primaryColor: Design.primaryColor,
                        accentColor: Design.accentColor
                    ) {
                        withAnimation(.spring(response: Design.transitionDuration, dampingFraction: 0.7)) {
                            inputManager.selectInputSource(source)
                            // 如果处于锁定状态，同时锁定该输入法
                            if inputManager.isLocked {
                                inputManager.lockInputSource(source)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, Design.itemSpacing)
        }
        .frame(maxHeight: 200)
        .padding(.horizontal, Design.padding)
    }

    // MARK: - Footer View (底部设置栏)

    /// 底部设置栏组件
    ///
    /// 包含:
    /// - 开机启动复选框
    /// - 退出按钮
    var footerView: some View {
        VStack(spacing: 12) {
            // 开机启动设置
            HStack {
                Button(action: {
                    withAnimation {
                        launchAtLogin.toggle()
                        setLaunchAtLogin(launchAtLogin)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: launchAtLogin ? "checkmark.square.fill" : "square")
                            .font(.system(size: 16))
                            .foregroundColor(launchAtLogin ? Design.primaryColor : .secondary)
                            .animation(.spring(response: 0.15), value: launchAtLogin)

                        Text("开机启动")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // 退出按钮
                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "power.circle.fill")
                            .font(.system(size: 15))
                        Text("退出")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Design.padding)
        .background(Design.secondaryBackground)
    }

    // MARK: - 辅助函数

    /// 判断指定输入法是否是当前正在使用的输入法
    /// - Parameter source: TISInputSource 对象
    /// - Returns: 如果是当前输入法返回 true
    func isCurrentSource(_ source: TISInputSource) -> Bool {
        guard let current = inputManager.getCurrentInputSource() else { return false }
        return inputManager.getInputSourceID(source) == inputManager.getInputSourceID(current)
    }

    /// 判断指定输入法是否是锁定的输入法
    /// - Parameter source: TISInputSource 对象
    /// - Returns: 如果是锁定的输入法返回 true
    func isLockedSource(_ source: TISInputSource) -> Bool {
        guard let locked = inputManager.lockedInputSource else { return false }
        return inputManager.getInputSourceID(source) == inputManager.getInputSourceID(locked)
    }

    /// 设置开机启动状态
    /// - Parameter enabled: 是否启用开机启动
    func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to set launch at login: \(error)")
            }
        }
    }
}

// MARK: - Input Source Row (输入法列表项)

/// 输入法列表中的单行组件
///
/// 包含:
/// - 输入法图标
/// - 输入法名称
/// - 选中状态指示器
/// - 锁定状态指示器
struct InputSourceRow: View {
    let source: TISInputSource
    let isSelected: Bool      // 是否为当前选中的输入法
    let isLocked: Bool       // 是否为锁定的输入法
    let primaryColor: Color
    let accentColor: Color
    let action: () -> Void   // 点击回调

    @ObservedObject var inputManager = InputMethodManager.shared
    @State private var isHovering = false

    private let transitionDuration: Double = 0.25
    private let rowHeight: CGFloat = 44

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // 输入法图标 (固定尺寸)
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isLocked ? [primaryColor, accentColor] : [.secondary.opacity(0.3), .secondary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)

                    Image(systemName: isLocked ? "lock.fill" : "keyboard")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isLocked ? .white : .secondary)
                }
                .frame(width: 32, height: 32)

                // 输入法名称 (固定字体权重，避免布局抖动)
                Text(inputManager.getInputSourceName(source))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? primaryColor : .primary)
                    .lineLimit(1)

                Spacer()

                // 选中指示器 (对勾图标)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(primaryColor)
                }
            }
            .frame(height: rowHeight)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Group {
                    if isSelected {
                        // 选中状态背景
                        RoundedRectangle(cornerRadius: 10)
                            .fill(primaryColor.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(primaryColor.opacity(0.3), lineWidth: 1)
                            )
                    } else if isHovering {
                        // 悬停状态背景
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.08))
                    } else {
                        // 默认透明背景
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.clear)
                    }
                }
            )
            .contentShape(Rectangle())
            .animation(.spring(response: transitionDuration, dampingFraction: 0.7), value: isSelected)
            .animation(.spring(response: 0.15), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}