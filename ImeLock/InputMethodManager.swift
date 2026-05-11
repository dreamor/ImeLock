//
//  InputMethodManager.swift
//  ImeLock
//
//  输入法管理工具 - 负责监听和锁定 macOS 系统输入法
//

import Foundation
import Carbon
import Combine
import os

/// 输入法管理器 - 负责管理系统输入法的切换和锁定
///
/// 主要功能:
/// - 获取和切换系统输入法
/// - 锁定当前输入法，防止意外切换
/// - 监听输入法变化并自动恢复锁定的输入法
@MainActor
final class InputMethodManager: ObservableObject {
    /// 单例共享实例
    static let shared = InputMethodManager()

    // MARK: - 日志系统

    private static let logger = Logger(subsystem: "com.imelock.app", category: "InputMethodManager")

    // MARK: - Design Tokens

    private enum Design {
        /// 自动恢复锁定输入法的延迟时间（秒）
        static let restoreDelay: TimeInterval = 0.05
        /// 最大重试次数
        static let maxRestoreRetries: Int = 3
    }

    // MARK: - UserDefaults 键

    private enum StorageKey {
        static let isLocked = "isLocked"
        static let lockedInputSourceID = "lockedInputSourceID"
    }

    /// 输入法是否处于锁定状态
    @Published var isLocked = false {
        didSet {
            UserDefaults.standard.set(isLocked, forKey: StorageKey.isLocked)
        }
    }

    /// 被锁定的输入法对象
    @Published var lockedInputSource: TISInputSource? {
        didSet {
            if let id = lockedInputSource.map({ getInputSourceID($0) }) {
                UserDefaults.standard.set(id, forKey: StorageKey.lockedInputSourceID)
            } else {
                UserDefaults.standard.removeObject(forKey: StorageKey.lockedInputSourceID)
            }
        }
    }

    /// 当前输入法的名称
    @Published var currentInputSourceName: String = ""

    /// 系统中所有可用的输入法列表
    @Published var availableInputSources: [TISInputSource] = []

    /// 监听输入法选择的观察者
    private var selectionObserver: AnyObject?
    /// 监听输入法列表变化的观察者
    private var listChangeObserver: AnyObject?

    /// 初始化方法
    /// - 加载可用输入法列表
    /// - 更新当前输入法名称
    /// - 设置输入法变化监听
    /// - 恢复之前保存的锁定状态
    private init() {
        loadAvailableInputSources()
        updateCurrentInputSourceName()
        setupInputSourceChangeObserver()
        setupInputSourceListChangeObserver()
        restoreLockState()
    }

    // MARK: - 持久化存储

    /// 恢复之前保存的锁定状态
    ///
    /// 从 UserDefaults 中读取:
    /// - 锁定状态 (isLocked)
    /// - 锁定的输入法 ID (lockedInputSourceID)
    ///
    /// 如果之前处于锁定状态，会切换到锁定的输入法并启用锁定
    private func restoreLockState() {
        let wasLocked = UserDefaults.standard.bool(forKey: StorageKey.isLocked)
        guard wasLocked,
              let savedID = UserDefaults.standard.string(forKey: StorageKey.lockedInputSourceID),
              !savedID.isEmpty else {
            return
        }

        // 在可用输入法列表中查找之前锁定的输入法
        for source in availableInputSources {
            if getInputSourceID(source) == savedID {
                // 切换到之前锁定的输入法
                selectInputSource(source)
                // 设置锁定状态
                lockedInputSource = source
                isLocked = true
                Self.logger.info("已恢复锁定状态: \(self.getInputSourceName(source))")
                break
            }
        }
    }

    deinit {
        if let selectionObserver = selectionObserver {
            DistributedNotificationCenter.default().removeObserver(selectionObserver)
        }
        if let listChangeObserver = listChangeObserver {
            DistributedNotificationCenter.default().removeObserver(listChangeObserver)
        }
    }

    // MARK: - 输入法加载与获取

    /// 加载系统中所有可用的键盘输入法
    ///
    /// 筛选条件:
    /// - 必须是键盘输入源 (kTISCategoryKeyboardInputSource)
    /// - 必须支持切换操作 (kTISPropertyInputSourceIsSelectCapable)
    /// - 必须是已启用的输入法
    func loadAvailableInputSources() {
        let conditionsDict: [CFString: Any] = [
            kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource as CFString,
            kTISPropertyInputSourceIsSelectCapable: kCFBooleanTrue as CFBoolean
        ]
        let conditions = conditionsDict as CFDictionary

        guard let sources = TISCreateInputSourceList(conditions, false)?.takeRetainedValue() as? [TISInputSource] else {
            Self.logger.warning("无法获取输入法列表")
            return
        }

        // 过滤出已启用的输入法
        availableInputSources = sources.filter { source in
            if let enabled = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsEnabled) {
                return Unmanaged<CFBoolean>.fromOpaque(enabled).takeUnretainedValue() == kCFBooleanTrue
            }
            return false
        }
        Self.logger.debug("已加载 \(self.availableInputSources.count) 个输入法")
    }

    /// 获取输入法的本地化名称
    /// - Parameter source: TISInputSource 对象
    /// - Returns: 输入法名称，如果获取失败则返回 "Unknown"
    nonisolated func getInputSourceName(_ source: TISInputSource) -> String {
        if let namePtr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) {
            return Unmanaged<CFString>.fromOpaque(namePtr).takeUnretainedValue() as String
        }
        return "Unknown"
    }

    /// 获取输入法的唯一标识符
    /// - Parameter source: TISInputSource 对象
    /// - Returns: 输入法 ID 字符串
    nonisolated func getInputSourceID(_ source: TISInputSource) -> String {
        if let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) {
            return Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
        }
        return ""
    }

    /// 获取当前正在使用的输入法
    /// - Returns: 当前键盘输入源，获取失败时返回 nil
    nonisolated func getCurrentInputSource() -> TISInputSource? {
        return TISCopyCurrentKeyboardInputSource()?.takeRetainedValue()
    }

    /// 更新当前输入法名称
    func updateCurrentInputSourceName() {
        if let current = getCurrentInputSource() {
            currentInputSourceName = getInputSourceName(current)
        }
    }

    // MARK: - 输入法切换

    /// 切换到指定的输入法
    /// - Parameter source: 要切换到的输入法对象
    /// - Returns: 是否切换成功
    @discardableResult
    func selectInputSource(_ source: TISInputSource) -> Bool {
        let result = TISSelectInputSource(source)
        if result == noErr {
            updateCurrentInputSourceName()
            Self.logger.debug("已切换输入法: \(self.getInputSourceName(source))")
            return true
        } else {
            Self.logger.error("切换输入法失败，错误码: \(result)")
            return false
        }
    }

    // MARK: - 锁定功能

    /// 锁定当前输入法
    ///
    /// 记录当前输入法并启用锁定状态，之后如果用户切换到其他输入法，
    /// 系统会自动恢复到此输入法
    func lockCurrentInputSource() {
        lockedInputSource = getCurrentInputSource()
        isLocked = true
        updateCurrentInputSourceName()
        if let source = lockedInputSource {
            Self.logger.info("已锁定输入法: \(self.getInputSourceName(source))")
        }
    }

    /// 锁定指定的输入法
    /// - Parameter source: 要锁定的输入法对象
    ///
    /// 会先切换到该输入法，然后启用锁定状态
    func lockInputSource(_ source: TISInputSource) {
        selectInputSource(source)
        lockedInputSource = source
        isLocked = true
        updateCurrentInputSourceName()
        Self.logger.info("已锁定输入法: \(self.getInputSourceName(source))")
    }

    /// 解锁输入法
    ///
    /// 解除锁定状态，允许自由切换输入法
    func unlock() {
        isLocked = false
        lockedInputSource = nil
        // UserDefaults 会在 property didSet 中自动清除
        Self.logger.info("已解锁输入法")
    }

    /// 切换锁定状态
    ///
    /// 如果当前已锁定则解锁，否则锁定当前输入法
    func toggle() {
        if isLocked {
            unlock()
        } else {
            lockCurrentInputSource()
        }
    }

    // MARK: - 输入法变化监听

    /// 设置输入法选择变化事件监听器
    ///
    /// 监听 kTISNotifySelectedKeyboardInputSourceChanged 通知，
    /// 当用户切换输入法时触发 handleInputSourceChange 方法
    private func setupInputSourceChangeObserver() {
        selectionObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleInputSourceChange()
            }
        } as AnyObject
    }

    /// 设置输入法列表变化事件监听器
    ///
    /// 监听 kTISNotifyEnabledKeyboardInputSourcesChanged 通知，
    /// 当用户添加或删除输入法时自动刷新列表
    private func setupInputSourceListChangeObserver() {
        listChangeObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(kTISNotifyEnabledKeyboardInputSourcesChanged as String),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleInputSourceListChange()
            }
        } as AnyObject
    }

    /// 处理输入法选择变化事件
    ///
    /// 当检测到输入法变化时:
    /// 1. 更新当前输入法名称
    /// 2. 如果处于锁定状态且当前输入法与锁定的不同，则恢复锁定的输入法
    private func handleInputSourceChange() {
        updateCurrentInputSourceName()

        guard isLocked, let locked = lockedInputSource else { return }

        if let current = getCurrentInputSource() {
            let currentID = getInputSourceID(current)
            let lockedID = getInputSourceID(locked)

            // 如果当前输入法与锁定的输入法不一致，则恢复
            if currentID != lockedID {
                Self.logger.debug("检测到输入法切换，自动恢复锁定")
                restoreWithRetry(locked, retries: Design.maxRestoreRetries)
            }
        }
    }

    /// 处理输入法列表变化事件
    ///
    /// 当用户添加或删除输入法时刷新可用输入法列表
    private func handleInputSourceListChange() {
        loadAvailableInputSources()
        Self.logger.info("输入法列表已更新")
    }

    // MARK: - 恢复机制

    /// 带重试的输入法恢复机制
    /// - Parameters:
    ///   - source: 要恢复到的输入法
    ///   - retries: 剩余重试次数
    private func restoreWithRetry(_ source: TISInputSource, retries: Int) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(Design.restoreDelay * 1_000_000_000))

            // 检查是否仍然处于锁定状态
            guard self.isLocked else { return }

            if self.selectInputSource(source) {
                Self.logger.info("已成功恢复锁定输入法")
            } else if retries > 0 {
                Self.logger.warning("恢复失败，剩余重试次数: \(retries)")
                self.restoreWithRetry(source, retries: retries - 1)
            } else {
                Self.logger.error("恢复输入法失败，已达到最大重试次数")
            }
        }
    }
}
