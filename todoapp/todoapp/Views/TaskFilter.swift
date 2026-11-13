//
//  TaskFilter.swift
//  todoapp
//

import Foundation

enum TaskFilter: String, CaseIterable, Identifiable {
    case day, week, month, all, history

    var id: String { rawValue }

    var label: String {
        switch self {
        case .day: return "日"
        case .week: return "週"
        case .month: return "月"
        case .all: return "全て"
        case .history: return "履歴"
        }
    }

    /// 画面上部の進み具合の文に使う、このタブの範囲
    var scopeLabel: String {
        switch self {
        case .day: return "今日"
        case .week: return "今週"
        case .month: return "今月"
        case .all: return "全て"
        case .history: return "8日以上前"
        }
    }
}
