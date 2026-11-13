//
//  GroupAvatar.swift
//  todoapp
//
//  グループの丸いアイコン（SF Symbol または名前の 1 文字目）と未完了バッジ。
//

import SwiftUI

struct GroupAvatar: View {
    let group: TodoGroup
    let isSelected: Bool

    @Environment(\.dsMonochrome) private var isMonochrome

    var body: some View {
        // モノクロではグループも墨色（形と名前で見分ける）
        let accent = isMonochrome ? DS.Accent.ink : group.accent
        ZStack {
            Circle()
                .fill(isSelected ? accent.fill : accent.soft)
            glyph
                .foregroundStyle(isSelected ? accent.onFill : accent.text)
        }
        .frame(width: DS.Size.groupIcon, height: DS.Size.groupIcon)
        // 選択中は色だけでなく外側の輪でも示す
        .padding(DS.Spacing.xs)
        .overlay {
            Circle()
                .strokeBorder(isSelected ? accent.fill : .clear, lineWidth: DS.Stroke.regular)
        }
    }

    @ViewBuilder
    private var glyph: some View {
        switch group.glyph {
        case .symbol(let name):
            Image(systemName: name)
                .font(DS.Typography.icon)
        case .letter(let letter):
            Text(letter)
                .font(DS.Typography.sectionTitle)
        }
    }
}

/// 閉じたサイドバーで、アイコンの右上に出す未完了件数（0 件なら出さない）
struct CountBadge: View {
    let count: Int

    @Environment(\.dsAccent) private var accent

    var body: some View {
        if count > 0 {
            Text("\(count)")
                .font(DS.Typography.counter)
                .foregroundStyle(accent.onFill)
                .padding(.horizontal, DS.Spacing.xs + DS.Spacing.xxs)
                .padding(.vertical, DS.Spacing.xxs)
                .background(accent.fill, in: Capsule())
                .overlay(Capsule().strokeBorder(DS.Colors.surfaceSunken, lineWidth: DS.Stroke.regular))
        }
    }
}
