//
//  LockScreenWidgets.swift
//  TodoWidgets
//
//  ロック画面のウィジェット（docs/widgets.md 2 章）。
//  ロック画面は iOS が単色で描くので、テーマの色は使わず、形（チェックの丸・輪）だけそろえる。
//

import AppIntents
import SwiftUI
import WidgetKit

// MARK: - 長方形：タスク 2 件（チェックできる）

struct LockTaskListView: View {
    let entry: TaskWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: entry.symbol)
                    .imageScale(.small)
                Text(entry.title)
                    .lineLimit(1)
                Spacer(minLength: DS.Spacing.xs)
                if entry.state == .tasks, entry.total > 0 {
                    Text("\(entry.done)/\(entry.total)")
                        .monospacedDigit()
                }
            }
            .font(.system(.caption, design: .rounded, weight: .bold))
            .widgetAccentable()

            switch entry.state {
            case .tasks:
                let remaining = entry.items.filter { !$0.isCompleted }
                if entry.items.isEmpty {
                    Text("\(entry.scopeLabel)のタスクはありません")
                        .font(.system(.caption, design: .rounded))
                } else if remaining.isEmpty {
                    Label("\(entry.scopeLabel)の分はすべて完了", systemImage: "checkmark.circle.fill")
                        .font(.system(.caption, design: .rounded))
                } else {
                    // 狭いので、まだ終わっていないものを先に出す
                    ForEach(Array(remaining.prefix(2))) { item in
                        row(item)
                    }
                }
            case .sourceMissing:
                Text("グループが見つかりません")
                    .font(.system(.caption, design: .rounded))
            case .noGroups:
                Text("アプリでグループを作ってください")
                    .font(.system(.caption, design: .rounded))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ item: WidgetTaskItem) -> some View {
        HStack(spacing: DS.Spacing.xs) {
            Button(intent: ToggleTaskIntent(taskID: item.id)) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(.body, design: .rounded, weight: .semibold))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isCompleted ? "未完了に戻す" : "完了にする")
            .accessibilityValue(item.title)

            Text(item.title)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .lineLimit(1)
            if item.isOverdue, let dueText = item.dueText {
                Text(dueText)
                    .font(.system(.caption2, design: .rounded))
            }
        }
    }
}

struct LockTaskListWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: WidgetKinds.lockList, intent: TaskWidgetConfigIntent.self,
                               provider: TaskWidgetProvider()) { entry in
            LockTaskListView(entry: entry)
                .widgetURL(entry.link)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("タスク")
        .description("残っているタスクを確認して、そのままチェックできます。")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - 円：進み具合と残り件数／1 行：残り件数と次のタスク

struct LockProgressView: View {
    let entry: TaskWidgetEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryInline:
            inline
        default:
            circular
        }
    }

    private var circular: some View {
        Gauge(value: entry.fraction) {
            Image(systemName: entry.symbol)
        } currentValueLabel: {
            if entry.isAllDone {
                Image(systemName: "checkmark")
            } else {
                Text("\(entry.remaining)")
                    .font(.system(.title3, design: .rounded, weight: .bold))
            }
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .accessibilityLabel(entry.isAllDone ? "\(entry.scopeLabel)の分はすべて完了" : "残り\(entry.remaining)件")
    }

    @ViewBuilder
    private var inline: some View {
        if entry.state != .tasks {
            Label("やること", systemImage: "checklist")
        } else if entry.isAllDone {
            Label("\(entry.scopeLabel)の分はすべて完了", systemImage: "checkmark.circle")
        } else if let next = entry.items.first(where: { !$0.isCompleted }) {
            Label("残り\(entry.remaining)件・\(next.title)", systemImage: "checklist")
        } else {
            Label("\(entry.scopeLabel)のタスクはありません", systemImage: "checklist")
        }
    }
}

struct LockProgressWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: WidgetKinds.lockProgress, intent: TaskWidgetConfigIntent.self,
                               provider: TaskWidgetProvider()) { entry in
            LockProgressView(entry: entry)
                .widgetURL(entry.link)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("進み具合")
        .description("残りの件数と、次にやることを出します。")
        .supportedFamilies([.accessoryCircular, .accessoryInline])
    }
}

// MARK: - まとめ

@main
struct TodoWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TaskListWidget()
        LockTaskListWidget()
        LockProgressWidget()
    }
}
