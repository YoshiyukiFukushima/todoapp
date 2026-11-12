//
//  TaskQueryTests.swift
//  todoappTests
//
//  タブごとの絞り込み・件数・完了済みのグループ分けが、部品分けの前と同じ結果になることを確かめる。
//  基準日: 2026-11-12（木）10:00 JST。週は日曜はじまり（11/8〜11/14）。
//

import Foundation
import SwiftData
import Testing
@testable import todoapp

@MainActor
struct TaskQueryTests {
    let calendar: Calendar
    let now: Date
    let query: TaskQuery
    let container: ModelContainer

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        calendar.firstWeekday = 1
        self.calendar = calendar
        self.now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 12, hour: 10))!
        self.query = TaskQuery(calendar: calendar, now: now)
        self.container = try ModelContainer(
            for: TodoGroup.self, SubGroup.self, TodoTask.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    // MARK: helpers

    private func day(_ month: Int, _ day: Int, hour: Int = 9) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    private func daysAgo(_ n: Int) -> Date {
        calendar.date(byAdding: .day, value: -n, to: now)!
    }

    private func task(_ title: String, due: Date? = nil, completedAt: Date? = nil) -> TodoTask {
        let task = TodoTask(title: title, dueDate: due, group: nil)
        container.mainContext.insert(task)
        if let completedAt {
            task.isCompleted = true
            task.completedDate = completedAt
        }
        return task
    }

    private func titles(_ tasks: [TodoTask]) -> [String] { tasks.map(\.title) }

    // MARK: 未完了の絞り込み

    @Test func dayShowsOnlyTasksDueToday() {
        let tasks = [
            task("今日", due: day(11, 12)),
            task("明日", due: day(11, 13)),
            task("期限なし"),
            task("今日・完了済み", due: day(11, 12), completedAt: now),
        ]
        #expect(titles(query.incompleteTasks(from: tasks, in: .day)) == ["今日"])
    }

    @Test func weekUsesSundayStartWeek() {
        let tasks = [
            task("日曜", due: day(11, 8)),
            task("土曜", due: day(11, 14)),
            task("翌週の日曜", due: day(11, 15)),
            task("前の週の土曜", due: day(11, 7)),
        ]
        #expect(titles(query.incompleteTasks(from: tasks, in: .week)) == ["日曜", "土曜"])
    }

    @Test func monthShowsTasksDueThisMonth() {
        let tasks = [
            task("11/1", due: day(11, 1)),
            task("11/30", due: day(11, 30)),
            task("12/1", due: day(12, 1)),
            task("10/31", due: day(10, 31)),
        ]
        #expect(titles(query.incompleteTasks(from: tasks, in: .month)) == ["11/1", "11/30"])
    }

    @Test func allShowsUndatedAndOverdueOnly() {
        let tasks = [
            task("期限なし"),
            task("期限切れ", due: day(11, 10)),
            task("今日", due: day(11, 12)),
            task("未来", due: day(11, 20)),
        ]
        #expect(titles(query.incompleteTasks(from: tasks, in: .all)) == ["期限切れ", "期限なし"])
    }

    @Test func historyShowsNoIncompleteTasks() {
        let tasks = [task("期限なし"), task("今日", due: day(11, 12))]
        #expect(query.incompleteTasks(from: tasks, in: .history).isEmpty)
        #expect(query.incompleteCount(in: tasks, for: .history) == nil)
    }

    @Test func incompleteTasksAreSortedByDueDateWithUndatedLast() {
        let tasks = [
            task("期限なし"),
            task("11/14", due: day(11, 14)),
            task("11/9", due: day(11, 9)),
        ]
        #expect(titles(query.incompleteTasks(from: tasks, in: .month)) == ["11/9", "11/14"])
        #expect(titles(query.incompleteTasks(from: tasks, in: .all)) == ["11/9", "期限なし"])
    }

    @Test(arguments: [TaskFilter.day, .week, .month, .all])
    func countMatchesVisibleTasks(filter: TaskFilter) {
        let tasks = [
            task("期限なし"),
            task("期限切れ", due: day(11, 1)),
            task("今日", due: day(11, 12)),
            task("今週", due: day(11, 14)),
            task("今月", due: day(11, 28)),
            task("完了", due: day(11, 12), completedAt: now),
        ]
        #expect(query.incompleteCount(in: tasks, for: filter) == query.incompleteTasks(from: tasks, in: filter).count)
    }

    // MARK: 完了済み

    @Test func completedVisibilityPerTab() {
        #expect(query.isCompletedVisible(completedDate: now, in: .day))
        #expect(!query.isCompletedVisible(completedDate: daysAgo(1), in: .day))

        #expect(query.isCompletedVisible(completedDate: daysAgo(7), in: .all))
        #expect(!query.isCompletedVisible(completedDate: daysAgo(8), in: .all))

        #expect(!query.isCompletedVisible(completedDate: daysAgo(7), in: .history))
        #expect(query.isCompletedVisible(completedDate: daysAgo(8), in: .history))

        // 11/8（日）は今週、11/7（土）は先週
        #expect(query.isCompletedVisible(completedDate: day(11, 8), in: .week))
        #expect(!query.isCompletedVisible(completedDate: day(11, 7), in: .week))

        #expect(query.isCompletedVisible(completedDate: day(11, 1), in: .month))
        #expect(!query.isCompletedVisible(completedDate: day(10, 31), in: .month))
    }

    @Test(arguments: [
        (0, "今日", 0), (1, "昨日", 1), (2, "2日前", 2), (29, "29日前", 29),
        (30, "1ヶ月前", 30), (89, "1ヶ月前", 30), (90, "3ヶ月前", 90),
        (179, "3ヶ月前", 90), (180, "6ヶ月前", 180), (364, "6ヶ月前", 180), (365, "1年以上前", 365),
    ])
    func dateBucketLabels(days: Int, label: String, rank: Int) {
        let bucket = query.dateBucket(for: daysAgo(days))
        #expect(bucket.label == label)
        #expect(bucket.rank == rank)
    }

    @Test func completedGroupsAreOrderedNewestFirst() {
        let tasks = [
            task("昨日A", completedAt: daysAgo(1).addingTimeInterval(-3600)),
            task("今日", completedAt: now.addingTimeInterval(-60)),
            task("昨日B", completedAt: daysAgo(1)),
            task("3日前", completedAt: daysAgo(3)),
            task("10日前", completedAt: daysAgo(10)),
            task("未完了"),
        ]
        let groups = query.completedGroups(from: tasks, in: .all)
        #expect(groups.map(\.label) == ["今日", "昨日", "3日前"])
        #expect(titles(groups[1].tasks) == ["昨日B", "昨日A"])

        let history = query.completedGroups(from: tasks, in: .history)
        #expect(history.map(\.label) == ["10日前"])
    }

    // MARK: 繰り返し

    @Test(arguments: [
        (RepeatInterval.daily, 11, 13), (.every3Days, 11, 15), (.weekly, 11, 19),
        (.biweekly, 11, 26), (.monthly, 12, 12),
    ])
    func repeatIntervalNextDate(interval: RepeatInterval, month: Int, dayOfMonth: Int) {
        let next = interval.nextDate(after: day(11, 12), calendar: calendar)
        #expect(next == day(month, dayOfMonth))
    }

    @Test func noRepeatHasNoNextDate() {
        #expect(RepeatInterval.none.nextDate(after: now, calendar: calendar) == nil)
    }

    @Test func nextRepeatDateRequiresRepeatingTask() {
        let once = TodoTask(title: "一回だけ", repeatInterval: .none, group: nil)
        #expect(once.nextRepeatDate == nil)

        let daily = TodoTask(title: "毎日", isRepeating: true, repeatInterval: .daily, group: nil)
        daily.completedDate = now
        #expect(daily.nextRepeatDate == Calendar.current.date(byAdding: .day, value: 1, to: now))
    }

    @Test func completingRepeatingTaskCreatesNextTask() throws {
        let context = container.mainContext
        let original = TodoTask(title: "洗濯", isRepeating: true, repeatInterval: .weekly, group: nil)
        context.insert(original)

        TaskViewModel(modelContext: context).toggleComplete(original)

        let all = try context.fetch(FetchDescriptor<TodoTask>())
        #expect(all.count == 2)
        let next = try #require(all.first { !$0.isCompleted })
        #expect(next.title == "洗濯")
        #expect(next.repeatIntervalEnum == .weekly)
        let completedDate = try #require(original.completedDate)
        #expect(next.dueDate == Calendar.current.date(byAdding: .day, value: 7, to: completedDate))
    }
}
