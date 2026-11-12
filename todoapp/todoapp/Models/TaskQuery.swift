//
//  TaskQuery.swift
//  todoapp
//
//  タブ（日／週／月／全て／履歴）ごとのタスクの絞り込み・件数・完了済みの日付グループ分け。
//  以前は TabBarView と TaskListView に同じ条件が別々に書かれていたものを 1 か所にまとめた。
//  `now` と `calendar` を差し替えられるのでテストできる。
//

import Foundation

/// 完了済みタスクを「今日」「昨日」「n日前」…でまとめたもの
struct CompletedDateGroup: Identifiable, Equatable {
    /// 並び順（何日前か。1ヶ月前以降は 30／90／180／365）
    let id: Int
    let label: String
    let tasks: [TodoTask]

    static func == (lhs: CompletedDateGroup, rhs: CompletedDateGroup) -> Bool {
        lhs.id == rhs.id && lhs.label == rhs.label && lhs.tasks.map(\.id) == rhs.tasks.map(\.id)
    }
}

/// 期限の表示用ラベル
struct DueLabel: Equatable {
    let text: String
    /// 未完了で期限を過ぎている（赤で表示する）
    let isOverdue: Bool
}

struct TaskQuery {
    var calendar: Calendar = .current
    var now: Date = Date()

    // MARK: 未完了

    /// 未完了タスクがこのタブに表示されるか
    func isIncompleteVisible(_ task: TodoTask, in filter: TaskFilter) -> Bool {
        guard !task.isCompleted else { return false }
        switch filter {
        case .day:
            guard let due = task.dueDate else { return false }
            return calendar.isDate(due, inSameDayAs: now)
        case .week:
            guard let due = task.dueDate else { return false }
            return calendar.isDate(due, equalTo: now, toGranularity: .weekOfYear)
        case .month:
            guard let due = task.dueDate else { return false }
            return calendar.isDate(due, equalTo: now, toGranularity: .month)
        case .all:
            guard let due = task.dueDate else { return true }
            return calendar.startOfDay(for: due) < calendar.startOfDay(for: now)
        case .history:
            return false
        }
    }

    /// このタブに表示する未完了タスク（期限の早い順。期限なしは最後）
    func incompleteTasks(from tasks: [TodoTask], in filter: TaskFilter) -> [TodoTask] {
        tasks
            .filter { isIncompleteVisible($0, in: filter) }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    /// このタブの一覧に出すタスク（未完了＋このタブの範囲で完了したもの）。
    /// 完了しても位置が変わらないよう、完了状態ではなく期限→作成日の順で並べる。「履歴」は対象外。
    func listedTasks(from tasks: [TodoTask], in filter: TaskFilter) -> [TodoTask] {
        guard filter != .history else { return [] }
        return tasks
            .filter { task in
                if task.isCompleted {
                    guard let completedDate = task.completedDate else { return false }
                    return isCompletedVisible(completedDate: completedDate, in: filter)
                }
                return isIncompleteVisible(task, in: filter)
            }
            .sorted { lhs, rhs in
                let l = lhs.dueDate ?? .distantFuture
                let r = rhs.dueDate ?? .distantFuture
                return l != r ? l < r : lhs.createdDate < rhs.createdDate
            }
    }

    /// タブに表示する未完了の件数。「履歴」は件数を出さないので nil
    func incompleteCount(in tasks: [TodoTask], for filter: TaskFilter) -> Int? {
        guard filter != .history else { return nil }
        return tasks.filter { isIncompleteVisible($0, in: filter) }.count
    }

    // MARK: 完了済み

    /// 完了済みタスクがこのタブに表示されるか（設計書 v3.0「完了タスクの表示ルール」）
    func isCompletedVisible(completedDate: Date, in filter: TaskFilter) -> Bool {
        let daysAgo = daysBefore(completedDate)
        switch filter {
        case .day: return calendar.isDate(completedDate, inSameDayAs: now)
        case .week: return calendar.isDate(completedDate, equalTo: now, toGranularity: .weekOfYear)
        case .month: return calendar.isDate(completedDate, equalTo: now, toGranularity: .month)
        case .all: return daysAgo < 8
        case .history: return daysAgo >= 8
        }
    }

    /// 完了日をどのグループに入れるか
    func dateBucket(for date: Date) -> (key: String, label: String, rank: Int) {
        let daysAgo = daysBefore(date)
        switch daysAgo {
        case 0: return ("d0", "今日", 0)
        case 1: return ("d1", "昨日", 1)
        case 2..<30: return ("d\(daysAgo)", "\(daysAgo)日前", daysAgo)
        case 30..<90: return ("m1", "1ヶ月前", 30)
        case 90..<180: return ("m3", "3ヶ月前", 90)
        case 180..<365: return ("m6", "6ヶ月前", 180)
        default: return ("y1", "1年以上前", 365)
        }
    }

    /// このタブに表示する完了済みタスクを、新しい日付のグループから順に返す
    func completedGroups(from tasks: [TodoTask], in filter: TaskFilter) -> [CompletedDateGroup] {
        var buckets: [String: (label: String, rank: Int, tasks: [TodoTask])] = [:]
        for task in tasks {
            guard task.isCompleted, let completedDate = task.completedDate,
                  isCompletedVisible(completedDate: completedDate, in: filter) else { continue }
            let bucket = dateBucket(for: completedDate)
            buckets[bucket.key, default: (bucket.label, bucket.rank, [])].tasks.append(task)
        }

        return buckets.values
            .map { value in
                CompletedDateGroup(
                    id: value.rank,
                    label: value.label,
                    tasks: value.tasks.sorted { ($0.completedDate ?? .distantPast) > ($1.completedDate ?? .distantPast) }
                )
            }
            .sorted { $0.id < $1.id }
    }

    // MARK: 進み具合

    /// このタブの進み具合（完了 / 完了＋未完了）。「履歴」は未完了がないので nil
    func progress(in tasks: [TodoTask], for filter: TaskFilter) -> (done: Int, total: Int)? {
        guard filter != .history else { return nil }
        let remaining = tasks.filter { isIncompleteVisible($0, in: filter) }.count
        let done = tasks.filter { task in
            guard task.isCompleted, let completedDate = task.completedDate else { return false }
            return isCompletedVisible(completedDate: completedDate, in: filter)
        }.count
        return (done, done + remaining)
    }

    /// 「履歴」タブに出る完了済みタスクの数
    func historyCount(in tasks: [TodoTask]) -> Int {
        tasks.filter { task in
            guard task.isCompleted, let completedDate = task.completedDate else { return false }
            return isCompletedVisible(completedDate: completedDate, in: .history)
        }.count
    }

    // MARK: 期限の表示

    /// 期限の表示用ラベル（今日・明日・n日遅れ・11/20(金) など）
    func dueLabel(for dueDate: Date, isCompleted: Bool) -> DueLabel {
        let startDue = calendar.startOfDay(for: dueDate)
        let startNow = calendar.startOfDay(for: now)
        let diff = calendar.dateComponents([.day], from: startNow, to: startDue).day ?? 0

        switch diff {
        case 0: return DueLabel(text: "今日", isOverdue: false)
        case 1: return DueLabel(text: "明日", isOverdue: false)
        case ..<0 where !isCompleted: return DueLabel(text: "\(-diff)日遅れ", isOverdue: true)
        default:
            let sameYear = calendar.isDate(dueDate, equalTo: now, toGranularity: .year)
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.timeZone = calendar.timeZone
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = sameYear ? "M/d(E)" : "yyyy/M/d"
            return DueLabel(text: formatter.string(from: dueDate), isOverdue: false)
        }
    }

    // MARK: -

    /// `date` が今日から何日前か（未来は 0）
    private func daysBefore(_ date: Date) -> Int {
        max(0, calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: date),
            to: calendar.startOfDay(for: now)
        ).day ?? 0)
    }
}
