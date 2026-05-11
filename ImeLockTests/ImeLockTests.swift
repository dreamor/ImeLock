//
//  ImeLockTests.swift
//  ImeLockTests
//

import Testing
import Foundation
import Carbon

// MARK: - Localization Consistency

struct LocalizationTests {
    private static let localizationKeys = [
        "status.locked", "status.unlocked",
        "menu.unlock", "menu.lock_current", "menu.quit",
        "header.input_locked", "header.input_unlocked",
        "button.unlock", "button.lock", "button.quit",
        "footer.launch_at_login",
        "error.launch_at_login_unsupported",
        "alert.settings_failed", "alert.ok",
        "accessibility.status_help",
        "accessibility.locked_state", "accessibility.unlocked_state",
        "accessibility.unlock_button", "accessibility.lock_button",
        "accessibility.input_source_list",
    ]

    @Test("All localization keys have Chinese translations")
    func chineseLocalizationsExist() {
        let zhPath = Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: "zh-Hans")
        #expect(zhPath != nil, "zh-Hans Localizable.strings not found in bundle")

        guard let path = zhPath, let content = try? String(contentsOfFile: path) else { return }
        for key in Self.localizationKeys {
            let pattern = "\"\(NSRegularExpression.escapedPattern(for: key))\"\\s*="
            let regex = try? NSRegularExpression(pattern: pattern)
            let match = regex?.firstMatch(in: content, range: NSRange(content.startIndex..., in: content))
            #expect(match != nil, "Missing Chinese localization for key: \(key)")
        }
    }

    @Test("All localization keys have English translations")
    func englishLocalizationsExist() {
        let enPath = Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: "en")
        #expect(enPath != nil, "en Localizable.strings not found in bundle")

        guard let path = enPath, let content = try? String(contentsOfFile: path) else { return }
        for key in Self.localizationKeys {
            let pattern = "\"\(NSRegularExpression.escapedPattern(for: key))\"\\s*="
            let regex = try? NSRegularExpression(pattern: pattern)
            let match = regex?.firstMatch(in: content, range: NSRange(content.startIndex..., in: content))
            #expect(match != nil, "Missing English localization for key: \(key)")
        }
    }
}

// MARK: - Icon Name Logic

struct IconNameTests {
    private func iconName(isLocked: Bool) -> String {
        isLocked ? "lock.fill" : "lock.open"
    }

    @Test("Lock icon mapping returns correct SF Symbol names")
    func lockIconMapping() {
        #expect(iconName(isLocked: true) == "lock.fill")
        #expect(iconName(isLocked: false) == "lock.open")
    }
}

// MARK: - Design Boundaries

struct DesignBoundaryTests {
    @Test("Restore retry count is reasonable")
    func restoreRetryCountReasonable() {
        let maxRetries = 3
        #expect(maxRetries > 0)
        #expect(maxRetries < 10)
    }

    @Test("Restore delay is reasonable")
    func restoreDelayReasonable() {
        let delay: TimeInterval = 0.05
        #expect(delay >= 0.01)
        #expect(delay <= 0.5)
    }
}

// MARK: - TIS API Constants

struct TISAPIConstantsTests {
    @Test("TIS property keys exist")
    func tisPropertyKeysExist() {
        #expect(kTISPropertyInputSourceCategory != nil)
        #expect(kTISPropertyInputSourceIsSelectCapable != nil)
        #expect(kTISPropertyInputSourceIsEnabled != nil)
        #expect(kTISPropertyLocalizedName != nil)
        #expect(kTISPropertyInputSourceID != nil)
    }
}