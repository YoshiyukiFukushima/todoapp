//
//  ThemeManager.swift
//  todoapp
//

import SwiftUI
import Combine

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
    private enum Keys {
        static let theme = "selectedTheme"
        static let animationsEnabled = "animationsEnabled"
        static let fadeOutOnComplete = "fadeOutOnComplete"
        static let addButtonPosition = "addButtonPosition"
        static let isCompletedSectionExpanded = "isCompletedSectionExpanded"
        static let isStickyHeaderEnabled = "isStickyHeaderEnabled"
    }

    @Published var selectedTheme: AppTheme {
        didSet { UserDefaults.standard.set(selectedTheme.rawValue, forKey: Keys.theme) }
    }

    @Published var animationsEnabled: Bool {
        didSet { UserDefaults.standard.set(animationsEnabled, forKey: Keys.animationsEnabled) }
    }

    @Published var fadeOutOnComplete: Bool {
        didSet { UserDefaults.standard.set(fadeOutOnComplete, forKey: Keys.fadeOutOnComplete) }
    }

    @Published var addButtonPosition: AddButtonPosition {
        didSet { UserDefaults.standard.set(addButtonPosition.rawValue, forKey: Keys.addButtonPosition) }
    }

    /// true: 完了済みセクションをデフォルトで展開 / false: 今日以外はデフォルトで折りたたむ
    @Published var isCompletedSectionExpanded: Bool {
        didSet { UserDefaults.standard.set(isCompletedSectionExpanded, forKey: Keys.isCompletedSectionExpanded) }
    }

    @Published var isStickyHeaderEnabled: Bool {
        didSet { UserDefaults.standard.set(isStickyHeaderEnabled, forKey: Keys.isStickyHeaderEnabled) }
    }

    init() {
        let defaults = UserDefaults.standard
        let rawTheme = defaults.string(forKey: Keys.theme) ?? AppTheme.lavender.rawValue
        selectedTheme = AppTheme(rawValue: rawTheme) ?? .lavender
        animationsEnabled = defaults.object(forKey: Keys.animationsEnabled) as? Bool ?? true
        fadeOutOnComplete = defaults.object(forKey: Keys.fadeOutOnComplete) as? Bool ?? false
        let rawPosition = defaults.string(forKey: Keys.addButtonPosition) ?? AddButtonPosition.bottomTrailing.rawValue
        addButtonPosition = AddButtonPosition(rawValue: rawPosition) ?? .bottomTrailing
        isCompletedSectionExpanded = defaults.object(forKey: Keys.isCompletedSectionExpanded) as? Bool ?? true
        isStickyHeaderEnabled = defaults.object(forKey: Keys.isStickyHeaderEnabled) as? Bool ?? true
    }
}
