//
//  BubbleViews.swift
//  todoapp
//
//  泡のテーマの部品：ガラスの面、シャボン玉、水の中の背景。
//  ガラスの面とシャボン玉は、色（GlassTint）を変えて花のテーマでも使う（花の色は FlowerSpec.glass）。
//

import SwiftUI

// MARK: - ガラスと玉の色

/// ガラスの面・玉の色の組。形は同じで、テーマごとに色だけ変える
struct GlassTint {
    let glassTop: Color
    let glassBottom: Color
    /// 空の玉（未完了のチェック）のふちの色みと奥の色
    let sphereTint: Color
    let sphereEdge: Color
    /// 満ちた玉（完了・＋ボタン）
    let filledLight: Color
    let filledMid: Color
    let filledDeep: Color

    static let bubble = GlassTint(
        glassTop: DS.Bubble.glassTop, glassBottom: DS.Bubble.glassBottom,
        sphereTint: DS.Bubble.tint, sphereEdge: DS.Bubble.sphereEdge,
        filledLight: DS.Bubble.filledLight, filledMid: DS.Bubble.filledMid, filledDeep: DS.Bubble.filledDeep
    )
}

// MARK: - ガラスの面（カード・丸いボタン・選んだタブ）

struct BubbleGlass<S: InsettableShape>: View {
    enum Highlight {
        /// 上の辺に沿った細長い光（カード・カプセル）
        case bar
        /// 左上の小さな光（丸いボタン）
        case spot
        /// 光なし（ウィジェットの細い行など、文字に重なるとき）
        case none
    }

    let shape: S
    var tint: GlassTint = .bubble
    var highlight: Highlight = .bar
    /// 完了したカードなど、控えめにする
    var isDimmed = false

    var body: some View {
        ZStack {
            shape.fill(LinearGradient(colors: [tint.glassTop, tint.glassBottom],
                                      startPoint: .top, endPoint: .bottom))
            shape.strokeBorder(
                LinearGradient(colors: [DS.Bubble.rim.opacity(0.55), DS.Bubble.rim.opacity(0.12), DS.Bubble.rim.opacity(0.4)],
                               startPoint: .top, endPoint: .bottom),
                lineWidth: 1.5
            )
        }
        .overlay { highlightView }
        .opacity(isDimmed ? 0.7 : 1)
    }

    @ViewBuilder
    private var highlightView: some View {
        switch highlight {
        case .bar:
            GeometryReader { proxy in
                Capsule()
                    .fill(LinearGradient(colors: [DS.Bubble.rim.opacity(0.6), DS.Bubble.rim.opacity(0.1)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: proxy.size.width * 0.45, height: 7)
                    .offset(x: DS.Radius.bubbleCard * 0.9, y: 5)
            }
            .allowsHitTesting(false)
        case .spot:
            GeometryReader { proxy in
                Ellipse()
                    .fill(DS.Bubble.rim.opacity(0.55))
                    .frame(width: proxy.size.width * 0.32, height: proxy.size.height * 0.18)
                    .rotationEffect(.degrees(-35))
                    .offset(x: proxy.size.width * 0.16, y: proxy.size.height * 0.14)
            }
            .allowsHitTesting(false)
        case .none:
            EmptyView()
        }
    }
}

// MARK: - シャボン玉（チェック・＋ボタン）

struct BubbleSphere: View {
    /// true: 満ちた青い泡（完了・＋ボタン）／ false: 透きとおった空の泡
    let isFilled: Bool
    var tint: GlassTint = .bubble

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                if isFilled {
                    Circle().fill(RadialGradient(
                        colors: [tint.filledLight, tint.filledMid, tint.filledDeep],
                        center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: size * 0.75))
                } else {
                    Circle().fill(RadialGradient(
                        colors: [DS.Bubble.rim.opacity(0.45), tint.sphereTint.opacity(0.25), tint.sphereEdge.opacity(0.7)],
                        center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: size * 0.75))
                }
                Circle().strokeBorder(
                    LinearGradient(colors: [DS.Bubble.rim.opacity(0.85), DS.Bubble.rim.opacity(0.3)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: max(1, size * 0.045))
                // 左上の光
                Ellipse()
                    .fill(DS.Bubble.rim.opacity(0.85))
                    .frame(width: size * 0.34, height: size * 0.2)
                    .rotationEffect(.degrees(-35))
                    .offset(x: -size * 0.17, y: -size * 0.22)
                // 右下の照り返し
                Circle()
                    .trim(from: 0.05, to: 0.2)
                    .stroke(DS.Bubble.rim.opacity(0.35), style: StrokeStyle(lineWidth: max(1, size * 0.05), lineCap: .round))
                    .padding(size * 0.14)
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }
}

// MARK: - Canvas に泡を描く（背景・はじける演出で共通）

enum BubbleDrawing {
    static func draw(in context: inout GraphicsContext, center: CGPoint, radius r: CGFloat, opacity o: Double) {
        guard r > 0.3, o > 0.01 else { return }
        let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
        let circle = Circle().path(in: rect)
        context.fill(circle, with: .radialGradient(
            Gradient(colors: [DS.Bubble.rim.opacity(0.04 * o), DS.Bubble.tint.opacity(0.12 * o), DS.Bubble.tint.opacity(0.4 * o)]),
            center: center, startRadius: 0, endRadius: r))
        context.stroke(circle, with: .color(DS.Bubble.rim.opacity(0.7 * o)), lineWidth: max(0.7, r * 0.1))
        let spot = CGRect(x: center.x - r * 0.6, y: center.y - r * 0.62, width: r * 0.5, height: r * 0.32)
        context.fill(Ellipse().path(in: spot), with: .color(DS.Bubble.rim.opacity(0.85 * o)))
    }
}

// MARK: - 水の中の背景（ぼんやり光る色と、ゆっくり昇る泡）

struct BubbleBackdrop: View {
    var isAnimated: Bool

    /// 背景で昇る泡（毎回同じ並びになるよう、決まった値で作る）
    private static let ambient: [AmbientBubble] = {
        var seed: UInt64 = 0x5EED
        func next() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double(seed >> 33) / Double(1 << 31)
        }
        return (0..<16).map { _ in
            AmbientBubble(x: next(), radius: 2 + next() * 6, speed: 10 + next() * 22,
                          wobble: 3 + next() * 8, phase: next() * .pi * 2, offset: next(), opacity: 0.35 + next() * 0.35)
        }
    }()

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                LinearGradient(colors: [DS.Bubble.deepTop, DS.Bubble.deepBottom], startPoint: .top, endPoint: .bottom)
                glow(DS.Bubble.glowBlue, diameter: size.width * 0.9, at: CGPoint(x: size.width * 0.05, y: size.height * 0.18), opacity: 0.55)
                glow(DS.Bubble.glowViolet, diameter: size.width * 0.8, at: CGPoint(x: size.width * 1.0, y: size.height * 0.48), opacity: 0.5)
                glow(DS.Bubble.glowGreen, diameter: size.width * 0.75, at: CGPoint(x: size.width * 0.15, y: size.height * 0.95), opacity: 0.45)

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
            for bubble in Self.ambient {
                let distance = (time * bubble.speed + bubble.offset * travel).truncatingRemainder(dividingBy: travel)
                let y = size.height + 20 - distance
                let x = bubble.x * size.width + sin(time * 0.8 + bubble.phase) * bubble.wobble
                BubbleDrawing.draw(in: &context, center: CGPoint(x: x, y: y), radius: bubble.radius, opacity: bubble.opacity)
            }
        }
    }
}

private struct AmbientBubble {
    let x: Double
    let radius: Double
    let speed: Double
    let wobble: Double
    let phase: Double
    let offset: Double
    let opacity: Double
}
