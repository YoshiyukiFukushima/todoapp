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
}
