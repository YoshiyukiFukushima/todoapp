//
//  WidgetTaskQuery.swift
//  todoapp
//
//  ウィジェットに出すタスクの選び方（docs/widgets.md 4.1）。アプリとウィジェットで共有し、テストで確かめる。
//  - 期限切れはいつも含める
//  - 選んだ期限の範囲まで（今日まで／明日まで／今週まで／今月まで）
//  - 期限なしは設定で含める
//  - 今日完了したものは、その場に残す（日付が変わると消える）
//

import Foundation

/// いつ期限までを出すか
nonisolated enum WidgetDueRange: String, CaseIterable, Sendable {
    case today, tomorrow, thisWeek, thisMonth

    var displayName: String {
        switch self {
        case .today: "今日まで"
        case .tomorrow: "明日まで"
        case .thisWeek: "今週まで"
        case .thisMonth: "今月まで"
        }
    }

    /// 見出しの進み具合の文に使う言い方
    var scopeLabel: String {
        switch self {
        case .today: "今日"
        case .tomorrow: "明日まで"
        case .thisWeek: "今週"
        case .thisMonth: "今月"
        }
    }
}

/// ウィジェットの進み具合
struct WidgetProgress: Equatable {
    let done: Int
    let total: Int

    var remaining: Int { total - done }
    var isComplete: Bool { total > 0 && done == total }
    var fraction: Double { total == 0 ? 0 : Double(done) / Double(total) }
}

extension TaskQuery {
    /// 範囲の終わり（この時刻より前の期限が入る）
    func widgetRangeEnd(_ range: WidgetDueRange) -> Date {
        let startOfToday = calendar.startOfDay(for: now)
        switch range {
        case .today:
            return calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now
        case .tomorrow:
            return calendar.date(byAdding: .day, value: 2, to: startOfToday) ?? now
        case .thisWeek:
            return calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
        case .thisMonth:
            return calendar.dateInterval(of: .month, for: now)?.end ?? now
        }
    }

    /// 期限の条件に入るか（完了・未完了は見ない）
    private func matchesWidgetDue(_ task: TodoTask, end: Date, includesUndated: Bool) -> Bool {
        guard let due = task.dueDate else { return includesUndated }
        return due < end
    }

    /// ウィジェットに出すタスク。完了しても位置が変わらないよう、期限→作成日の順で並べる
    func widgetTasks(from tasks: [TodoTask], range: WidgetDueRange, includesUndated: Bool) -> [TodoTask] {
        let end = widgetRangeEnd(range)
        return tasks
            .filter { task in
                guard matchesWidgetDue(task, end: end, includesUndated: includesUndated) else { return false }
                if task.isCompleted {
                    // 今日チェックしたものだけ残す
                    guard let completedDate = task.completedDate else { return false }
                    return calendar.isDate(completedDate, inSameDayAs: now)
                }
                return true
            }
            .sorted { lhs, rhs in
                let l = lhs.dueDate ?? .distantFuture
                let r = rhs.dueDate ?? .distantFuture
                return l != r ? l < r : lhs.createdDate < rhs.createdDate
            }
    }

    /// ウィジェットに出したタスクの進み具合
    func widgetProgress(of tasks: [TodoTask]) -> WidgetProgress {
        WidgetProgress(done: tasks.filter(\.isCompleted).count, total: tasks.count)
    }
}
