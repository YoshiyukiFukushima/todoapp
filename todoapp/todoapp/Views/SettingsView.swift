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

/// テーマを選ぶ丸（差し色 8 色・モノクロ・泡）
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

/// テーマの見本。モノクロは白と黒の半分ずつ、泡は水の中のシャボン玉、花・結晶は咲いた形、水滴は水玉
private struct ThemeSwatch: View {
    let theme: ColorTheme
    let isSelected: Bool

    var body: some View {
        ZStack {
            face
            if isSelected {
                Image(systemName: "checkmark")
                    .font(DS.Typography.iconSmall)
                    .foregroundStyle(checkColor)
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

    @ViewBuilder
    private var face: some View {
        switch theme.style {
        case .bubble:
            ZStack {
                Circle().fill(LinearGradient(colors: [DS.Bubble.glowBlue, DS.Bubble.deepTop, DS.Bubble.glowViolet],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                BubbleSphere(isFilled: false)
                    .frame(width: DS.Size.groupIcon * 0.42, height: DS.Size.groupIcon * 0.42)
                    .offset(x: -DS.Size.groupIcon * 0.1, y: DS.Size.groupIcon * 0.08)
                BubbleSphere(isFilled: false)
                    .frame(width: DS.Size.groupIcon * 0.22, height: DS.Size.groupIcon * 0.22)
                    .offset(x: DS.Size.groupIcon * 0.2, y: -DS.Size.groupIcon * 0.18)
            }
            .clipShape(Circle())
        case .flower(let kind):
            let spec = kind.spec
            ZStack {
                Circle().fill(LinearGradient(colors: [spec.glows[0], spec.deepTop, spec.glows[2]],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                FlowerBlossom(kind: kind, progress: 1)
                    .frame(width: DS.Size.groupIcon * 0.4, height: DS.Size.groupIcon * 0.4)
            }
            .clipShape(Circle())
        case .water:
            ZStack {
                Circle().fill(LinearGradient(colors: [DS.Water.glows[0], DS.Water.deepTop, DS.Water.glows[2]],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                WaterBead(showsCheck: false)
                    .frame(width: DS.Size.groupIcon * 0.46, height: DS.Size.groupIcon * 0.46)
                    .offset(x: -DS.Size.groupIcon * 0.06, y: DS.Size.groupIcon * 0.06)
                WaterBead(showsCheck: false)
                    .frame(width: DS.Size.groupIcon * 0.2, height: DS.Size.groupIcon * 0.2)
                    .offset(x: DS.Size.groupIcon * 0.2, y: -DS.Size.groupIcon * 0.18)
            }
            .clipShape(Circle())
        case .stamp:
            ZStack {
                WashiSurface(shape: Circle())
                StampMark(tilt: -8)
                    .frame(width: DS.Size.groupIcon * 0.62, height: DS.Size.groupIcon * 0.62)
            }
        case .candle:
            ZStack {
                Circle().fill(RadialGradient(colors: [DS.Candle.cardLight, DS.Candle.roomTop],
                                             center: .center, startRadius: 0, endRadius: DS.Size.groupIcon * 0.55))
                CandleFace(lit: 1, isAnimated: false)
                    .frame(width: DS.Size.groupIcon * 0.5, height: DS.Size.groupIcon * 0.5)
                    .offset(y: DS.Size.groupIcon * 0.08)
            }
            .clipShape(Circle())
        case .constellation:
            ZStack {
                Circle().fill(LinearGradient(colors: [DS.Star.skyGlow, DS.Star.skyTop, DS.Star.skyBottom],
                                             startPoint: .topTrailing, endPoint: .bottomLeading))
                StarFace(isLit: true)
                    .frame(width: DS.Size.groupIcon * 0.42, height: DS.Size.groupIcon * 0.42)
                Circle().fill(Color.white.opacity(0.8)).frame(width: 2, height: 2)
                    .offset(x: -DS.Size.groupIcon * 0.24, y: -DS.Size.groupIcon * 0.18)
                Circle().fill(Color.white.opacity(0.6)).frame(width: 1.5, height: 1.5)
                    .offset(x: DS.Size.groupIcon * 0.22, y: DS.Size.groupIcon * 0.2)
            }
            .clipShape(Circle())
        case .standard:
            if theme.isMonochrome {
                ZStack {
                    Circle().fill(DS.Colors.monoSwatchLight)
                    Circle()
                        .trim(from: 0, to: 0.5)
                        .fill(DS.Colors.monoSwatchDark)
                        .rotationEffect(.degrees(-45))
                    Circle().strokeBorder(DS.Colors.separator, lineWidth: DS.Stroke.hairline * 2)
                }
            } else {
                Circle().fill(theme.accent.fill)
            }
        }
    }

    private var checkColor: Color {
        if theme.isMonochrome { return DS.Colors.monoSwatchLight }
        switch theme.style {
        case .standard: return theme.accent.onFill
        case .stamp: return DS.Stamp.vermilion
        default: return DS.Bubble.rim
        }
    }
}
