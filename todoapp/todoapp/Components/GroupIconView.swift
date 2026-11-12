//
//  GroupIconView.swift
//  todoapp
//

import SwiftUI

struct GroupIconView: View {
    let group: TodoGroup
    let isSelected: Bool

    @State private var showTooltip = false

    private var groupColor: Color { Color(hex: group.colorHex) }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                Circle()
                    .fill(groupColor.opacity(isSelected ? 1 : DS.Opacity.unselected))
                    .frame(width: DS.Size.groupIcon, height: DS.Size.groupIcon)
                    .overlay(
                        Circle().stroke(isSelected ? groupColor : .clear, lineWidth: DS.Stroke.regular)
                    )

                Text(group.icon)
                    .font(DS.Typography.icon)
            }

            CountBadge(count: group.incompleteTaskCount)
                .offset(DS.Layout.badgeOffset)
        }
        .overlay(alignment: .top) {
            if showTooltip {
                GroupNameTooltip(name: group.name)
                    .offset(y: DS.Layout.tooltipOffsetY)
                    .transition(.opacity)
            }
        }
        .onLongPressGesture(minimumDuration: 0.4) {
            withAnimation(DS.Motion.standard) { showTooltip = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(DS.Motion.standard) { showTooltip = false }
            }
        }
    }
}

/// グループアイコン右上の未完了件数
struct CountBadge: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(DS.Typography.counter)
            .foregroundStyle(DS.Colors.onDanger)
            .padding(DS.Spacing.xs)
            .background(Circle().fill(DS.Colors.danger))
    }
}

/// 長押しで出るグループ名の吹き出し
private struct GroupNameTooltip: View {
    let name: String

    var body: some View {
        Text(name)
            .font(DS.Typography.caption)
            .padding(.horizontal, DS.Spacing.s)
            .padding(.vertical, DS.Spacing.xs)
            .background(DS.Colors.surfaceElevated, in: RoundedRectangle(cornerRadius: DS.Radius.s))
            .dsShadow(.card)
    }
}
