//
//  WidgetDataStore.swift
//  TodoWidgets
//
//  ウィジェットからデータを読み書きする。アプリと同じ App Group のデータを使う（docs/widgets.md 4.3）。
//

import Foundation
import SwiftData
import SwiftUI
import WidgetKit

/// ウィジェットに出す 1 行（モデルを外へ持ち出さないよう、値だけにする）
nonisolated struct WidgetTaskItem: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    let isCompleted: Bool
    let dueText: String?
    let isOverdue: Bool
    /// すべてのグループを出しているときだけ、どのグループのタスクかを出す
    let groupName: String?
    let groupSymbol: String?
}

/// ウィジェット 1 つ分の中身
nonisolated struct TaskWidgetEntry: TimelineEntry, Sendable {
    enum State: Sendable {
        case tasks
        /// 選んだグループ・サブグループが消された
        case sourceMissing
        /// グループが 1 つもない
        case noGroups
    }

    let date: Date
    let state: State
    /// 見出し（グループ名など）とアイコン、タップで開く先
    let title: String
    let symbol: String
    let link: URL
    let items: [WidgetTaskItem]
    let done: Int
    let total: Int
    /// 「今日」「今週」など（空のときや全部終わったときの文に使う）
    let scopeLabel: String
    let theme: ColorTheme

    var remaining: Int { total - done }
    var isAllDone: Bool { total > 0 && done == total }
    var fraction: Double { total == 0 ? 0 : Double(done) / Double(total) }

    /// 見本（ウィジェットを選ぶ画面で出す）
    static func placeholder(theme: ColorTheme = .defaultTheme) -> TaskWidgetEntry {
        let titles = ["水を1杯飲む", "メールを返す", "洗濯物をたたむ", "アプリの画面を考える", "10分散歩する"]
        let items = titles.enumerated().map { index, title in
            WidgetTaskItem(id: UUID(), title: title, isCompleted: index == 0, dueText: "今日", isOverdue: false,
                           groupName: nil, groupSymbol: nil)
        }
        return TaskWidgetEntry(date: Date(), state: .tasks, title: "ホーム", symbol: "house.fill",
                               link: AppLink.allGroups.url, items: items, done: 1, total: items.count,
                               scopeLabel: "今日", theme: theme)
    }
}

enum WidgetDataStore {
    private static let container: ModelContainer? = try? SharedStore.makeContainer(migrateLegacyStore: false)

    /// 毎回新しいコンテキストで読む（アプリ側の変更を取りこぼさないため）
    private static func makeContext() -> ModelContext? {
        container.map { ModelContext($0) }
    }

    private static func groups(in context: ModelContext) -> [TodoGroup] {
        (try? context.fetch(FetchDescriptor<TodoGroup>(sortBy: [SortDescriptor(\.order)]))) ?? []
    }

    private static func symbol(for group: TodoGroup) -> String {
        if case .symbol(let name) = group.glyph { return name }
        return "folder.fill"
    }

    // MARK: 設定の選択肢

    /// 「すべてのグループ」、各グループ、各サブグループ（「仕事 › 開発」）
    static func sourceChoices() -> [TaskSourceEntity] {
        guard let context = makeContext() else { return [.allGroups] }
        var choices: [TaskSourceEntity] = [.allGroups]
        for group in groups(in: context) {
            choices.append(TaskSourceEntity(id: "group:\(group.id.uuidString)", name: group.name))
            for subgroup in group.subgroups.sorted(by: { $0.order < $1.order }) {
                choices.append(TaskSourceEntity(id: "subgroup:\(subgroup.id.uuidString)",
                                                name: "\(group.name) › \(subgroup.name)"))
            }
        }
        return choices
    }

    // MARK: 中身を作る

    static func entry(for configuration: TaskWidgetConfigIntent, now: Date = Date()) -> TaskWidgetEntry {
        let theme = ThemeManager.storedTheme()
        let range = configuration.range.range
        let source = configuration.source ?? .allGroups

        guard let context = makeContext() else {
            return emptyEntry(state: .noGroups, now: now, theme: theme, range: range)
        }
        let allGroups = groups(in: context)
        guard !allGroups.isEmpty else {
            return emptyEntry(state: .noGroups, now: now, theme: theme, range: range)
        }

        let title: String
        let symbol: String
        let link: URL
        let tasks: [TodoTask]
        let showsGroup: Bool
        switch source.kind {
        case .allGroups:
            title = "すべてのグループ"
            symbol = "square.stack.3d.up.fill"
            link = AppLink.allGroups.url
            tasks = allGroups.flatMap(\.tasks)
            showsGroup = true
        case .group(let id):
            guard let group = allGroups.first(where: { $0.id == id }) else {
                return emptyEntry(state: .sourceMissing, now: now, theme: theme, range: range)
            }
            title = group.name
            symbol = Self.symbol(for: group)
            link = AppLink.group(group.id).url
            tasks = group.tasks
            showsGroup = false
        case .subgroup(let id):
            guard let group = allGroups.first(where: { $0.subgroups.contains { $0.id == id } }),
                  let subgroup = group.subgroups.first(where: { $0.id == id }) else {
                return emptyEntry(state: .sourceMissing, now: now, theme: theme, range: range)
            }
            title = subgroup.name
            symbol = Self.symbol(for: group)
            link = AppLink.group(group.id).url
            tasks = subgroup.tasks
            showsGroup = false
        }

        let query = TaskQuery(now: now)
        let listed = query.widgetTasks(from: tasks, range: range, includesUndated: configuration.includesUndated)
        let items = listed.map { task in
            let due = task.dueDate.map { query.dueLabel(for: $0, isCompleted: task.isCompleted) }
            return WidgetTaskItem(
                id: task.id,
                title: task.title,
                isCompleted: task.isCompleted,
                dueText: due?.text,
                isOverdue: due?.isOverdue ?? false,
                groupName: showsGroup ? task.group?.name : nil,
                groupSymbol: showsGroup ? task.group.map { Self.symbol(for: $0) } : nil
            )
        }
        let done = items.filter(\.isCompleted).count
        return TaskWidgetEntry(date: now, state: .tasks, title: title, symbol: symbol, link: link,
                               items: items, done: done, total: items.count,
                               scopeLabel: range.scopeLabel, theme: theme)
    }

    private static func emptyEntry(state: TaskWidgetEntry.State, now: Date, theme: ColorTheme,
                                   range: WidgetDueRange) -> TaskWidgetEntry {
        TaskWidgetEntry(date: now, state: state, title: "やること", symbol: "checklist",
                        link: AppLink.allGroups.url, items: [], done: 0, total: 0,
                        scopeLabel: range.scopeLabel, theme: theme)
    }

    // MARK: チェック

    /// アプリと同じ処理で完了／未完了を切り替える（繰り返しなら次の回も作る）
    static func toggleTask(id: UUID) {
        guard let context = makeContext() else { return }
        let descriptor = FetchDescriptor<TodoTask>(predicate: #Predicate { $0.id == id })
        guard let task = try? context.fetch(descriptor).first else { return }
        TaskViewModel(modelContext: context).toggleComplete(task)
        try? context.save()
    }
}

// MARK: - いつ描き直すか

nonisolated struct TaskWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TaskWidgetEntry {
        .placeholder()
    }

    func snapshot(for configuration: TaskWidgetConfigIntent, in context: Context) async -> TaskWidgetEntry {
        if context.isPreview {
            let theme = await MainActor.run { ThemeManager.storedTheme() }
            return .placeholder(theme: theme)
        }
        return await MainActor.run { WidgetDataStore.entry(for: configuration) }
    }

    func timeline(for configuration: TaskWidgetConfigIntent, in context: Context) async -> Timeline<TaskWidgetEntry> {
        let entry = await MainActor.run { WidgetDataStore.entry(for: configuration) }
        // 日付が変わると「今日」の範囲が変わるので、次の 0 時に描き直す
        let calendar = Calendar.current
        let nextMidnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextMidnight))
    }

    func recommendations() -> [AppIntentRecommendation<TaskWidgetConfigIntent>] {
        [AppIntentRecommendation(intent: TaskWidgetConfigIntent(source: .allGroups), description: "すべてのグループの今日のタスク")]
    }
}
