//
//  SectionHeaders.swift
//  todoapp
//
//  タスク一覧のセクション見出し（未完了・サブグループ・完了済み）。
//

import SwiftUI

/// 見出しの右の件数
private struct CountPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(DS.Typography.counter)
            .foregroundStyle(DS.Colors.textSecondary)
            .padding(.horizontal, DS.Spacing.s)
            .padding(.vertical, DS.Spacing.xxs)
            .background(DS.Colors.surfaceSunken, in: Capsule())
    }
}

/// 「未完了 n」
struct IncompleteSectionHeader: View {
    let count: Int

    var body: some View {
        HStack(spacing: DS.Spacing.s) {
            Text("未完了")
                .font(DS.Typography.sectionTitle)
                .foregroundStyle(DS.Colors.textPrimary)
            CountPill(text: "\(count)")
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// 開閉できる見出し（サブグループ・完了済み）
struct CollapsibleSectionHeader: View {
    let title: String
    /// 右に出す件数（例：「3」「1/2」）
    let countText: String
    let isExpanded: Bool
    /// 完了済みは控えめな色にする
    var isMuted = false
    let onToggle: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: DS.Spacing.s) {
                Image(systemName: "chevron.right")
                    .font(DS.Typography.iconSmall)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .animation(DS.Motion.respecting(reduceMotion), value: isExpanded)
                Text(title)
                    .font(isMuted ? DS.Typography.meta : DS.Typography.sectionTitle)
                    .foregroundStyle(isMuted ? DS.Colors.textSecondary : DS.Colors.textPrimary)
                CountPill(text: countText)
                Spacer()
            }
            .frame(minHeight: DS.Size.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isHeader)
        .accessibilityValue(isExpanded ? "開いています" : "閉じています")
    }
}
