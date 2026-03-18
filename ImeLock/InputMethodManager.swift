//
//  InputMethodManager.swift
//  ImeLock
//
//  输入法管理工具 - 负责监听和锁定 macOS 系统输入法
//

import Foundation
import Carbon
import Combine

/// 输入法管理器 - 单例类，负责管理系统输入法的切换和锁定
///
/// 主要功能:
/// - 获取和切换系统输入法
/// - 锁定当前输入法，防止意外切换
/// - 监听输入法变化并自动恢复锁定的输入法
class InputMethodManager: ObservableObject {
    /// 单例共享实例
    static let shared = InputMethodManager()

    /// 输入法是否处于锁定状态
    @Published var isLocked = false

    /// 被锁定的输入法对象
    @Published var lockedInputSource: TISInputSource?

    /// 当前输入法的名称
    @Published var currentInputSourceName: String = ""

    /// 系统中所有可用的输入法列表
    @Published var availableInputSources: [TISInputSource] = []

    /// 监听输入法变化的观察者
    private var observer: AnyObject?

    /// 初始化方法
    /// - 加载可用输入法列表
    /// - 更新当前输入法名称
    /// - 设置输入法变化监听
    init() {
        loadAvailableInputSources()
        updateCurrentInputSourceName()
        setupInputSourceChangeObserver()
    }

    deinit {
        if let observer = observer {
            DistributedNotificationCenter.default().removeObserver(observer)
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
            return
        }

        // 过滤出已启用的输入法
        availableInputSources = sources.filter { source in
            if let enabled = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsEnabled) {
                return Unmanaged<CFBoolean>.fromOpaque(enabled).takeUnretainedValue() == kCFBooleanTrue
            }
            return false
        }
    }

    /// 获取输入法的本地化名称
    /// - Parameter source: TISInputSource 对象
    /// - Returns: 输入法名称，如果获取失败则返回 "Unknown"
    func getInputSourceName(_ source: TISInputSource) -> String {
        if let namePtr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) {
            return Unmanaged<CFString>.fromOpaque(namePtr).takeUnretainedValue() as String
        }
        return "Unknown"
    }

    /// 获取输入法的唯一标识符
    /// - Parameter source: TISInputSource 对象
    /// - Returns: 输入法 ID 字符串
    func getInputSourceID(_ source: TISInputSource) -> String {
        if let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) {
            return Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
        }
        return ""
    }

    /// 获取当前正在使用的输入法
    /// - Returns: 当前键盘输入源，获取失败时返回 nil
    func getCurrentInputSource() -> TISInputSource? {
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
    func selectInputSource(_ source: TISInputSource) {
        TISSelectInputSource(source)
        updateCurrentInputSourceName()
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
    }

    /// 解锁输入法
    ///
    /// 解除锁定状态，允许自由切换输入法
    func unlock() {
        isLocked = false
        lockedInputSource = nil
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

    /// 设置输入法变化事件监听器
    ///
    /// 监听 kTISNotifySelectedKeyboardInputSourceChanged 通知，
    /// 当用户切换输入法时触发 handleInputSourceChange 方法
    private func setupInputSourceChangeObserver() {
        observer = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleInputSourceChange()
        } as AnyObject
    }

    /// 处理输入法变化事件
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                    self?.selectInputSource(locked)
                }
            }
        }
    }
}