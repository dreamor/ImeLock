//
//  ContentView.swift
//  ImeLock
//
//  主视图组件 - 包含标题、输入法列表和底部设置的弹出窗口界面
//

import SwiftUI
import ServiceManagement
import Carbon
import os

/// 主内容视图
///
/// 显示内容:
/// - 顶部标题栏：锁定状态、开关按钮
/// - 中间列表：所有可用的输入法
/// - 底部栏：开机启动、退出按钮
struct ContentView: View {
    @ObservedObject var inputManager = InputMethodManager.shared
    @AppStorage("launchAtLogin") var launchAtLogin = false

    // MARK: - 日志系统

    private static let logger = Logger(subsystem: "com.imelock.app", category: "ContentView")

    // MARK: - 错误状态

    @State private var showLaunchError = false
    @State private var launchErrorMessage = ""

    // MARK: - Design Tokens

    private enum Design {
        // 主题色 - Teal 色系
        static let primaryColor = Color(red: 0.05, green: 0.57, blue: 0.67)      // #0D9488
        static let primaryLight = Color(red: 0.14, green: 0.72, blue: 0.93)       // #22D3EE
        static let primaryDark = Color(red: 0.02, green: 0.40, blue: 0.48)        // #096B61
        
        // 警告色 - Orange 色系
        static let warningColor = Color(red: 0.98, green: 0.46, blue: 0.09)       // #F97316
        static let warningLight = Color(red: 1.0, green: 0.68, blue: 0.38)        // #FFAD61
        
        // 系统色
        static let cardBackground = Color(NSColor.windowBackgroundColor)
        static let secondaryBackground = Color(NSColor.controlBackgroundColor)
        static let separatorColor = Color(NSColor.separatorColor)
        
        // 文字颜色
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color(red: 0.6, green: 0.6, blue: 0.6)
        static let textHint = Color(red: 0.5, green: 0.5, blue: 0.5)

        // 圆角
        static let cornerRadius: CGFloat = 12
        static let buttonCornerRadius: CGFloat = 8
        static let iconCornerRadius: CGFloat = 10

        // 间距
        static let itemSpacing: CGFloat = 6
        static let padding: CGFloat = 16
        static let horizontalPadding: CGFloat = 14

        // 列表项尺寸
        static let rowHeight: CGFloat = 46
        static let rowIconSize: CGFloat = 32
        static let headerIconSize: CGFloat = 48

        // 容器尺寸
        static let popoverWidth: CGFloat = 280
        static let popoverHeight: CGFloat = 380
        static let headerHeight: CGFloat = 76
        static let footerHeight: CGFloat = 44
        static let inputListHeight: CGFloat = popoverHeight - headerHeight - footerHeight - 2

        // 按钮尺寸
        static let toggleButtonWidth: CGFloat = 64
        static let toggleButtonHeight: CGFloat = 32
    }

    var body: some View {
        VStack(spacing: 0) {
            // ===== 顶部标题栏 =====
            headerView

            Divider()
                .padding(.horizontal, Design.horizontalPadding)

            // ===== 输入法列表 =====
            inputSourceList

            Divider()
                .padding(.horizontal, Design.horizontalPadding)

            // ===== 底部设置栏 =====
            footerView
        }
        .frame(width: Design.popoverWidth, height: Design.popoverHeight)
        .background(Design.cardBackground)
        .modifier(ErrorAlertModifier(
            isPresented: $showLaunchError,
            message: launchErrorMessage
        ))
    }

    // MARK: - Header View (顶部标题栏)

    var headerView: some View {
        HStack(spacing: 14) {
            // 状态图标 - 更精致的设计
            ZStack {
                // 背景圆
                Circle()
                    .fill(inputManager.isLocked ? Design.primaryColor : Design.warningColor)
                    .frame(width: Design.headerIconSize, height: Design.headerIconSize)
                
                // 内圈装饰
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    .frame(width: Design.headerIconSize - 8, height: Design.headerIconSize - 8)
                
                // 图标
                Image(systemName: inputManager.isLocked ? "checkmark" : "lock.open")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: Design.headerIconSize, height: Design.headerIconSize)
            .accessibilityLabel(inputManager.isLocked ? "已锁定状态" : "未锁定状态")

            // 状态文字
            VStack(alignment: .leading, spacing: 3) {
                Text(inputManager.isLocked ? "输入法已锁定" : "输入法未锁定")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Design.textPrimary)

                Text(inputManager.currentInputSourceName)
                    .font(.system(size: 12))
                    .foregroundColor(Design.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // 锁定/解锁按钮 - 胶囊形状
            Button(action: {
                inputManager.toggle()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: inputManager.isLocked ? "lock.open" : "lock.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text(inputManager.isLocked ? "解锁" : "锁定")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(width: Design.toggleButtonWidth, height: Design.toggleButtonHeight)
                .background(
                    Capsule()
                        .fill(inputManager.isLocked ? Design.warningColor : Design.primaryColor)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(inputManager.isLocked ? "解锁输入法" : "锁定当前输入法")
        }
        .padding(.horizontal, Design.horizontalPadding)
        .padding(.vertical, 14)
        .frame(height: Design.headerHeight)
        .background(Design.secondaryBackground)
    }

    // MARK: - Input Source List (输入法列表)

    var inputSourceList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: Design.itemSpacing) {
                ForEach(inputManager.availableInputSources, id: \.self) { source in
                    InputSourceRow(
                        source: source,
                        inputManager: inputManager,
                        isSelected: isCurrentSource(source),
                        isLocked: isLockedSource(source),
                        primaryColor: Design.primaryColor,
                        rowHeight: Design.rowHeight,
                        rowIconSize: Design.rowIconSize
                    ) {
                        inputManager.selectInputSource(source)
                        if inputManager.isLocked {
                            inputManager.lockInputSource(source)
                        }
                    }
                }
            }
            .padding(.vertical, Design.itemSpacing)
        }
        .frame(height: Design.inputListHeight)
        .padding(.horizontal, Design.horizontalPadding)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("输入法列表")
    }

    // MARK: - Footer View (底部设置栏)

    var footerView: some View {
        HStack(spacing: 16) {
            // 开机启动
            Button(action: {
                launchAtLogin.toggle()
                setLaunchAtLogin(launchAtLogin)
            }) {
                HStack(spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(launchAtLogin ? Design.primaryColor : Design.textTertiary, lineWidth: 1.5)
                            .frame(width: 16, height: 16)
                        
                        if launchAtLogin {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Design.primaryColor)
                        }
                    }
                    
                    Text("开机启动")
                        .font(.system(size: 12))
                        .foregroundColor(Design.textPrimary)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // 退出按钮 - 带悬停效果
            ExitButton()
        }
        .padding(.horizontal, Design.horizontalPadding)
        .frame(height: Design.footerHeight)
        .background(Design.secondaryBackground)
    }

    // MARK: - 辅助函数

    func isCurrentSource(_ source: TISInputSource) -> Bool {
        guard let current = inputManager.getCurrentInputSource() else { return false }
        return inputManager.getInputSourceID(source) == inputManager.getInputSourceID(current)
    }

    func isLockedSource(_ source: TISInputSource) -> Bool {
        guard let locked = inputManager.lockedInputSource else { return false }
        return inputManager.getInputSourceID(source) == inputManager.getInputSourceID(locked)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                    Self.logger.info("已启用开机启动")
                } else {
                    try SMAppService.mainApp.unregister()
                    Self.logger.info("已禁用开机启动")
                }
            } catch {
                Self.logger.error("开机启动设置失败: \(error.localizedDescription)")
                launchErrorMessage = error.localizedDescription
                showLaunchError = true
                launchAtLogin = !enabled
            }
        } else {
            Self.logger.warning("开机启动需要 macOS 13.0 或更高版本")
            launchErrorMessage = "开机启动功能需要 macOS 13.0 或更高版本"
            showLaunchError = true
            launchAtLogin = false
        }
    }
}

// MARK: - Exit Button with Hover Effect

struct ExitButton: View {
    @State private var isHovering = false
    
    var body: some View {
        Button(action: {
            NSApp.terminate(nil)
        }) {
            HStack(spacing: 4) {
                Image(systemName: "power")
                    .font(.system(size: 11))
                Text("退出")
                    .font(.system(size: 12))
            }
            .foregroundColor(isHovering ? .red : Color(red: 0.6, green: 0.6, blue: 0.6))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovering ? Color.red.opacity(0.1) : Color.secondary.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Input Source Row

struct InputSourceRow: View {
    let source: TISInputSource
    let inputManager: InputMethodManager
    let isSelected: Bool
    let isLocked: Bool
    let primaryColor: Color
    let rowHeight: CGFloat
    let rowIconSize: CGFloat
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // 输入法图标
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isLocked ? primaryColor : Color.secondary.opacity(0.15))
                        .frame(width: rowIconSize, height: rowIconSize)
                    
                    Image(systemName: isLocked ? "lock.fill" : "keyboard")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isLocked ? .white : .secondary)
                }
                .frame(width: rowIconSize, height: rowIconSize)

                // 输入法名称 - 左对齐，允许截断
                Text(inputManager.getInputSourceName(source))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? primaryColor : .primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // 选中指示器
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(primaryColor)
                }
            }
            .frame(height: rowHeight)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: isSelected ? 1.5 : 0)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return primaryColor.opacity(0.08)
        } else if isHovering {
            return Color.secondary.opacity(0.08)
        }
        return Color.clear
    }
    
    private var borderColor: Color {
        if isSelected {
            return primaryColor.opacity(0.3)
        }
        return Color.clear
    }
}

// MARK: - Error Alert Modifier

struct ErrorAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String

    func body(content: Content) -> some View {
        content
            .alert(isPresented: $isPresented) {
                Alert(
                    title: Text("设置失败"),
                    message: Text(message),
                    dismissButton: .default(Text("确定"))
                )
            }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
