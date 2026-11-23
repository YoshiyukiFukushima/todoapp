//
//  NightBackdrop.swift
//  todoapp
//
//  花火・風船・ゼリー・紙飛行機・ししおどし・ちょうちょ・惑星・雪だるま・くもり晴れのテーマで共通の部品。
//  - ThemeSeed: タスクごとに決まった「でたらめ」（花火・風船の色など）。描き直しても変わらない
//  - NightBackdrop: グラデーションと、ぼんやり光る 3 色、テーマごとの小さな飾り（星・光の粒・雪・雲）。
//    名前は夜だが、雪だるま・くもり晴れの明るい空もこれで描く
//

import SwiftUI

// MARK: - タスクごとに決まったでたらめ

/// 同じ種からは、いつも同じ並びの数を返す
nonisolated struct ThemeSeed: Sendable {
    private var state: UInt64

    init(_ value: UInt64) { state = value == 0 ? 0x9E37_79B9_7F4A_7C15 : value }

    /// タスクの ID から種を作る。String.hashValue は起動のたびに変わるので使わない
    init(id: UUID) {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        withUnsafeBytes(of: id.uuid) { bytes in
            for byte in bytes {
                hash = (hash ^ UInt64(byte)) &* 0x0000_0100_0000_01B3
            }
        }
        self.init(hash)
    }

    /// 0〜1
    mutating func next() -> Double {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Double(state >> 33) / Double(1 << 31)
    }

    mutating func next(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + (range.upperBound - range.lowerBound) * next()
    }
}

// MARK: - 背景

struct NightBackdrop: View {
    let style: ThemeStyle
    var isAnimated: Bool

    private struct Look {
        let top: Color
        let bottom: Color
        /// 左上・右・左下でぼんやり光る色と、その強さ
        let glows: [(Color, Double)]
    }

    private var look: Look {
        switch style {
        case .planet:
            Look(top: DS.Planet.deepTop, bottom: DS.Planet.deepBottom, glows: DS.Planet.glows)
        case .snowman:
            Look(top: DS.Snowman.deepTop, bottom: DS.Snowman.deepBottom, glows: DS.Snowman.glows)
        case .weather:
            Look(top: DS.Weather.deepTop, bottom: DS.Weather.deepBottom, glows: DS.Weather.glows)
        case .balloon:
            Look(top: DS.Balloon.deepTop, bottom: DS.Balloon.deepBottom, glows: DS.Balloon.glows)
        case .jelly:
            Look(top: DS.Jelly.deepTop, bottom: DS.Jelly.deepBottom, glows: DS.Jelly.glows)
        case .paperPlane:
            Look(top: DS.PaperPlane.deepTop, bottom: DS.PaperPlane.deepBottom, glows: DS.PaperPlane.glows)
        case .shishiOdoshi:
            Look(top: DS.Shishi.deepTop, bottom: DS.Shishi.deepBottom, glows: DS.Shishi.glows)
        case .butterfly:
            Look(top: DS.Butterfly.deepTop, bottom: DS.Butterfly.deepBottom, glows: DS.Butterfly.glows)
        default:
            Look(top: DS.Fireworks.deepTop, bottom: DS.Fireworks.deepBottom, glows: DS.Fireworks.glows)
        }
    }

    var body: some View {
        let look = look
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                LinearGradient(colors: [look.top, look.bottom], startPoint: .top, endPoint: .bottom)
                glow(look.glows[0], diameter: size.width * 0.95, at: CGPoint(x: size.width * 0.02, y: size.height * 0.1))
                glow(look.glows[1], diameter: size.width * 0.8, at: CGPoint(x: size.width * 1.0, y: size.height * 0.52))
                glow(look.glows[2], diameter: size.width * 0.8, at: CGPoint(x: size.width * 0.15, y: size.height * 0.97))

                if isAnimated {
                    TimelineView(.animation(minimumInterval: 1 / 20)) { timeline in
                        ambient(time: timeline.date.timeIntervalSinceReferenceDate)
                    }
                } else {
                    ambient(time: 0)
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func glow(_ glow: (Color, Double), diameter: CGFloat, at point: CGPoint) -> some View {
        Circle()
            .fill(glow.0.opacity(glow.1))
            .frame(width: diameter, height: diameter)
            .blur(radius: diameter * 0.28)
            .position(point)
    }

    @ViewBuilder
    private func ambient(time: TimeInterval) -> some View {
        switch style {
        case .balloon: BalloonSky(time: time)
        case .jelly: JellySoda(time: time)
        case .paperPlane: PaperClouds(time: time)
        case .shishiOdoshi: ShishiRipples(time: time)
        case .butterfly: ButterflyPollen(time: time)
        case .planet: PlanetStars(time: time)
        case .snowman: SnowmanFlakes(time: time)
        case .weather: WeatherClouds(time: time)
        default: FireworksSky(time: time)
        }
    }
}

/// 背景の飾りの置き場所（毎回同じ並びにする）
struct AmbientDot {
    let x: Double
    let y: Double
    let size: Double
    let speed: Double
    let phase: Double

    static func make(count: Int, seed: UInt64) -> [AmbientDot] {
        var random = ThemeSeed(seed)
        return (0..<count).map { _ in
            AmbientDot(x: random.next(), y: random.next(), size: random.next(),
                       speed: random.next(in: 0.5...1.5), phase: random.next() * .pi * 2)
        }
    }
}

// MARK: - 動きの計算（どのテーマの部品からも使う）

nonisolated enum Ease {
    static func clamp(_ x: Double) -> Double { min(max(x, 0), 1) }

    /// a から b にかけて、なめらかに 0→1
    static func smoothstep(_ a: Double, _ b: Double, _ x: Double) -> Double {
        let t = clamp((x - a) / (b - a))
        return t * t * (3 - 2 * t)
    }

    /// 少し行きすぎてから戻る
    static func outBack(_ x: Double, overshoot: Double = 1.7) -> Double {
        let t = clamp(x)
        let c3 = overshoot + 1
        let u = t - 1
        return 1 + c3 * u * u * u + overshoot * u * u
    }

    /// だんだん速く
    static func inCubic(_ x: Double) -> Double {
        let t = clamp(x)
        return t * t * t
    }

    /// だんだんゆっくり
    static func outCubic(_ x: Double) -> Double {
        let u = 1 - clamp(x)
        return 1 - u * u * u
    }
}
