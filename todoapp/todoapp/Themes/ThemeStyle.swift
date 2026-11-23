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
    /// 判子（和紙のカード、上から降りてくる判子、にじむ朱色）
    case stamp
    /// ろうそく（火に照らされたカード、吹き消される火、昇る煙）
    case candle
    /// 星座（夜のガラスのカード、灯る星、夜空の星座）
    case constellation
    /// 花火（夜空のカード、まっすぐ放射状に開く花火、全部終わると打ち上げ）
    case fireworks
    /// 風船（夕暮れの空、ふくらんでパンッと割れるチェック、紙吹雪と落ちるひも）
    case balloon
    /// ゼリー（ガラスの器、ぷるんと揺れて色に染まるチェック、少し揺れるカード）
    case jelly
    /// 紙飛行機（夜明け前の空、折りたたまれて飛んでいくチェック、点線の軌跡）
    case paperPlane
    /// ししおどし（月夜の庭、水がたまって石を打つチェック、「カコーン」）
    case shishiOdoshi
    /// ちょうちょ（夕暮れの野原、羽化するチェック、カードの右端にとまるちょうちょ）
    case butterfly
    /// 惑星（星雲の夜空、星くずが集まって生まれる輪のある惑星）
    case planet
    /// 雪だるま（初雪の朝、雪玉が転がって頭が乗り、マフラーを巻く。明るい）
    case snowman
    /// くもりのち晴れ（青空、雲が流れて太陽が出る、全部終えると虹。明るい）
    case weather
}

extension ThemeStyle {
    /// タスクカードの角の丸さ
    var cardRadius: CGFloat {
        switch self {
        case .standard: DS.Radius.l
        case .bubble, .flower, .water, .candle, .constellation, .fireworks,
             .balloon, .jelly, .paperPlane, .shishiOdoshi, .butterfly, .planet, .snowman, .weather: DS.Radius.bubbleCard
        case .stamp: DS.Radius.l
        }
    }

    /// チェックの丸の大きさ
    var checkboxSize: CGFloat {
        switch self {
        case .standard: DS.Size.checkbox
        case .bubble: DS.Size.bubbleCheckbox
        case .flower: DS.Size.flowerCheckbox
        case .water: DS.Size.bubbleCheckbox
        case .stamp: 34
        case .candle: 30
        case .constellation: 28
        case .fireworks: DS.Size.bubbleCheckbox
        case .balloon, .jelly, .paperPlane, .butterfly, .planet, .snowman, .weather: 32
        // 小さな庭を描くので少し大きめ
        case .shishiOdoshi: 38
        }
    }

    /// 完了したタスクでも、チェックを薄くしないか（チェックの絵が主役のテーマ）
    var keepsCheckBright: Bool {
        switch self {
        // 花は、咲いた花が薄暗くなると映えないので、薄くしない
        case .flower, .fireworks, .jelly, .shishiOdoshi, .butterfly, .planet, .snowman, .weather: true
        case .standard, .bubble, .water, .stamp, .candle, .constellation, .balloon, .paperPlane: false
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
        case .stamp: nil
        case .candle: DS.Candle.glass
        case .constellation: DS.Star.glass
        case .fireworks: DS.Fireworks.glass
        case .balloon: DS.Balloon.glass
        case .jelly: DS.Jelly.glass
        case .paperPlane: DS.PaperPlane.glass
        case .shishiOdoshi: DS.Shishi.glass
        case .butterfly: DS.Butterfly.glass
        case .planet: DS.Planet.glass
        case .snowman: DS.Snowman.glass
        case .weather: DS.Weather.glass
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
        case .stamp:
            WashiBackdrop()
        case .candle:
            CandleBackdrop()
        case .constellation:
            StarfieldBackdrop(isAnimated: themeManager.animationsEnabled && !reduceMotion)
        case .fireworks, .balloon, .jelly, .paperPlane, .shishiOdoshi, .butterfly, .planet, .snowman, .weather:
            NightBackdrop(style: style, isAnimated: themeManager.animationsEnabled && !reduceMotion)
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
        case .bubble, .flower, .water, .fireworks, .balloon, .jelly, .paperPlane, .shishiOdoshi, .butterfly,
             .planet, .snowman, .weather:
            BubbleGlass(shape: path, tint: style.glassTint ?? .bubble,
                        highlight: shape == .circle ? .spot : .bar, isDimmed: elevation == .none)
        case .candle, .constellation:
            // 夜の部屋・夜空では、ガラスの上の光の帯は出さない
            BubbleGlass(shape: path, tint: style.glassTint ?? .bubble,
                        highlight: shape == .circle ? .spot : .none, isDimmed: elevation == .none)
        case .stamp:
            WashiSurface(shape: path)
        }
    }
}

extension View {
    /// テーマに合わせたカードの面を後ろに敷く
    func dsSurface(_ shape: DSSurfaceShape = .card, elevation: DS.Elevation = .card) -> some View {
        background { DSSurface(shape: shape, elevation: elevation) }
    }
}
