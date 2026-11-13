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
                DSFormSection("テーマ") {
                    ThemePicker(selection: $themeManager.selectedTheme)
                        .padding(.vertical, DS.Spacing.s)
                }

                DSFormSection("＋ボタンの位置") {
                    Picker("＋ボタンの位置", selection: $themeManager.addButtonPosition) {
                        ForEach(AddButtonPosition.allCases) { position in
                            Text(position.displayName).tag(position)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                DSFormSection("表示") {
                    Toggle("「未完了」の見出しを出す", isOn: $themeManager.isStickyHeaderEnabled)
                    Toggle("履歴を開いた状態で表示", isOn: $themeManager.isCompletedSectionExpanded)
                }

                DSFormSection("動き") {
                    Toggle("完了したときのアニメーション", isOn: $themeManager.animationsEnabled)
                    Toggle("完了したときにゆっくり薄くする", isOn: $themeManager.fadeOutOnComplete)
                }
            }
            .dsFormBackground()
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
        }
        // テーマを変えたら、この画面にもすぐ反映する
        .dsRoot(theme: themeManager.selectedTheme)
    }
}

/// テーマを選ぶ色の丸（9 種類）
private struct ThemePicker: View {
    @Binding var selection: ColorTheme

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let columns = Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.s), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: DS.Spacing.m) {
            ForEach(ColorTheme.allCases) { theme in
                let isSelected = selection == theme
                Button {
                    withAnimation(DS.Motion.respecting(reduceMotion)) { selection = theme }
                } label: {
                    VStack(spacing: DS.Spacing.xs) {
                        ThemeSwatch(theme: theme, isSelected: isSelected)
                        Text(theme.displayName)
                            .font(DS.Typography.caption)
                            .foregroundStyle(isSelected ? DS.Colors.textPrimary : DS.Colors.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(theme.displayName)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
    }
}

/// テーマの色見本。モノクロは白と黒の半分ずつ
private struct ThemeSwatch: View {
    let theme: ColorTheme
    let isSelected: Bool

    var body: some View {
        ZStack {
            if theme.isMonochrome {
                Circle().fill(DS.Colors.monoSwatchLight)
                Circle()
                    .trim(from: 0, to: 0.5)
                    .fill(DS.Colors.monoSwatchDark)
                    .rotationEffect(.degrees(-45))
                Circle().strokeBorder(DS.Colors.separator, lineWidth: DS.Stroke.hairline * 2)
            } else {
                Circle().fill(theme.accent.fill)
            }
            if isSelected {
                Image(systemName: "checkmark")
                    .font(DS.Typography.iconSmall)
                    .foregroundStyle(theme.isMonochrome ? DS.Colors.monoSwatchLight : theme.accent.onFill)
                    .padding(DS.Spacing.xs)
                    .background(theme.isMonochrome ? DS.Colors.monoSwatchDark : .clear, in: Circle())
            }
        }
        .frame(width: DS.Size.groupIcon, height: DS.Size.groupIcon)
        .padding(DS.Spacing.xxs)
        .overlay {
            Circle()
                .strokeBorder(isSelected ? DS.Colors.textPrimary : .clear, lineWidth: DS.Stroke.regular)
        }
    }
}
