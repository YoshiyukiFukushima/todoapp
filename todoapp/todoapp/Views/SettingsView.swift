//
//  SettingsView.swift
//  todoapp
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                DSFormSection("テーマ選択") {
                    ForEach(AppTheme.allCases) { theme in
                        ThemeRow(theme: theme, isSelected: themeManager.selectedTheme == theme) {
                            themeManager.selectedTheme = theme
                        }
                    }
                }

                DSFormSection("＋ボタンの位置") {
                    Picker("＋ボタンの位置", selection: $themeManager.addButtonPosition) {
                        ForEach(AddButtonPosition.allCases) { position in
                            Text(position.displayName).tag(position)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                DSFormSection("完了済みセクション表示") {
                    Toggle("デフォルトで展開", isOn: $themeManager.isCompletedSectionExpanded)
                }

                DSFormSection("アニメーション") {
                    Toggle("完了アニメーション", isOn: $themeManager.animationsEnabled)
                    Toggle("完了時のエモジエフェクト", isOn: $themeManager.emojiEffectEnabled)
                        .disabled(!themeManager.animationsEnabled)
                    Toggle("完了後にフェードアウト", isOn: $themeManager.fadeOutOnComplete)
                }

                DSFormSection("その他") {
                    Toggle("Sticky Header（未完了を常時表示）", isOn: $themeManager.isStickyHeaderEnabled)
                }
            }
            .dsFormBackground()
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}

/// テーマ 1 行（色見本・名前・選択中の印）
private struct ThemeRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Circle()
                    .fill(theme.accent.fill)
                    .frame(width: DS.Size.checkbox, height: DS.Size.checkbox)
                Text(theme.displayName)
                    .foregroundStyle(DS.Colors.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(DS.Typography.icon)
                        .foregroundStyle(theme.accent.fill)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
