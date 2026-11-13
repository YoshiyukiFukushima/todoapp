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

    // MARK: 進み具合・期限の表示

    @Test func progressCountsDoneAndRemainingInTab() throws {
        let tasks = [
            task("今日・未完了", due: day(11, 12)),
            task("今日・完了", due: day(11, 12), completedAt: now),
            task("昨日完了", due: day(11, 11), completedAt: daysAgo(1)),
            task("明日", due: day(11, 13)),
        ]
        let today = try #require(query.progress(in: tasks, for: .day))
        #expect(today.done == 1)
        #expect(today.total == 2)
        let week = try #require(query.progress(in: tasks, for: .week))
        #expect(week.done == 2)
        #expect(week.total == 4)
        #expect(query.progress(in: tasks, for: .history) == nil)
    }

    @Test func dueLabels() {
        #expect(query.dueLabel(for: day(11, 12), isCompleted: false) == DueLabel(text: "今日", isOverdue: false))
        #expect(query.dueLabel(for: day(11, 13), isCompleted: false) == DueLabel(text: "明日", isOverdue: false))
        #expect(query.dueLabel(for: day(11, 10), isCompleted: false) == DueLabel(text: "2日遅れ", isOverdue: true))
        #expect(query.dueLabel(for: day(11, 20), isCompleted: false) == DueLabel(text: "11/20(金)", isOverdue: false))
        // 完了済みは遅れ表示にしない
        #expect(query.dueLabel(for: day(11, 10), isCompleted: true) == DueLabel(text: "11/10(火)", isOverdue: false))
        let nextYear = calendar.date(from: DateComponents(year: 2027, month: 1, day: 5, hour: 9))!
        #expect(query.dueLabel(for: nextYear, isCompleted: false).text == "2027/1/5")
    }

    // MARK: グループの見た目

    @Test func legacyGroupIconsMapToSymbolsOrFirstLetter() {
        #expect(GroupAppearance.glyph(icon: "🏠", name: "ホーム") == .symbol("house.fill"))
        #expect(GroupAppearance.glyph(icon: "cart.fill", name: "買い物") == .symbol("cart.fill"))
        #expect(GroupAppearance.glyph(icon: "🦄", name: "趣味") == .letter("趣"))
    }

    @Test func legacyGroupColorsMapToAccents() {
        #expect(GroupAppearance.accent(colorHex: AppTheme.lavender.colorHex) == .grape)
        #expect(GroupAppearance.accent(colorHex: AppTheme.mint.colorHex) == .teal)
        #expect(GroupAppearance.accent(colorHex: "mikan") == .mikan)
        #expect(GroupAppearance.accent(colorHex: "#1E6FD9") == .sky)
        #expect(GroupAppearance.accent(colorHex: "#808080") == .cocoa)
    }

    // MARK: 完了してもその場に残る

    @Test func completedTasksStayInPlaceWithinTab() {
        let a = task("A", due: day(11, 12, hour: 8))
        let b = task("B", due: day(11, 12, hour: 9))
        let c = task("C", due: day(11, 12, hour: 10))
        let tasks = [c, a, b]
        #expect(titles(query.listedTasks(from: tasks, in: .day)) == ["A", "B", "C"])

        b.isCompleted = true
        b.completedDate = now
        #expect(titles(query.listedTasks(from: tasks, in: .day)) == ["A", "B", "C"])
    }

    @Test func listedTasksRespectCompletedRangeAndExcludeHistory() {
        let tasks = [
            task("未完了", due: day(11, 12)),
            task("今日完了", due: day(11, 12), completedAt: now),
            task("昨日完了", due: day(11, 11), completedAt: daysAgo(1)),
            task("10日前完了", completedAt: daysAgo(10)),
        ]
        #expect(Set(titles(query.listedTasks(from: tasks, in: .day))) == ["未完了", "今日完了"])
        #expect(Set(titles(query.listedTasks(from: tasks, in: .all))) == ["今日完了", "昨日完了"])
        #expect(query.listedTasks(from: tasks, in: .history).isEmpty)
    }

    // MARK: サブグループの削除

    @Test(arguments: [true, false])
    func deletingSubgroupKeepsOrRemovesTasks(keepingTasks: Bool) throws {
        let context = container.mainContext
        let group = TodoGroup(name: "ホーム", icon: "house.fill", colorHex: "mikan", order: 0)
        context.insert(group)
        let viewModel = GroupViewModel(modelContext: context)
        viewModel.addSubGroup(name: "掃除", to: group, order: 0)
        let subgroup = try #require(try context.fetch(FetchDescriptor<SubGroup>()).first)
        let inside = TodoTask(title: "浴室", group: group, subgroup: subgroup)
        context.insert(inside)
        try context.save()

        viewModel.deleteSubGroup(subgroup, keepingTasks: keepingTasks)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<SubGroup>()).isEmpty)
        let remaining = try context.fetch(FetchDescriptor<TodoTask>())
        if keepingTasks {
            #expect(remaining.map(\.title) == ["浴室"])
            #expect(remaining.first?.subgroup == nil)
            #expect(remaining.first?.group?.name == "ホーム")
        } else {
            #expect(remaining.isEmpty)
        }
    }

    // MARK: 期限のチップ

    @Test func dueChoiceFromExistingDate() {
        #expect(DueChoice(date: nil, now: now, calendar: calendar) == .none)
        #expect(DueChoice(date: day(11, 12, hour: 20), now: now, calendar: calendar) == .today)
        #expect(DueChoice(date: day(11, 13), now: now, calendar: calendar) == .tomorrow)
        #expect(DueChoice(date: day(11, 20), now: now, calendar: calendar) == .custom(day(11, 20)))
    }

    @Test func dueChoiceResolvesDate() {
        #expect(DueChoice.none.resolvedDate(now: now, calendar: calendar) == nil)
        #expect(DueChoice.today.resolvedDate(now: now, calendar: calendar) == now)
        #expect(DueChoice.tomorrow.resolvedDate(now: now, calendar: calendar) == calendar.date(byAdding: .day, value: 1, to: now))
        #expect(DueChoice.custom(day(11, 20)).resolvedDate(now: now, calendar: calendar) == day(11, 20))
    }

    @Test func shortDateText() {
        #expect(query.shortDateText(day(11, 20)) == "11/20(金)")
        let nextYear = calendar.date(from: DateComponents(year: 2027, month: 1, day: 5, hour: 9))!
        #expect(query.shortDateText(nextYear) == "2027/1/5")
    }
}
