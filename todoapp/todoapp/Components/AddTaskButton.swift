//
//  AddTaskButton.swift
//  todoapp
//
//  メイン画面のタスク追加の入口（浮いた＋ボタン）。
//

import SwiftUI

struct AddTaskButton: View {
    let isEnabled: Bool
    let action: () -> Void

    @Environment(\.dsAccent) private var accent
    @Environment(\.dsStyle) private var style

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(DS.Typography.iconLarge)
                .foregroundStyle(accent.onFill)
                .frame(width: DS.Size.fab, height: DS.Size.fab)
                .background { face }
        }
        .padding(DS.Spacing.l)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : DS.Opacity.disabled)
        .accessibilityLabel("タスクを追加")
    }

    @ViewBuilder
    private var face: some View {
        switch style {
        case .standard:
            Circle().fill(accent.fill).dsShadow(.floating)
        case .bubble, .flower, .water:
            BubbleSphere(isFilled: true, tint: style.glassTint ?? .bubble).dsShadow(.floating)
        }
    }
}
