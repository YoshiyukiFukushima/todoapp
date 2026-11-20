//
//  WidgetIntents.swift
//  TodoWidgets
//
//  ウィジェットの設定（長押し →「ウィジェットを編集」）と、チェックの操作。docs/widgets.md 4.1・4.2。
//

import AppIntents
import WidgetKit

// MARK: - 何を出すか（すべてのグループ／グループ 1 つ／サブグループ 1 つ）

nonisolated struct TaskSourceEntity: AppEntity, Hashable {
    enum Kind: Hashable { case allGroups, group(UUID), subgroup(UUID) }

    /// "all"・"group:<id>"・"subgroup:<id>"
    let id: String
    let name: String

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "表示するもの"
    static let defaultQuery = TaskSourceQuery()

    static let allGroups = TaskSourceEntity(id: "all", name: "すべてのグループ")

    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }

    var kind: Kind {
        let parts = id.split(separator: ":", maxSplits: 1).map(String.init)
        if parts.count == 2, let uuid = UUID(uuidString: parts[1]) {
            return parts[0] == "subgroup" ? .subgroup(uuid) : .group(uuid)
        }
        return .allGroups
    }
}

nonisolated struct TaskSourceQuery: EntityQuery {
    func entities(for identifiers: [TaskSourceEntity.ID]) async throws -> [TaskSourceEntity] {
        let all = await MainActor.run { WidgetDataStore.sourceChoices() }
        return all.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [TaskSourceEntity] {
        await MainActor.run { WidgetDataStore.sourceChoices() }
    }

    func defaultResult() async -> TaskSourceEntity? {
        .allGroups
    }
}

// MARK: - いつ期限までを出すか

nonisolated enum DueRangeOption: String, AppEnum {
    case today, tomorrow, thisWeek, thisMonth

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "期限"
    static let caseDisplayRepresentations: [DueRangeOption: DisplayRepresentation] = [
        .today: "今日まで",
        .tomorrow: "明日まで",
        .thisWeek: "今週まで",
        .thisMonth: "今月まで",
    ]

    var range: WidgetDueRange { WidgetDueRange(rawValue: rawValue) ?? .today }
}

// MARK: - ウィジェットの設定

struct TaskWidgetConfigIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "表示するタスク"
    static let description = IntentDescription("ウィジェットに出すグループと期限を選びます。期限切れのタスクはいつも出ます。")

    @Parameter(title: "表示するもの")
    var source: TaskSourceEntity?

    @Parameter(title: "期限", default: .today)
    var range: DueRangeOption

    @Parameter(title: "期限なしのタスクも出す", default: false)
    var includesUndated: Bool

    init() {}

    init(source: TaskSourceEntity, range: DueRangeOption = .today, includesUndated: Bool = false) {
        self.source = source
        self.range = range
        self.includesUndated = includesUndated
    }
}

// MARK: - チェック（完了／未完了の切り替え。アプリは開かない）

struct ToggleTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "タスクの完了を切り替える"
    static let isDiscoverable = false

    @Parameter(title: "タスク")
    var taskID: String

    init() {}

    init(taskID: UUID) {
        self.taskID = taskID.uuidString
    }

    func perform() async throws -> some IntentResult {
        let id = UUID(uuidString: taskID)
        await MainActor.run {
            if let id { WidgetDataStore.toggleTask(id: id) }
        }
        // ホーム画面とロック画面のウィジェットをそろえる
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
