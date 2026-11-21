//
//  CandleViews.swift
//  todoapp
//
//  ろうそくのテーマ：ゆらめく火のろうそく（チェック）、火に照らされたカード、暗い部屋の背景。
//  まだ終わっていないタスクは火にゆらゆら照らされ、チェックすると火が横に吹かれて消える。
//

import SwiftUI

extension DS {
    enum Candle {
        // MARK: 部屋
        static let roomTop = Color(fixed: 0x16141A)
        static let roomBottom = Color(fixed: 0x08070A)
        /// 部屋の奥に残る、ほのかな暖かい光
        static let roomGlow = Color(fixed: 0x5A3E22)

        // MARK: カード（火の消えた暗いガラス）
        static let glass = GlassTint(
            glassTop: Color(fixed: 0x2C2A31).opacity(0.92), glassBottom: Color(fixed: 0x1A191E).opacity(0.92),
            sphereTint: Color(fixed: 0xE9D2B0), sphereEdge: Color(fixed: 0x3A3036),
            filledLight: Color(fixed: 0xFFE2B0), filledMid: Color(fixed: 0xD9934A), filledDeep: Color(fixed: 0x8A4E1E)
        )
        /// 火に照らされたカードの光（左の火から右へ弱まる）
        static let cardLight = Color(fixed: 0xB08452)
        static let cardLightFar = Color(fixed: 0x5A4330)

        // MARK: ろうそくと火
        static let waxLight = Color(fixed: 0xFBF7EE)
        static let waxShade = Color(fixed: 0xD8D0C2)
        static let waxOutLight = Color(fixed: 0x8E8B86)
        static let waxOutShade = Color(fixed: 0x5C5A57)
        static let wick = Color(fixed: 0x2A221C)
        static let flameCore = Color(fixed: 0xFFFBEA)
        static let flameMid = Color(fixed: 0xFFC766)
        static let flameEdge = Color(fixed: 0xE8792B)
        static let flameBlue = Color(fixed: 0x8FB6FF)
        static let ember = Color(fixed: 0xFF5A2A)
        static let smoke = Color(fixed: 0xBDB6AD)

        // MARK: 動き
        /// 火が横に吹かれて消えるまで
        static let snuffDuration: TimeInterval = 0.3
        /// 火をつけ直す時間（チェックを外したとき）
        static let relightDuration: TimeInterval = 0.45
        /// カードが暗くなる／明るくなる時間
        static let dimDuration: TimeInterval = 0.6
    }
}

/// 火のゆらめき（いくつかの波を重ねて、規則的に見えないようにする）
enum CandleFlicker {
    /// 明るさ（1 前後）
    static func brightness(_ t: TimeInterval, phase: Double) -> Double {
        1 + 0.07 * sin(t * 13 + phase) + 0.05 * sin(t * 23.7 + phase * 2) + 0.03 * sin(t * 5.3 + phase * 3)
    }

    /// 火の傾き（度）
    static func sway(_ t: TimeInterval, phase: Double) -> Double {
        3 * sin(t * 4.7 + phase) + 2 * sin(t * 11.3 + phase * 1.7)
    }
}

// MARK: - ろうそく（チェック）

/// lit 1 で火がついたろうそく、0 で消えたろうそく。1→0 に動かすと、火が横に吹かれて消える
struct CandleFace: View, Animatable {
    /// ろうそく全体を下げる量（大きさに対する割合）。煙の出る位置もこれに合わせる
    static let drop: CGFloat = 0.34

    var lit: Double
    /// ゆらめかせるか
    var isAnimated: Bool
    /// ろうそくごとにゆらめきをずらす
    var phase: Double = 0

    nonisolated var animatableData: Double {
        get { lit }
        set { lit = newValue }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !isAnimated || lit < 0.01)) { timeline in
            let t = isAnimated ? timeline.date.timeIntervalSinceReferenceDate : 0
            GeometryReader { proxy in
                let size = min(proxy.size.width, proxy.size.height)
                // 火の分だけ上が重く見えるので、ろうそく全体を下げて、カードの中で上下の釣り合いを取る
                candle(size: size, time: t)
                    .frame(width: size, height: size)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2 + size * CandleFace.drop)
            }
        }
        .accessibilityHidden(true)
    }

    private func candle(size: CGFloat, time: TimeInterval) -> some View {
        let waxWidth = size * 0.42
        let waxHeight = size * 0.62
        return ZStack {
            // 消えたろうそく（灰色）
            wax(light: DS.Candle.waxOutLight, shade: DS.Candle.waxOutShade, width: waxWidth, height: waxHeight)
                .offset(y: size * 0.19)
            // 火のついたろうそく（白）。火が消えるにつれて灰色へ
            wax(light: DS.Candle.waxLight, shade: DS.Candle.waxShade, width: waxWidth, height: waxHeight)
                .offset(y: size * 0.19)
                .opacity(lit)
            // 芯
            Capsule()
                .fill(DS.Candle.wick)
                .frame(width: max(1.4, size * 0.06), height: size * 0.14)
                // 根もとをろうの中まで入れて、ろうとのすき間をなくす
                .offset(y: -size * 0.12)
            // 火の根もとを芯の先に合わせる
            flame(size: size, time: time)
                .offset(y: -size * 0.39)
        }
    }

    private func wax(light: Color, shade: Color, width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: width * 0.18, style: .continuous)
            .fill(LinearGradient(colors: [light, shade], startPoint: .leading, endPoint: .trailing))
            .overlay(alignment: .top) {
                // ろうの上の、溶けてくぼんだところ
                Ellipse()
                    .fill(shade.opacity(0.6))
                    .frame(width: width * 0.8, height: width * 0.22)
                    .offset(y: width * 0.04)
            }
            .frame(width: width, height: height)
    }

    /// 火：外は橙、中は白、根もとに少し青。消えるときは横に倒れながら細くなる
    private func flame(size: CGFloat, time: TimeInterval) -> some View {
        let brightness = CandleFlicker.brightness(time, phase: phase)
        let sway = CandleFlicker.sway(time, phase: phase)
        let blown = 1 - lit
        let width = size * 0.32
        let height = size * 0.66 * brightness
        return ZStack {
            // 火のまわりの光
            Circle()
                .fill(RadialGradient(colors: [DS.Candle.flameMid.opacity(0.45), .clear],
                                     center: .center, startRadius: 0, endRadius: size * 0.5))
                .frame(width: size, height: size)
                .opacity(lit * brightness)
            FlameShape()
                .fill(RadialGradient(colors: [DS.Candle.flameCore, DS.Candle.flameMid, DS.Candle.flameEdge.opacity(0.85)],
                                     center: UnitPoint(x: 0.5, y: 0.75), startRadius: 0, endRadius: height * 0.7))
                .frame(width: width, height: height)
                .overlay(alignment: .bottom) {
                    Ellipse()
                        .fill(DS.Candle.flameBlue.opacity(0.75))
                        .frame(width: width * 0.32, height: height * 0.2)
                        .offset(y: -height * 0.04)
                }
                .scaleEffect(x: 1 - blown * 0.5, y: 1 - blown * 0.4, anchor: .bottom)
                .rotationEffect(.degrees(sway * lit + blown * 70), anchor: .bottom)
                .offset(x: blown * size * 0.18)
                .opacity(lit)
        }
        .frame(width: size, height: size * 0.6, alignment: .bottom)
    }
}

/// 火の形：下が丸く、上がとがる
struct FlameShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.7),
                   control1: CGPoint(x: r.midX + r.width * 0.12, y: r.minY + r.height * 0.25),
                   control2: CGPoint(x: r.maxX, y: r.minY + r.height * 0.45))
        p.addArc(center: CGPoint(x: r.midX, y: r.minY + r.height * 0.7), radius: r.width / 2,
                 startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY),
                   control1: CGPoint(x: r.minX, y: r.minY + r.height * 0.45),
                   control2: CGPoint(x: r.midX - r.width * 0.12, y: r.minY + r.height * 0.25))
        p.closeSubpath()
        return p
    }
}

// MARK: - 火に照らされたカード

/// まだ終わっていないカードを、左のろうそくの火がゆらゆら照らす。終えると暗くなる
struct CandleCardLight: View {
    let isLit: Bool
    let isAnimated: Bool
    var phase: Double = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !isAnimated || !isLit)) { timeline in
            let brightness = isAnimated ? CandleFlicker.brightness(timeline.date.timeIntervalSinceReferenceDate, phase: phase) : 1
            GeometryReader { proxy in
                let size = proxy.size
                ZStack {
                    LinearGradient(colors: [DS.Candle.cardLight.opacity(0.75), DS.Candle.cardLightFar.opacity(0.45), .clear],
                                   startPoint: .leading, endPoint: .trailing)
                    RadialGradient(colors: [DS.Candle.flameMid.opacity(0.35), .clear],
                                   center: UnitPoint(x: 0.08, y: 0.4), startRadius: 0, endRadius: size.width * 0.45)
                }
                .opacity(min(1, 0.85 * brightness))
            }
        }
        .opacity(isLit ? 1 : 0)
        .animation(isAnimated ? .easeInOut(duration: DS.Candle.dimDuration) : nil, value: isLit)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - 暗い部屋の背景

struct CandleBackdrop: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(colors: [DS.Candle.roomTop, DS.Candle.roomBottom], startPoint: .top, endPoint: .bottom)
                Circle()
                    .fill(DS.Candle.roomGlow.opacity(0.35))
                    .frame(width: proxy.size.width * 1.1)
                    .blur(radius: proxy.size.width * 0.3)
                    .position(x: proxy.size.width * 0.1, y: proxy.size.height * 0.3)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
