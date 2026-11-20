//
//  WidgetTaskQueryTests.swift
//  todoappTests
//
//  ウィジェットに出すタスクの選び方（docs/widgets.md 4.1）と、ウィジェットからアプリを開く URL。
//  基準日: 2026-11-12（木）10:00 JST。週は日曜はじまり（11/8〜11/14）。
//

import Foundation
import SwiftData
import Testing
@testable import todoapp

@MainActor
struct WidgetTaskQueryTests {
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

    private func day(_ month: Int, _ day: Int, hour: Int = 9) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
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

    private var sample: [TodoTask] {
        [
            task("期限切れ", due: day(11, 10)),
            task("今日", due: day(11, 12)),
            task("明日", due: day(11, 13)),
            task("土曜", due: day(11, 14)),
            task("来週", due: day(11, 16)),
            task("来月", due: day(12, 1)),
            task("期限なし"),
        ]
    }

    @Test(arguments: [
        (WidgetDueRange.today, ["期限切れ", "今日"]),
        (.tomorrow, ["期限切れ", "今日", "明日"]),
        (.thisWeek, ["期限切れ", "今日", "明日", "土曜"]),
        (.thisMonth, ["期限切れ", "今日", "明日", "土曜", "来週"]),
    ])
    func rangeAlwaysIncludesOverdue(range: WidgetDueRange, expected: [String]) {
        let result = query.widgetTasks(from: sample, range: range, includesUndated: false)
        #expect(result.map(\.title) == expected)
    }

    @Test func undatedTasksComeLastWhenIncluded() {
        let result = query.widgetTasks(from: sample, range: .today, includesUndated: true)
        #expect(result.map(\.title) == ["期限切れ", "今日", "期限なし"])
    }

    @Test func checkedTodayStaysInPlaceButOlderCompletionsDisappear() {
        let tasks = [
            task("朝に完了", due: day(11, 12, hour: 8), completedAt: day(11, 12, hour: 9)),
            task("未完了", due: day(11, 12)),
            task("昨日完了", due: day(11, 11), completedAt: day(11, 11, hour: 20)),
        ]
        let result = query.widgetTasks(from: tasks, range: .today, includesUndated: false)
        #expect(result.map(\.title) == ["朝に完了", "未完了"])
        #expect(query.widgetProgress(of: result) == WidgetProgress(done: 1, total: 2))
    }

    @Test func progressIsCompleteOnlyWhenEverythingIsDone() {
        #expect(WidgetProgress(done: 0, total: 0).isComplete == false)
        #expect(WidgetProgress(done: 2, total: 2).isComplete)
        #expect(WidgetProgress(done: 1, total: 3).remaining == 2)
    }

    @Test func appLinksRoundTrip() {
        let id = UUID()
        for link in [AppLink.task(id), .group(id), .allGroups] {
            #expect(AppLink(url: link.url) == link)
        }
        #expect(AppLink(url: URL(string: "https://example.com/task/1")!) == nil)
    }
}

/// 以前のデータを App Group へ写す処理（docs/widgets.md 4.3）
@MainActor
struct SharedStoreMigrationTests {
    private func makeDirectory(_ name: String) throws -> URL {
        // 実際の場所と同じく、名前に空白を含める
        let url = FileManager.default.temporaryDirectory
            .appending(path: "SharedStoreTests-\(UUID().uuidString)/\(name)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func copiesAllSQLiteFilesOnceAndKeepsTheOriginal() throws {
        let legacy = try makeDirectory("Application Support").appending(path: "default.store")
        let shared = try makeDirectory("Group Support").appending(path: "default.store")
        for suffix in ["", "-wal", "-shm"] {
            try Data("old\(suffix)".utf8).write(to: URL(filePath: legacy.path(percentEncoded: false) + suffix))
        }

        SharedStore.moveLegacyStoreIfNeeded(from: legacy, to: shared)

        for suffix in ["", "-wal", "-shm"] {
            let copied = try Data(contentsOf: URL(filePath: shared.path(percentEncoded: false) + suffix))
            #expect(String(decoding: copied, as: UTF8.self) == "old\(suffix)")
            #expect(FileManager.default.fileExists(atPath: legacy.path(percentEncoded: false) + suffix))
        }
    }

    @Test func doesNothingWhenSharedStoreAlreadyExists() throws {
        let legacy = try makeDirectory("Application Support").appending(path: "default.store")
        let shared = try makeDirectory("Group Support").appending(path: "default.store")
        try Data("old".utf8).write(to: legacy)
        try Data("new".utf8).write(to: shared)

        SharedStore.moveLegacyStoreIfNeeded(from: legacy, to: shared)

        #expect(String(decoding: try Data(contentsOf: shared), as: UTF8.self) == "new")
    }
}
