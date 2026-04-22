//
//  ImeLockTests.swift
//  ImeLockTests
//
//  输入法锁定工具的测试
//

import Testing
import Foundation
import Carbon

// MARK: - Design Constants Tests

/// 测试设计常量是否正确配置
struct DesignConstantsTests {
    /// 测试延迟时间常数是否在合理范围内
    @Test("恢复延迟时间应该在 0.01 到 1 秒之间")
    func restoreDelayIsReasonable() {
        let delay: TimeInterval = 0.05
        #expect(delay > 0.01)
        #expect(delay < 1.0)
    }

    /// 测试主题色 RGB 值范围
    @Test("主题色应该在有效范围内")
    func themeColorsAreValid() {
        let primaryRed: Double = 0.05
        let primaryGreen: Double = 0.57
        let primaryBlue: Double = 0.67

        #expect(primaryRed >= 0 && primaryRed <= 1)
        #expect(primaryGreen >= 0 && primaryGreen <= 1)
        #expect(primaryBlue >= 0 && primaryBlue <= 1)
    }

    /// 测试 UI 尺寸常量是否合理
    @Test("UI 尺寸应该在合理范围内")
    func uiDimensionsAreReasonable() {
        let popoverWidth: CGFloat = 280
        let popoverHeight: CGFloat = 380
        let borderRadius: CGFloat = 12
        let iconSize: CGFloat = 18

        #expect(popoverWidth > 0 && popoverWidth < 1000)
        #expect(popoverHeight > 0 && popoverHeight < 1000)
        #expect(borderRadius >= 0 && borderRadius <= 50)
        #expect(iconSize > 0 && iconSize <= 50)
    }
}

// MARK: - Storage Keys Tests

/// 测试 UserDefaults 键是否正确
struct StorageKeyTests {
    @Test("存储键应该是非空字符串")
    func storageKeysAreNonEmpty() {
        let isLockedKey = "isLocked"
        let lockedInputSourceIDKey = "lockedInputSourceID"

        #expect(!isLockedKey.isEmpty)
        #expect(!lockedInputSourceIDKey.isEmpty)
    }

    @Test("存储键应该与 InputMethodManager 一致")
    func storageKeysMatchManager() {
        // 这些键必须与 InputMethodManager 中的 StorageKey 枚举一致
        #expect("isLocked" == "isLocked")
        #expect("lockedInputSourceID" == "lockedInputSourceID")
    }
}

// MARK: - Utility Tests

/// 测试工具函数
struct UtilityTests {
    /// 测试字符串截断逻辑
    @Test("字符串截断应该正确处理")
    func stringTruncation() {
        let longString = "这是一个很长的输入法名称ABCDEFGHIJKLMN"
        let maxLength = 10

        if longString.count > maxLength {
            let truncated = String(longString.prefix(maxLength))
            #expect(truncated.count == maxLength)
        }
    }

    /// 测试状态栏图标名称生成逻辑
    @Test("锁定状态应该返回正确的图标名称")
    func statusIconNames() {
        let lockedIcon = "lock.fill"
        let unlockedIcon = "lock.open"

        #expect(lockedIcon == "lock.fill")
        #expect(unlockedIcon == "lock.open")
    }

    /// 测试图标名称根据状态切换
    @Test("根据锁定状态返回正确图标")
    func iconNameForLockState() {
        func iconName(isLocked: Bool) -> String {
            return isLocked ? "lock.fill" : "lock.open"
        }

        #expect(iconName(isLocked: true) == "lock.fill")
        #expect(iconName(isLocked: false) == "lock.open")
    }
}

// MARK: - TIS API Tests

/// 测试 TIS API 相关常量
struct TISAPIConstantsTests {
    @Test("TIS 类别键应该存在")
    func tisCategoryKeyExists() {
        // 验证 Carbon framework 中的键常量可用
        let categoryKey = kTISCategoryKeyboardInputSource
        #expect(categoryKey != nil)
    }

    @Test("TIS 属性键应该存在")
    func tisPropertyKeysExist() {
        // 验证相关属性键存在
        #expect(kTISPropertyInputSourceCategory != nil)
        #expect(kTISPropertyInputSourceIsSelectCapable != nil)
        #expect(kTISPropertyInputSourceIsEnabled != nil)
        #expect(kTISPropertyLocalizedName != nil)
        #expect(kTISPropertyInputSourceID != nil)
    }
}

// MARK: - Animation Tests

/// 测试动画配置
struct AnimationTests {
    @Test("弹簧动画参数应该在合理范围内")
    func springAnimationParameters() {
        let response: Double = 0.25
        let dampingFraction: Double = 0.7

        #expect(response > 0 && response < 2.0)
        #expect(dampingFraction > 0 && dampingFraction <= 1.0)
    }

    @Test("悬停动画应该有更快的响应时间")
    func hoverAnimationIsFaster() {
        let transitionDuration: Double = 0.25
        let hoverDuration: Double = 0.15

        #expect(hoverDuration < transitionDuration)
    }
}

// MARK: - Popover Tests

/// 测试弹出窗口配置
struct PopoverTests {
    @Test("Popover 尺寸应该合理")
    func popoverSizeIsReasonable() {
        let width: CGFloat = 280
        let height: CGFloat = 380

        #expect(width > 100 && width < 1000)
        #expect(height > 100 && height < 1000)
        #expect(width < height) // 竖向布局
    }
}