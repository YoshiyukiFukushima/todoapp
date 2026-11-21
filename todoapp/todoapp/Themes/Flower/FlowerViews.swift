//
//  FlowerViews.swift
//  todoapp
//
//  花のテーマの部品：花びらの形、咲くチェック、夜の庭の背景。
//  色・形・速さは花の種類ごとの FlowerSpec から取る（桜・マーガレット）。
//  カードと＋ボタンは泡と同じガラスの形を、花の色（FlowerSpec.glass）で使う。
//

import SwiftUI

// MARK: - 花びらの形（下が付け根）

struct PetalShape: Shape {
    var style: PetalStyle = .notched

    func path(in r: CGRect) -> Path {
        switch style {
        case .notched: notched(in: r)
        case .slender: slender(in: r)
        }
    }

    /// 付け根が細く、先に小さな切れ込み（桜）
    private func notched(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.minX + w * 0.04, y: r.minY + h * 0.34),
                   control1: CGPoint(x: r.midX - w * 0.34, y: r.maxY - h * 0.1),
                   control2: CGPoint(x: r.minX - w * 0.03, y: r.minY + h * 0.58))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY + h * 0.1),
                   control1: CGPoint(x: r.minX + w * 0.1, y: r.minY + h * 0.02),
                   control2: CGPoint(x: r.midX - w * 0.2, y: r.minY - h * 0.04))
        p.addCurve(to: CGPoint(x: r.maxX - w * 0.04, y: r.minY + h * 0.34),
                   control1: CGPoint(x: r.midX + w * 0.2, y: r.minY - h * 0.04),
                   control2: CGPoint(x: r.maxX - w * 0.1, y: r.minY + h * 0.02))
        p.addCurve(to: CGPoint(x: r.midX, y: r.maxY),
                   control1: CGPoint(x: r.maxX + w * 0.03, y: r.minY + h * 0.58),
                   control2: CGPoint(x: r.midX + w * 0.34, y: r.maxY - h * 0.1))
        p.closeSubpath()
        return p
    }

    /// 細長く、先が丸い（マーガレット）
    private func slender(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.minX, y: r.minY + h * 0.3),
                   control1: CGPoint(x: r.midX - w * 0.42, y: r.maxY - h * 0.08),
                   control2: CGPoint(x: r.minX, y: r.minY + h * 0.6))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + h * 0.3),
                   control1: CGPoint(x: r.minX, y: r.minY - h * 0.08),
                   control2: CGPoint(x: r.maxX, y: r.minY - h * 0.08))
        p.addCurve(to: CGPoint(x: r.midX, y: r.maxY),
                   control1: CGPoint(x: r.maxX, y: r.minY + h * 0.6),
                   control2: CGPoint(x: r.midX + w * 0.42, y: r.maxY - h * 0.08))
        p.closeSubpath()
        return p
    }
}

/// 花びらのすじ（桜は付け根から 3 本、細い花びらは真ん中の 1 本）
private struct PetalVeinShape: Shape {
    let style: PetalStyle

    func path(in r: CGRect) -> Path {
        func point(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: r.minX + r.width * x, y: r.minY + r.height * y)
        }
        var p = Path()
        switch style {
        case .notched:
            p.move(to: point(0.5, 0.95))
            p.addLine(to: point(0.5, 0.5))
            p.move(to: point(0.5, 0.9))
            p.addQuadCurve(to: point(0.34, 0.55), control: point(0.38, 0.75))
            p.move(to: point(0.5, 0.9))
            p.addQuadCurve(to: point(0.66, 0.55), control: point(0.62, 0.75))
        case .slender:
            p.move(to: point(0.5, 0.92))
            p.addLine(to: point(0.5, 0.25))
        }
        return p
    }
}

/// 1 枚の花びら（グラデーション・すじ・ふち）
struct PetalView: View {
    let spec: FlowerSpec

    var body: some View {
        ZStack {
            PetalShape(style: spec.petalStyle)
                .fill(LinearGradient(colors: [spec.petalTip, spec.petalBase], startPoint: .top, endPoint: .bottom))
            PetalVeinShape(style: spec.petalStyle)
                .stroke(spec.petalVein.opacity(0.45), lineWidth: 0.7)
            PetalShape(style: spec.petalStyle)
                .stroke(spec.petalEdge.opacity(0.6), lineWidth: 0.8)
        }
    }
}

// MARK: - 咲くチェック（つぼみ → 花びらが 1 枚ずつ開く → 花芯が黄色に）

/// progress 0 でつぼみ、1 で咲ききった花。アニメーションで 0→1 に動かすと、花びらが 1 枚ずつ、
/// ひねりながら大きくなって開き、最後にふわっと戻る。1→0 に動かすと逆の順で閉じる。
struct FlowerBlossom: View, Animatable {
    let kind: FlowerKind
    var progress: Double

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    private var spec: FlowerSpec { kind.spec }

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                ForEach(0..<spec.petalCount, id: \.self) { index in
                    petal(index, size: size)
                }
                center(size: size)
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }

    /// index 番目の花びらの開き具合（0〜1）
    private func petalProgress(_ index: Int) -> Double {
        let start = Double(index) * spec.stagger
        return min(max((progress - start) / spec.span, 0), 1)
    }

    private func petal(_ index: Int, size: CGFloat) -> some View {
        let p = petalProgress(index)
        let grow = Self.easeOutBack(p)
        let length = size * spec.petalLength
        return PetalView(spec: spec)
            .frame(width: size * spec.petalWidth, height: length)
            .scaleEffect(grow, anchor: .bottom)
            // 開きながらひねる
            .rotationEffect(.degrees((1 - p) * spec.twist), anchor: .bottom)
            .offset(y: -length / 2 - size * spec.petalInset)
            // 花全体が回り込みながら開く
            .rotationEffect(.degrees(Double(index) * 360 / Double(spec.petalCount) + (1 - p) * spec.swirl))
            .opacity(min(p * 4, 1))
    }

    /// つぼみ（真珠のような玉）が縮んで、黄色い花芯に変わる
    private func center(size: CGFloat) -> some View {
        let toStamen = Self.smoothstep(0.35, 0.8, progress)
        let checkOpacity = Self.smoothstep(0.7, 0.95, progress)
        let diameter = size * (1 - (1 - spec.stamenSize) * Self.smoothstep(0, 0.45, progress))
        return ZStack {
            BubbleSphere(isFilled: false, tint: spec.glass)
                .opacity(1 - toStamen)
            ZStack {
                Circle().fill(RadialGradient(
                    colors: [spec.stamenLight, spec.stamenMid, spec.stamenDeep],
                    center: UnitPoint(x: 0.38, y: 0.32), startRadius: 0, endRadius: diameter * 0.7))
                if spec.petalStyle == .slender {
                    // マーガレットの花芯は、小さな粒の輪で少しざらっとさせる
                    Circle()
                        .strokeBorder(spec.stamenDeep.opacity(0.5),
                                      style: StrokeStyle(lineWidth: max(1, diameter * 0.08), lineCap: .round,
                                                         dash: [0.1, diameter * 0.12]))
                        .padding(diameter * 0.12)
                }
                Circle().strokeBorder(Color.white.opacity(0.75), lineWidth: max(1, diameter * 0.06))
                Image(systemName: "checkmark")
                    .font(.system(size: diameter * 0.46, weight: .bold, design: .rounded))
                    .foregroundStyle(spec.checkmark)
                    .opacity(checkOpacity)
            }
            .opacity(toStamen)
        }
        .frame(width: diameter, height: diameter)
    }

    /// 少し大きくなりすぎてから戻る（最後にふわっと戻る動き）
    private static func easeOutBack(_ t: Double) -> Double {
        guard t > 0 else { return 0 }
        let c1 = 1.9, c3 = c1 + 1
        let u = t - 1
        return 1 + c3 * u * u * u + c1 * u * u
    }

    private static func smoothstep(_ a: Double, _ b: Double, _ x: Double) -> Double {
        let t = min(max((x - a) / (b - a), 0), 1)
        return t * t * (3 - 2 * t)
    }
}

// MARK: - Canvas に花びらを描く（背景・舞い落ちる演出で共通）

enum FlowerDrawing {
    /// center を中心に、angle だけ回し、flip（-1〜1）で裏返りかけた花びらを 1 枚描く
    static func drawPetal(in context: inout GraphicsContext, spec: FlowerSpec, center: CGPoint, size: CGFloat,
                          angle: Angle, flip: Double, color: Color, opacity: Double) {
        guard size > 0.5, opacity > 0.01 else { return }
        var c = context
        c.opacity = opacity
        c.translateBy(x: center.x, y: center.y)
        c.rotate(by: angle)
        // 裏返りかけでも消えきらないよう、少し幅を残す
        c.scaleBy(x: max(abs(flip), 0.15), y: 1)
        // 細い花びらは少し太めに描く（小さく落ちると線に見えるため）
        let width = size * min(max(spec.petalWidth / spec.petalLength, 0.42), 0.9)
        let rect = CGRect(x: -width / 2, y: -size / 2, width: width, height: size)
        let path = PetalShape(style: spec.petalStyle).path(in: rect)
        c.fill(path, with: .linearGradient(Gradient(colors: [spec.petalTip, color]),
                                           startPoint: CGPoint(x: 0, y: rect.minY),
                                           endPoint: CGPoint(x: 0, y: rect.maxY)))
        c.stroke(path, with: .color(spec.petalEdge.opacity(0.45)), lineWidth: 0.7)
    }
}

// MARK: - 夜の庭の背景（ぼんやり光る色と、ゆっくり舞い落ちる花びら）

struct FlowerBackdrop: View {
    let kind: FlowerKind
    var isAnimated: Bool

    /// 背景で舞う花びら（毎回同じ並びになるよう、決まった値で作る）
    private static let ambient: [AmbientPetal] = {
        var seed: UInt64 = 0xF10E
        func next() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double(seed >> 33) / Double(1 << 31)
        }
        return (0..<11).map { _ in
            AmbientPetal(x: next(), scale: next(), speed: 8 + next() * 14, sway: 10 + next() * 18,
                         spin: (next() - 0.5) * 1.6, phase: next() * .pi * 2, offset: next(),
                         opacity: 0.4 + next() * 0.3, shade: Int(next() * 4))
        }
    }()

    var body: some View {
        let spec = kind.spec
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                LinearGradient(colors: [spec.deepTop, spec.deepBottom], startPoint: .top, endPoint: .bottom)
                glow(spec.glows[0], diameter: size.width * 0.9, at: CGPoint(x: size.width * 0.02, y: size.height * 0.12), opacity: 0.55)
                glow(spec.glows[1], diameter: size.width * 0.75, at: CGPoint(x: size.width * 0.98, y: size.height * 0.5), opacity: 0.4)
                glow(spec.glows[2], diameter: size.width * 0.8, at: CGPoint(x: size.width * 0.2, y: size.height * 0.98), opacity: 0.5)

                if isAnimated {
                    TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
                        ambientCanvas(spec: spec, time: timeline.date.timeIntervalSinceReferenceDate)
                    }
                } else {
                    ambientCanvas(spec: spec, time: 0)
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

    private func ambientCanvas(spec: FlowerSpec, time: TimeInterval) -> some View {
        Canvas { context, size in
            let travel = size.height + 40
            let range = spec.fallingSize
            for petal in Self.ambient {
                let distance = (time * petal.speed + petal.offset * travel).truncatingRemainder(dividingBy: travel)
                let y = distance - 20
                let x = petal.x * size.width + sin(time * 0.5 + petal.phase) * petal.sway
                // 背景の花びらは、降ってくるものより少し小さく
                let petalSize = (range.lowerBound + (range.upperBound - range.lowerBound) * petal.scale) * 0.7
                FlowerDrawing.drawPetal(in: &context, spec: spec, center: CGPoint(x: x, y: y), size: petalSize,
                                        angle: .radians(time * petal.spin + petal.phase),
                                        flip: cos(time * 0.9 + petal.phase),
                                        color: spec.petalShades[petal.shade % spec.petalShades.count],
                                        opacity: petal.opacity)
            }
        }
    }
}

private struct AmbientPetal {
    let x: Double
    /// 大きさ（0〜1。花の種類ごとの大きさの幅の中で決める）
    let scale: Double
    let speed: Double
    let sway: Double
    let spin: Double
    let phase: Double
    let offset: Double
    let opacity: Double
    let shade: Int
}
