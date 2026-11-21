//
//  TaskRowView.swift
//  todoapp
//

import SwiftUI

struct TaskRowView: View {
    let task: TodoTask
    /// どのグループのタスクかを出す（すべてのグループを見ているとき）
    var showsGroup = false
    let animationsEnabled: Bool
    let fadeOutOnComplete: Bool
    let onTap: () -> Void
    let onToggleComplete: () -> Void

    @Environment(\.dsStyle) private var style
    @Environment(BubbleEffects.self) private var bubbleEffects: BubbleEffects?

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            CheckButton(
                isCompleted: task.isCompleted,
                taskTitle: task.title,
                animationsEnabled: animationsEnabled,
                action: onToggleComplete
            )
            .padding(.leading, style.glassTint != nil ? DS.Spacing.s : DS.Spacing.xs)
            .padding(.top, DS.Spacing.xs)

            Button(action: onTap) {
                TaskRowContent(task: task, showsGroup: showsGroup)
                    .padding(.vertical, DS.Spacing.m)
                    .padding(.trailing, DS.Spacing.l)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("詳細を開く")
        }
        .dsSurface(.card, elevation: task.isCompleted ? .none : .card)
        // 全部終わったときに、このカードから泡をあふれさせるため位置を知らせる
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
            if style.hasCompletionEffects { bubbleEffects?.updateCardFrame(frame, for: task.id) }
        }
        .onDisappear { bubbleEffects?.removeCardFrame(for: task.id) }
        .opacity(task.isCompleted ? DS.Opacity.completed : 1)
        .animation(fadeOutOnComplete ? DS.Motion.fade : nil, value: task.isCompleted)
    }
}

/// タイトル・期限と繰り返し・メモ
private struct TaskRowContent: View {
    let task: TodoTask
    let showsGroup: Bool

    /// 行に出すグループ（アイコンと名前）
    private var groupMeta: (symbol: String, name: String)? {
        guard showsGroup, let group = task.group else { return nil }
        if case .symbol(let symbol) = group.glyph { return (symbol, group.name) }
        return ("folder", group.name)
    }

    private var memoText: String {
        task.memoDisplayMode == 1 ? String(task.memo.prefix(DS.Layout.memoPreviewLength)) : task.memo
    }

    private var dueLabel: DueLabel? {
        task.dueDate.map { TaskQuery().dueLabel(for: $0, isCompleted: task.isCompleted) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
            Text(task.title)
                .font(DS.Typography.taskTitle)
                .strikethrough(task.isCompleted, color: DS.Colors.textSecondary)
                .foregroundStyle(task.isCompleted ? DS.Colors.textSecondary : DS.Colors.textPrimary)
                .multilineTextAlignment(.leading)

            if groupMeta != nil || dueLabel != nil || task.isRepeating {
                HStack(spacing: DS.Spacing.s) {
                    if let groupMeta {
                        MetaItem(symbol: groupMeta.symbol, text: groupMeta.name)
                            .foregroundStyle(DS.Colors.textSecondary)
                            .lineLimit(1)
                    }
                    if let dueLabel {
                        MetaItem(symbol: dueLabel.isOverdue ? "exclamationmark.circle.fill" : "calendar", text: dueLabel.text)
                            .foregroundStyle(dueLabel.isOverdue ? DS.Colors.danger : DS.Colors.textSecondary)
                    }
                    if task.isRepeating {
                        MetaItem(symbol: "repeat", text: task.repeatIntervalEnum.displayName)
                            .foregroundStyle(DS.Colors.textSecondary)
                    }
                }
                .font(DS.Typography.caption)
            }

            if task.memoDisplayMode > 0 && !task.memo.isEmpty {
                Text(memoText)
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .lineLimit(task.memoDisplayMode == 1 ? 1 : nil)
                    .multilineTextAlignment(.leading)
                    .padding(.top, DS.Spacing.xxs)
            }
        }
    }
}

/// 期限・繰り返しなどの小さな「アイコン＋文字」
private struct MetaItem: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(spacing: DS.Spacing.xxs) {
            Image(systemName: symbol)
                .imageScale(.small)
            Text(text)
        }
    }
}
