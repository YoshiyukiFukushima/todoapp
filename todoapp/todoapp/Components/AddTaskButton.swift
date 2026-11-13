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

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(DS.Typography.iconLarge)
                .foregroundStyle(accent.onFill)
                .frame(width: DS.Size.fab, height: DS.Size.fab)
                .background(accent.fill, in: Circle())
                .dsShadow(.floating)
        }
        .padding(DS.Spacing.l)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : DS.Opacity.disabled)
    }
}
