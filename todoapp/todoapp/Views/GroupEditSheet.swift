//
//  GroupEditSheet.swift
//  todoapp
//

import SwiftUI

struct GroupEditSheet: View {
    let group: TodoGroup?
    let groupViewModel: GroupViewModel
    var nextOrder: Int = 0

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var icon: String = "📌"
    @State private var color: Color = AppTheme.lavender.color

    var body: some View {
        NavigationStack {
            Form {
                DSFormSection("グループ名") {
                    TextField("グループ名", text: $name)
                }

                DSFormSection("アイコン") {
                    GroupIconPicker(selection: $icon)
                }

                DSFormSection("カラー") {
                    ColorPicker("カラー選択", selection: $color)
                }
            }
            .dsFormBackground()
            .navigationTitle(group == nil ? "新規グループ" : "グループ編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear {
            if let group {
                name = group.name
                icon = group.icon
                color = Color(hex: group.colorHex)
            }
        }
    }

    private func save() {
        let hex = color.toHex()
        if let group {
            groupViewModel.updateGroup(group, name: name, icon: icon, colorHex: hex)
        } else {
            groupViewModel.addGroup(name: name, icon: icon, colorHex: hex, order: nextOrder)
        }
        dismiss()
    }
}

/// グループのアイコンを選ぶグリッド（フェーズ4で SF Symbols に置き換える）
private struct GroupIconPicker: View {
    @Binding var selection: String

    @Environment(\.dsAccent) private var accent

    private let options = ["🏠", "📝", "🛒", "🏋️", "💼", "📚", "🍽️", "🎯", "💰", "🧹", "🚗", "🎨"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 6)

    var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(options, id: \.self) { option in
                Text(option)
                    .font(DS.Typography.iconLarge)
                    .padding(DS.Spacing.s)
                    .background(selection == option ? accent.soft : .clear, in: RoundedRectangle(cornerRadius: DS.Radius.s))
                    .onTapGesture { selection = option }
            }
        }
    }
}
