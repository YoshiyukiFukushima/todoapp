//
//  EmptyTasksView.swift
//  todoapp
//
//  表示するタスクがないときの案内（ボタンは置かず、＋ボタンを案内する）。
//

import SwiftUI

struct EmptyTasksView: View {
    let filter: TaskFilter
    let addButtonPosition: AddButtonPosition

    @Environment(\.dsAccent) private var accent

    private var title: String {
        switch filter {
        case .day: "今日のタスクはありません"
        case .week: "今週のタスクはありません"
        case .month: "今月のタスクはありません"
        case .all: "期限なし・期限切れのタスクはありません"
        case .history: "履歴はまだありません"
        }
    }

    private var message: String {
        filter == .history
            ? "完了してから8日たったタスクがここに並びます。"
            : "\(addButtonPosition.displayName)の＋から追加できます。"
    }

    var body: some View {
        VStack(spacing: DS.Spacing.m) {
            Image(systemName: filter == .history ? "clock.arrow.circlepath" : "checkmark.circle")
                .font(DS.Typography.iconLarge)
                .foregroundStyle(accent.text)
                .frame(width: DS.Size.fab, height: DS.Size.fab)
                .background(accent.soft, in: Circle())
            Text(title)
                .font(DS.Typography.sectionTitle)
                .foregroundStyle(DS.Colors.textPrimary)
            Text(message)
                .font(DS.Typography.meta)
                .foregroundStyle(DS.Colors.textSecondary)
        }
        .multilineTextAlignment(.center)
        .padding(DS.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}
