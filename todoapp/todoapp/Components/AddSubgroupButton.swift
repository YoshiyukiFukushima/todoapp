//
//  AddSubgroupButton.swift
//  todoapp
//
//  一覧のいちばん下に置く、目立たない「＋ サブグループを追加」ボタン。
//

import SwiftUI

struct AddSubgroupButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("サブグループを追加", systemImage: "plus")
                .font(DS.Typography.meta)
                .foregroundStyle(DS.Colors.textSecondary)
                .frame(maxWidth: .infinity, minHeight: DS.Size.minTapTarget)
                .background {
                    RoundedRectangle(cornerRadius: DS.Radius.l)
                        .strokeBorder(DS.Colors.textTertiary.opacity(DS.Opacity.dashedBorder),
                                      style: StrokeStyle(lineWidth: DS.Stroke.regular, dash: DS.Stroke.dash))
                }
                .contentShape(RoundedRectangle(cornerRadius: DS.Radius.l))
        }
        .buttonStyle(.plain)
    }
}
