//
//  SectionHeaders.swift
//  todoapp
//
//  タスク一覧のセクション見出し。
//

import SwiftUI

/// 「未完了 (n)」
struct IncompleteSectionHeader: View {
    let count: Int

    var body: some View {
        Text("未完了 (\(count))")
            .font(DS.Typography.sectionTitle)
            .foregroundStyle(DS.Colors.textSecondary)
    }
}

/// 「完了済み - 今日 (n)」。タップで開閉する
struct CompletedSectionHeader: View {
    let label: String
    let count: Int
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: DS.Spacing.s) {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(DS.Typography.iconSmall)
            Text("完了済み - \(label) (\(count))")
                .font(DS.Typography.meta)
            Spacer()
        }
        .foregroundStyle(DS.Colors.textSecondary)
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
    }
}
