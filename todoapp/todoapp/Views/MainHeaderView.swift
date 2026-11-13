//
//  MainHeaderView.swift
//  todoapp
//
//  画面上部：進み具合の輪・グループ名・進み具合の文・設定ボタン。
//

import SwiftUI

struct MainHeaderView: View {
    let groupName: String
    let filter: TaskFilter
    let tasks: [TodoTask]
    let onSettings: () -> Void

    private var subtitle: String {
        let query = TaskQuery()
        if filter == .history {
            return "\(filter.scopeLabel)に完了 \(query.historyCount(in: tasks))件"
        }
        guard let progress = query.progress(in: tasks, for: filter), progress.total > 0 else {
            return "\(filter.scopeLabel) 0件"
        }
        if progress.done == progress.total {
            return "\(filter.scopeLabel)の\(progress.total)件すべて完了"
        }
        return "\(filter.scopeLabel) \(progress.total)件中\(progress.done)件完了"
    }

    var body: some View {
        let progress = TaskQuery().progress(in: tasks, for: filter)
        HStack(spacing: DS.Spacing.m) {
            if let progress, progress.total > 0 {
                ProgressRing(done: progress.done, total: progress.total)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text(groupName)
                    .font(DS.Typography.screenTitle)
                    .foregroundStyle(DS.Colors.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(DS.Typography.meta)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .contentTransition(.numericText())
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)

            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(DS.Typography.icon)
                    .foregroundStyle(DS.Colors.textPrimary)
                    .frame(width: DS.Size.minTapTarget, height: DS.Size.minTapTarget)
                    .background(DS.Colors.surface, in: Circle())
                    .dsShadow(.card)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("設定")
        }
    }
}
