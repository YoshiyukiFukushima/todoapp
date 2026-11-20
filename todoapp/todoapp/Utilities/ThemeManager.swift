//
//  ThemeManager.swift
//  todoapp
//

import SwiftUI
import Combine
import WidgetKit

enum AddButtonPosition: String, CaseIterable, Identifiable {
    case bottomLeading, bottomTrailing

    var id: String { rawValue }

    var alignment: Alignment {
        self == .bottomTrailing ? .bottomTrailing : .bottomLeading
    }

    var displayName: String {
        self == .bottomTrailing ? "右下" : "左下"
    }
}

final class ThemeManager: ObservableObject {
    /// 設定の保存先（ウィジェットもテーマを読むので App Group）
    static let store = SharedStore.defaults

    private enum Keys {
        /// 新しいテーマ（以前の "selectedTheme" は引き継がず、全員みかん色から始める。docs/design.md）
        static let theme = "colorTheme"
        static let animationsEnabled = "animationsEnabled"
        static let fadeOutOnComplete = "fadeOutOnComplete"
        static let addButtonPosition = "addButtonPosition"
        static let isCompletedSectionExpanded = "isCompletedSectionExpanded"
        static let isStickyHeaderEnabled = "isStickyHeaderEnabled"

        static let all = [theme, animationsEnabled, fadeOutOnComplete, addButtonPosition,
                          isCompletedSectionExpanded, isStickyHeaderEnabled]
    }

    /// ウィジェットが読む、今のテーマ
    nonisolated static func storedTheme() -> ColorTheme {
        let raw = SharedStore.defaults.string(forKey: "colorTheme") ?? ColorTheme.defaultTheme.rawValue
        return ColorTheme(rawValue: raw) ?? .defaultTheme
    }

    @Published var selectedTheme: ColorTheme {
        didSet {
            Self.store.set(selectedTheme.rawValue, forKey: Keys.theme)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    @Published var animationsEnabled: Bool {
        didSet { Self.store.set(animationsEnabled, forKey: Keys.animationsEnabled) }
    }

    @Published var fadeOutOnComplete: Bool {
        didSet { Self.store.set(fadeOutOnComplete, forKey: Keys.fadeOutOnComplete) }
    }

    @Published var addButtonPosition: AddButtonPosition {
        didSet { Self.store.set(addButtonPosition.rawValue, forKey: Keys.addButtonPosition) }
    }

    /// true: 完了済みセクションをデフォルトで展開 / false: 今日以外はデフォルトで折りたたむ
    @Published var isCompletedSectionExpanded: Bool {
        didSet { Self.store.set(isCompletedSectionExpanded, forKey: Keys.isCompletedSectionExpanded) }
    }

    @Published var isStickyHeaderEnabled: Bool {
        didSet { Self.store.set(isStickyHeaderEnabled, forKey: Keys.isStickyHeaderEnabled) }
    }

    init() {
        SharedStore.migrateLegacyDefaults(keys: Keys.all)
        let defaults = Self.store
        let rawTheme = defaults.string(forKey: Keys.theme) ?? ColorTheme.defaultTheme.rawValue
        selectedTheme = ColorTheme(rawValue: rawTheme) ?? .defaultTheme
        animationsEnabled = defaults.object(forKey: Keys.animationsEnabled) as? Bool ?? true
        fadeOutOnComplete = defaults.object(forKey: Keys.fadeOutOnComplete) as? Bool ?? false
        let rawPosition = defaults.string(forKey: Keys.addButtonPosition) ?? AddButtonPosition.bottomTrailing.rawValue
        addButtonPosition = AddButtonPosition(rawValue: rawPosition) ?? .bottomTrailing
        isCompletedSectionExpanded = defaults.object(forKey: Keys.isCompletedSectionExpanded) as? Bool ?? true
        isStickyHeaderEnabled = defaults.object(forKey: Keys.isStickyHeaderEnabled) as? Bool ?? true
    }
}
