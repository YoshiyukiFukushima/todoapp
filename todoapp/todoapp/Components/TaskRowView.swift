//
//  TaskRowView.swift
//  todoapp
//

import SwiftUI

struct TaskRowView: View {
    let task: TodoTask
    let animationsEnabled: Bool
    let fadeOutOnComplete: Bool
    let onTap: () -> Void
    let onToggleComplete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            CheckButton(
                isCompleted: task.isCompleted,
                taskTitle: task.title,
                animationsEnabled: animationsEnabled,
                action: onToggleComplete
            )
            .padding(.leading, DS.Spacing.xs)
            .padding(.top, DS.Spacing.xs)

            Button(action: onTap) {
                TaskRowContent(task: task)
                    .padding(.vertical, DS.Spacing.m)
                    .padding(.trailing, DS.Spacing.l)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("詳細を開く")
        }
        .background(DS.Colors.surface, in: RoundedRectangle(cornerRadius: DS.Radius.l))
        .dsShadow(task.isCompleted ? .none : .card)
        .opacity(task.isCompleted ? DS.Opacity.completed : 1)
        .animation(fadeOutOnComplete ? DS.Motion.fade : nil, value: task.isCompleted)
    }
}

/// タイトル・期限と繰り返し・メモ
private struct TaskRowContent: View {
    let task: TodoTask

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

            if dueLabel != nil || task.isRepeating {
                HStack(spacing: DS.Spacing.s) {
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
