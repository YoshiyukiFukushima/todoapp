//
//  TaskRowView.swift
//  todoapp
//

import SwiftUI

struct TaskRowView: View {
    let task: TodoTask
    let animationsEnabled: Bool
    let emojiEffectEnabled: Bool
    let fadeOutOnComplete: Bool
    let onTap: () -> Void
    let onToggleComplete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.m) {
            AnimatedCheckboxButton(
                isCompleted: task.isCompleted,
                animationsEnabled: animationsEnabled,
                emojiEffectEnabled: emojiEffectEnabled,
                action: onToggleComplete
            )
            .padding(.top, DS.Spacing.xxs)

            TaskRowContent(task: task)
                .contentShape(Rectangle())
                .onTapGesture(perform: onTap)
        }
        .padding(DS.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.s)
                .fill(task.isCompleted ? DS.Colors.surfaceSunken : DS.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.s)
                .stroke(DS.Colors.separator, lineWidth: DS.Stroke.hairline)
        )
        .opacity(task.isCompleted ? DS.Opacity.completed : 1)
        .animation(fadeOutOnComplete ? DS.Motion.fade : nil, value: task.isCompleted)
    }
}

/// タイトル・期限・メモ
private struct TaskRowContent: View {
    let task: TodoTask

    private var memoText: String {
        task.memoDisplayMode == 1 ? String(task.memo.prefix(DS.Layout.memoPreviewLength)) : task.memo
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            HStack {
                Text(task.title)
                    .font(DS.Typography.taskTitle)
                    .strikethrough(task.isCompleted, color: DS.Colors.textSecondary)
                    .foregroundStyle(task.isCompleted ? DS.Colors.textSecondary : DS.Colors.textPrimary)

                Spacer()

                if task.dueDate != nil {
                    Text(task.displayDate)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.textSecondary)
                }
            }

            if task.memoDisplayMode > 0 && !task.memo.isEmpty {
                Text(memoText)
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .lineLimit(task.memoDisplayMode == 1 ? 1 : nil)
                    .opacity(task.isCompleted ? DS.Opacity.completedMemo : 1)
            }
        }
    }
}
