//
//  TaskFilter.swift
//  todoapp
//
//  一覧の絞り込み。画面上部では、今日から順に並んだ日付（days）と「全て」「履歴」から選ぶ（FilterTabs）。
//  day / week / month は、日付の並びにする前のタブ。今は画面からは選ばない（テストとの互換のため残している）。
//

import Foundation

/// 今日から何日目から、何日ぶんか（0 = 今日）。1 日だけのことも、続いた何日かのこともある
nonisolated struct DayRange: Hashable, Sendable {
    /// 今日から何日目か（0 = 今日、1 = 明日）
    var start: Int
    /// 何日ぶんか（1 以上）
    var count: Int

    init(start: Int, count: Int = 1) {
        self.start = max(0, start)
        self.count = max(1, count)
    }

    static let today = DayRange(start: 0)

    /// 最後の日（今日から何日目か）
    var end: Int { start + count - 1 }

    func contains(_ offset: Int) -> Bool { offset >= start && offset <= end }

    /// a 日目と b 日目のあいだ（どちらが先でもよい）
    static func between(_ a: Int, _ b: Int) -> DayRange {
        DayRange(start: min(a, b), count: abs(a - b) + 1)
    }
}

enum TaskFilter: Hashable, Identifiable {
    /// 今日から順に並んだ日付から、選んだ 1 日、または続いた何日か
    case days(DayRange)
    case day, week, month, all, history

    var id: Self { self }

    var label: String {
        switch self {
        case .days: return "日付"
        case .day: return "日"
        case .week: return "週"
        case .month: return "月"
        case .all: return "全て"
        case .history: return "履歴"
        }
    }

    /// 画面上部の進み具合の文に使う、この絞り込みの範囲
    var scopeLabel: String {
        switch self {
        case .days(let range):
            let query = TaskQuery()
            guard range.count > 1 else { return Self.dayName(range.start, query: query) }
            // 何日かのときは曜日を省いて短くする（画面上部の 1 行に収める）
            return "\(Self.dayName(range.start, query: query, short: true))〜\(Self.dayName(range.end, query: query, short: true))"
        case .day: return "今日"
        case .week: return "今週"
        case .month: return "今月"
        case .all: return "全て"
        case .history: return "8日以上前"
        }
    }

    /// 今日・明日、それより先は「11/27(金)」（short なら「11/27」）
    private static func dayName(_ offset: Int, query: TaskQuery, short: Bool = false) -> String {
        switch offset {
        case 0: return "今日"
        case 1: return "明日"
        default:
            let date = query.date(atOffset: offset)
            guard short else { return query.shortDateText(date) }
            return "\(query.calendar.component(.month, from: date))/\(query.calendar.component(.day, from: date))"
        }
    }
}
