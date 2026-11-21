//
//  ThemeStyle.swift
//  todoapp
//
//  テーマの「描き方」。画面の部品は、色だけでなく形や動きもテーマに合わせて変えるとき、ここを通す。
//  - DSScreenBackground: 画面のいちばん下の背景
//  - DSSurface: カード・丸いボタン・カプセルの面
//  - CheckMarkFace: タスクの完了チェックの見た目（CheckButton.swift）
//  - 完了したときの演出（BubbleEffects など）
//
//  新しい描き方を足すときは case を足し、下の switch に描き方を足す（足し忘れはコンパイルエラーで分かる）。
//

import SwiftUI

nonisolated enum ThemeStyle: Sendable, Equatable {
    /// ふつうの平らなカード
    case standard
    /// シャボン玉（ガラスのカード、泡のチェック、昇る泡）
    case bubble
    /// 花（すりガラスのカード、咲くチェック、舞い落ちる花びら）。花の種類で色・形・速さが変わる
    case flower(FlowerKind)
    /// 水滴（青いガラスのカード、しずくが落ちて水玉になり、カードに水がたまる）
    case water
}

extension ThemeStyle {
    /// タスクカードの角の丸さ
    var cardRadius: CGFloat {
        switch self {
        case .standard: DS.Radius.l
        case .bubble, .flower, .water: DS.Radius.bubbleCard
        }
    }

    /// チェックの丸の大きさ
    var checkboxSize: CGFloat {
        switch self {
        case .standard: DS.Size.checkbox
        case .bubble: DS.Size.bubbleCheckbox
        case .flower: DS.Size.flowerCheckbox
        case .water: DS.Size.bubbleCheckbox
        }
    }

    /// 完了したときに、画面全体に重ねる演出を使うか
    var hasCompletionEffects: Bool { self != .standard }

    /// ガラスの面の色（平らなカードなら nil）
    var glassTint: GlassTint? {
        switch self {
        case .standard: nil
        case .bubble: .bubble
        case .flower(let kind): kind.spec.glass
        case .water: DS.Water.glass
        }
    }
}

// MARK: - 画面の背景

struct DSScreenBackground: View {
    @Environment(\.dsStyle) private var style
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        switch style {
        case .standard:
            DS.Colors.background
        case .bubble:
            BubbleBackdrop(isAnimated: themeManager.animationsEnabled && !reduceMotion)
        case .flower(let kind):
            FlowerBackdrop(kind: kind, isAnimated: themeManager.animationsEnabled && !reduceMotion)
        case .water:
            WaterBackdrop(isAnimated: themeManager.animationsEnabled && !reduceMotion)
        }
    }
}

// MARK: - 面（カード・丸・カプセル）

enum DSSurfaceShape {
    /// タスクカード（角丸の四角。角の丸さはテーマで決まる）
    case card
    case circle
    case capsule
}

struct DSSurface: View {
    var shape: DSSurfaceShape = .card
    var elevation: DS.Elevation = .card

    @Environment(\.dsStyle) private var style

    var body: some View {
        switch shape {
        case .card:
            render(RoundedRectangle(cornerRadius: style.cardRadius, style: .continuous))
        case .circle:
            render(Circle())
        case .capsule:
            render(Capsule())
        }
    }

    @ViewBuilder
    private func render<S: InsettableShape>(_ path: S) -> some View {
        switch style {
        case .standard:
            path.fill(DS.Colors.surface).dsShadow(elevation)
        case .bubble, .flower, .water:
            BubbleGlass(shape: path, tint: style.glassTint ?? .bubble,
                        highlight: shape == .circle ? .spot : .bar, isDimmed: elevation == .none)
        }
    }
}

extension View {
    /// テーマに合わせたカードの面を後ろに敷く
    func dsSurface(_ shape: DSSurfaceShape = .card, elevation: DS.Elevation = .card) -> some View {
        background { DSSurface(shape: shape, elevation: elevation) }
    }
}
