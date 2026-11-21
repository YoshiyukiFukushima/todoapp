//
//  WaterViews.swift
//  todoapp
//
//  水滴のテーマの部品：水玉（完了のチェック）、カードにたまる水、しずく・波紋の描き方、深い水の背景。
//  水は透明なので、塗りはごく薄くして、ふちの光と映り込み、揺れで形を見せる。
//

import SwiftUI

// MARK: - 水玉（完了のチェック。ハイライトが 2 つある透明なレンズ）

struct WaterBead: View {
    var showsCheck = true

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                // 中はほとんど透明。ふちに向かって少しだけ青く、レンズの厚みを出す
                Circle().fill(RadialGradient(
                    colors: [DS.Water.tint.opacity(0.06), DS.Water.tint.opacity(0.14), DS.Water.deep.opacity(0.32)],
                    center: UnitPoint(x: 0.45, y: 0.4), startRadius: 0, endRadius: size * 0.55))
                // 下側に回り込んだ光（レンズの底の明るさ）
                Circle()
                    .trim(from: 0.08, to: 0.42)
                    .stroke(DS.Water.rim.opacity(0.45), style: StrokeStyle(lineWidth: max(1, size * 0.07), lineCap: .round))
                    .padding(size * 0.1)
                // ふちの光
                Circle().strokeBorder(
                    LinearGradient(colors: [DS.Water.rim.opacity(0.95), DS.Water.rim.opacity(0.35), DS.Water.rim.opacity(0.75)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: max(1, size * 0.05))
                // ハイライト 1：左上の大きな映り込み
                Circle()
                    .fill(RadialGradient(colors: [DS.Water.rim, DS.Water.rim.opacity(0)],
                                         center: .center, startRadius: 0, endRadius: size * 0.13))
                    .frame(width: size * 0.26, height: size * 0.26)
                    .offset(x: -size * 0.19, y: -size * 0.2)
                // ハイライト 2：右下の小さな映り込み
                Circle()
                    .fill(RadialGradient(colors: [DS.Water.rim.opacity(0.85), DS.Water.rim.opacity(0)],
                                         center: .center, startRadius: 0, endRadius: size * 0.09))
                    .frame(width: size * 0.18, height: size * 0.18)
                    .offset(x: size * 0.19, y: size * 0.22)
                if showsCheck {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                        .foregroundStyle(DS.Water.rim)
                        .shadow(color: DS.Water.deep.opacity(0.6), radius: 1.5)
                }
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }
}

// MARK: - カードにたまる水（下半分。水面が波打つ）

struct WaterPool: View {
    let isFilled: Bool
    /// 波を動かすか（オフなら止まった水面）
    let isAnimated: Bool
    /// 水がたまり始めるまで（しずくが落ちてくる時間）
    var fillDelay: TimeInterval = DS.Water.fallDuration

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !isAnimated || !isFilled)) { timeline in
            WaterSurface(level: isFilled ? 1 : 0,
                         time: isAnimated ? timeline.date.timeIntervalSinceReferenceDate : 0)
        }
        .animation(isAnimated ? fillAnimation : nil, value: isFilled)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var fillAnimation: Animation {
        isFilled
            ? .spring(duration: DS.Water.fillDuration, bounce: 0.25).delay(fillDelay)
            : .easeIn(duration: DS.Water.drainDuration)
    }
}

/// 水面（level 0 で空、1 でカードの高さの poolLevel まで）
private struct WaterSurface: View, Animatable {
    var level: Double
    let time: TimeInterval

    nonisolated var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    var body: some View {
        Canvas { context, size in
            guard level > 0.001 else { return }
            let surfaceY = size.height * (1 - DS.Water.poolLevel * level)
            // 水がたまりたては大きく揺れ、落ち着くと静かになる
            let amplitude = 2.2 + 1.5 * (1 - min(level, 1))
            let wave = wavePath(width: size.width, y: surfaceY, amplitude: amplitude)

            var body = wave
            body.addLine(to: CGPoint(x: size.width, y: size.height))
            body.addLine(to: CGPoint(x: 0, y: size.height))
            body.closeSubpath()
            context.fill(body, with: .linearGradient(
                Gradient(colors: [DS.Water.poolTop, DS.Water.poolBottom]),
                startPoint: CGPoint(x: 0, y: surfaceY), endPoint: CGPoint(x: 0, y: size.height)))
            // 水面のすぐ下の明るい帯（光が差しこむ）
            context.stroke(wavePath(width: size.width, y: surfaceY + 4, amplitude: amplitude * 0.8, phase: 0.6),
                           with: .color(DS.Water.rim.opacity(0.1)), lineWidth: 5)
            // 水面の光る線
            context.stroke(wave, with: .color(DS.Water.rim.opacity(0.6)), lineWidth: 1.2)
        }
    }

    private func wavePath(width: CGFloat, y: CGFloat, amplitude: CGFloat, phase: Double = 0) -> Path {
        var path = Path()
        let step: CGFloat = 4
        var x: CGFloat = 0
        path.move(to: CGPoint(x: 0, y: y + waveOffset(0, width: width, amplitude: amplitude, phase: phase)))
        while x < width {
            x = min(x + step, width)
            path.addLine(to: CGPoint(x: x, y: y + waveOffset(x, width: width, amplitude: amplitude, phase: phase)))
        }
        return path
    }

    /// 長い波と短い波を重ねて、自然な揺れにする
    private func waveOffset(_ x: CGFloat, width: CGFloat, amplitude: CGFloat, phase: Double) -> CGFloat {
        let u = Double(x / max(width, 1))
        let long = sin(u * .pi * 2.4 + time * 1.6 + phase)
        let short = sin(u * .pi * 6.5 - time * 2.3 + phase * 2)
        return amplitude * CGFloat(long * 0.75 + short * 0.3)
    }
}

// MARK: - Canvas にしずく・波紋を描く（落ちる演出・雨・背景で共通）

enum WaterDrawing {
    /// 落ちてくるしずく（上がとがった透明な形）。stretch で縦に伸びる
    static func drawDrop(in context: inout GraphicsContext, center: CGPoint, radius r: CGFloat,
                         stretch: CGFloat = 1, opacity: Double) {
        guard r > 0.3, opacity > 0.01 else { return }
        var c = context
        c.opacity = opacity
        c.translateBy(x: center.x, y: center.y)
        c.scaleBy(x: 1, y: stretch)
        var drop = Path()
        drop.move(to: CGPoint(x: 0, y: -r * 2.1))
        drop.addCurve(to: CGPoint(x: r, y: r * 0.15),
                      control1: CGPoint(x: r * 0.25, y: -r * 1.3), control2: CGPoint(x: r, y: -r * 0.55))
        drop.addArc(center: CGPoint(x: 0, y: r * 0.15), radius: r,
                    startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        drop.addCurve(to: CGPoint(x: 0, y: -r * 2.1),
                      control1: CGPoint(x: -r, y: -r * 0.55), control2: CGPoint(x: -r * 0.25, y: -r * 1.3))
        drop.closeSubpath()
        // 中はほぼ透明。ふちに向かって少し青い
        c.fill(drop, with: .radialGradient(
            Gradient(colors: [DS.Water.tint.opacity(0.05), DS.Water.tint.opacity(0.12), DS.Water.deep.opacity(0.3)]),
            center: CGPoint(x: 0, y: r * 0.1), startRadius: 0, endRadius: r * 1.4))
        // ふちの光
        c.stroke(drop, with: .color(DS.Water.rim.opacity(0.75)), lineWidth: max(0.8, r * 0.12))
        // 内側の映り込み（左上の細長い光と、底の明るさ）
        let spot = CGRect(x: -r * 0.55, y: -r * 0.6, width: r * 0.32, height: r * 0.7)
        c.fill(Ellipse().path(in: spot), with: .color(DS.Water.rim.opacity(0.8)))
        var bottom = Path()
        bottom.addArc(center: CGPoint(x: 0, y: r * 0.15), radius: r * 0.7,
                      startAngle: .degrees(30), endAngle: .degrees(150), clockwise: false)
        c.stroke(bottom, with: .color(DS.Water.rim.opacity(0.4)), style: StrokeStyle(lineWidth: max(0.8, r * 0.14), lineCap: .round))
    }

    /// 水面を斜めから見た波紋（横長の楕円）
    static func drawRipple(in context: inout GraphicsContext, center: CGPoint, radius: CGFloat, opacity: Double) {
        guard radius > 0.5, opacity > 0.01 else { return }
        let rect = CGRect(x: center.x - radius, y: center.y - radius * 0.32, width: radius * 2, height: radius * 0.64)
        context.stroke(Ellipse().path(in: rect), with: .color(DS.Water.rim.opacity(0.8 * opacity)),
                       lineWidth: 1.6 * opacity + 0.4)
    }
}

// MARK: - 深い水の背景（ぼんやり光る色と、ゆっくり落ちる小さなしずく）

struct WaterBackdrop: View {
    var isAnimated: Bool

    private static let ambient: [AmbientDrop] = {
        var seed: UInt64 = 0xD20B
        func next() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double(seed >> 33) / Double(1 << 31)
        }
        return (0..<10).map { _ in
            AmbientDrop(x: next(), radius: 1.6 + next() * 2.4, speed: 10 + next() * 18,
                        offset: next(), opacity: 0.35 + next() * 0.35)
        }
    }()

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                LinearGradient(colors: [DS.Water.deepTop, DS.Water.deepBottom], startPoint: .top, endPoint: .bottom)
                glow(DS.Water.glows[0], diameter: size.width * 0.95, at: CGPoint(x: size.width * 0.02, y: size.height * 0.1), opacity: 0.6)
                glow(DS.Water.glows[1], diameter: size.width * 0.7, at: CGPoint(x: size.width * 0.98, y: size.height * 0.52), opacity: 0.3)
                glow(DS.Water.glows[2], diameter: size.width * 0.85, at: CGPoint(x: size.width * 0.15, y: size.height * 0.96), opacity: 0.45)

                if isAnimated {
                    TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
                        ambientCanvas(time: timeline.date.timeIntervalSinceReferenceDate)
                    }
                } else {
                    ambientCanvas(time: 0)
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func glow(_ color: Color, diameter: CGFloat, at point: CGPoint, opacity: Double) -> some View {
        Circle()
            .fill(color.opacity(opacity))
            .frame(width: diameter, height: diameter)
            .blur(radius: diameter * 0.28)
            .position(point)
    }

    private func ambientCanvas(time: TimeInterval) -> some View {
        Canvas { context, size in
            let travel = size.height + 40
            for drop in Self.ambient {
                let distance = (time * drop.speed + drop.offset * travel).truncatingRemainder(dividingBy: travel)
                WaterDrawing.drawDrop(in: &context, center: CGPoint(x: drop.x * size.width, y: distance - 20),
                                      radius: drop.radius, opacity: drop.opacity)
            }
        }
    }
}

private struct AmbientDrop {
    let x: Double
    let radius: Double
    let speed: Double
    let offset: Double
    let opacity: Double
}
