//
//  ChickViews.swift
//  todoapp
//
//  ひよこのテーマの色・形：卵、割れた殻、ひよこ、生まれるチェック、背景の光の粒。
//  チェックすると卵がゆらゆら揺れて、ひびが入り、上の殻が飛んで、ひよこが顔を出す（ChickHatch）。
//

import SwiftUI

extension DS {
    enum Chick {
        // MARK: 背景
        static let deepTop = Color(fixed: 0x2A2216)
        static let deepBottom = Color(fixed: 0x14100A)
        static let glows: [(Color, Double)] = [
            (Color(fixed: 0xE39A2B), 0.8), (Color(fixed: 0xB86A1E), 0.35), (Color(fixed: 0x8A6A2A), 0.4),
        ]
        static let dust = Color(fixed: 0xFFE7A8)

        // MARK: 卵
        static let shellLight = Color(fixed: 0xFFFDF7)
        static let shellMid = Color(fixed: 0xF8F1E3)
        static let shellDeep = Color(fixed: 0xE3D4B6)
        static let shellLine = Color(fixed: 0xC9B48F)

        // MARK: ひよこ
        static let bodyLight = Color(fixed: 0xFFF3A6)
        static let bodyMid = Color(fixed: 0xFFD84D)
        static let bodyDeep = Color(fixed: 0xEDB01E)
        static let beak = Color(fixed: 0xF08A24)
        static let eye = Color(fixed: 0x3A2A1A)
        static let cheek = Color(fixed: 0xF4A3A8)
        static let tuft = Color(fixed: 0xE9A81A)

        static let glass = GlassTint(
            glassTop: Color(fixed: 0xC9B48A).opacity(0.4), glassBottom: Color(fixed: 0x4A4030).opacity(0.55),
            sphereTint: Color(fixed: 0xFFF6E0), sphereEdge: Color(fixed: 0x6B5A3A),
            filledLight: bodyLight, filledMid: bodyMid, filledDeep: bodyDeep
        )

        // MARK: 動き
        /// 揺れて、割れて、ひよこが出てくるまで
        static let hatchDuration: TimeInterval = 1.15
        /// 外したとき、卵に戻る時間
        static let unhatchDuration: TimeInterval = 0.4
        /// hatchDuration の中で、上の殻が割れて飛ぶところ
        static let splitAt: Double = 0.42
    }
}

// MARK: - 形（frame の正方形の中の割合で描く）

/// 卵の形（上が少し細い）
struct EggShape: Shape {
    func path(in rect: CGRect) -> Path {
        let egg = ChickLayout.egg(in: rect)
        let w = egg.width, h = egg.height
        var p = Path()
        p.move(to: CGPoint(x: egg.midX, y: egg.minY))
        p.addCurve(to: CGPoint(x: egg.maxX, y: egg.minY + h * 0.6),
                   control1: CGPoint(x: egg.midX + w * 0.4, y: egg.minY),
                   control2: CGPoint(x: egg.maxX, y: egg.minY + h * 0.3))
        p.addCurve(to: CGPoint(x: egg.midX, y: egg.maxY),
                   control1: CGPoint(x: egg.maxX, y: egg.minY + h * 0.86),
                   control2: CGPoint(x: egg.midX + w * 0.3, y: egg.maxY))
        p.addCurve(to: CGPoint(x: egg.minX, y: egg.minY + h * 0.6),
                   control1: CGPoint(x: egg.midX - w * 0.3, y: egg.maxY),
                   control2: CGPoint(x: egg.minX, y: egg.minY + h * 0.86))
        p.addCurve(to: CGPoint(x: egg.midX, y: egg.minY),
                   control1: CGPoint(x: egg.minX, y: egg.minY + h * 0.3),
                   control2: CGPoint(x: egg.midX - w * 0.4, y: egg.minY))
        p.closeSubpath()
        return p
    }
}

/// ひびのぎざぎざ（卵の横幅より少し長い）
struct CrackShape: Shape {
    func path(in rect: CGRect) -> Path {
        let egg = ChickLayout.egg(in: rect)
        let y = ChickLayout.crackY(in: rect)
        let teeth = 6
        let amplitude = egg.height * 0.07
        var p = Path()
        let left = egg.minX - egg.width * 0.1, right = egg.maxX + egg.width * 0.1
        p.move(to: CGPoint(x: left, y: y))
        for index in 1...teeth * 2 {
            let x = left + (right - left) * Double(index) / Double(teeth * 2)
            p.addLine(to: CGPoint(x: x, y: y + (index % 2 == 0 ? amplitude : -amplitude)))
        }
        return p
    }
}

/// ひびより下（残る殻）と上（飛ぶ殻）
struct EggHalfShape: Shape {
    let isTop: Bool

    func path(in rect: CGRect) -> Path {
        var region = CrackShape().path(in: rect)
        let crack = region.currentPoint ?? CGPoint(x: rect.maxX, y: rect.midY)
        let far = isTop ? rect.minY - rect.height : rect.maxY + rect.height
        region.addLine(to: CGPoint(x: crack.x + rect.width, y: crack.y))
        region.addLine(to: CGPoint(x: crack.x + rect.width, y: far))
        region.addLine(to: CGPoint(x: rect.minX - rect.width, y: far))
        region.addLine(to: CGPoint(x: rect.minX - rect.width, y: ChickLayout.crackY(in: rect)))
        region.closeSubpath()
        return EggShape().path(in: rect).intersection(region)
    }
}

enum ChickLayout {
    /// 正方形の中の卵の位置（たて長）
    static func egg(in rect: CGRect) -> CGRect {
        let size = min(rect.width, rect.height)
        let w = size * 0.74, h = size * 0.94
        return CGRect(x: rect.midX - w / 2, y: rect.midY - h / 2, width: w, height: h)
    }

    static func crackY(in rect: CGRect) -> CGFloat {
        let egg = egg(in: rect)
        return egg.minY + egg.height * 0.56
    }
}

// MARK: - 部品

/// 殻（つやのある白）
private struct ShellView<S: Shape>: View {
    let shape: S

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                shape.fill(RadialGradient(colors: [DS.Chick.shellLight, DS.Chick.shellMid, DS.Chick.shellDeep],
                                          center: UnitPoint(x: 0.38, y: 0.3), startRadius: 0, endRadius: size * 0.7))
                shape.stroke(DS.Chick.shellLine, lineWidth: max(0.8, size * 0.035))
            }
        }
    }
}

/// 卵のつや（左上の光）
private struct EggShine: View {
    var body: some View {
        GeometryReader { proxy in
            let egg = ChickLayout.egg(in: CGRect(origin: .zero, size: proxy.size))
            Ellipse()
                .fill(.white.opacity(0.9))
                .frame(width: egg.width * 0.22, height: egg.height * 0.14)
                .rotationEffect(.degrees(-30))
                .position(x: egg.minX + egg.width * 0.3, y: egg.minY + egg.height * 0.24)
        }
    }
}

/// ひよこ（まるい頭と、目・くちばし・ほっぺ・頭の毛）
struct ChickBody: View {
    var body: some View {
        Canvas { context, size in
            let s = min(size.width, size.height)
            let ox = (size.width - s) / 2, oy = (size.height - s) / 2
            func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: ox + s * x, y: oy + s * y) }
            func circle(_ x: Double, _ y: Double, _ r: Double) -> Path {
                Path(ellipseIn: CGRect(x: ox + s * (x - r), y: oy + s * (y - r), width: s * r * 2, height: s * r * 2))
            }
            // 頭の毛（3 本の小さなとんがり）
            var tuft = Path()
            tuft.move(to: pt(0.43, 0.12))
            tuft.addLine(to: pt(0.44, 0.02))
            tuft.addLine(to: pt(0.48, 0.08))
            tuft.addLine(to: pt(0.5, -0.01))
            tuft.addLine(to: pt(0.52, 0.08))
            tuft.addLine(to: pt(0.56, 0.02))
            tuft.addLine(to: pt(0.57, 0.12))
            tuft.closeSubpath()
            context.fill(tuft, with: .color(DS.Chick.tuft))

            context.fill(circle(0.5, 0.41, 0.31), with: .radialGradient(
                Gradient(colors: [DS.Chick.bodyLight, DS.Chick.bodyMid, DS.Chick.bodyDeep]),
                center: pt(0.42, 0.28), startRadius: 0, endRadius: s * 0.42))
            context.fill(circle(0.38, 0.37, 0.035), with: .color(DS.Chick.eye))
            context.fill(circle(0.62, 0.37, 0.035), with: .color(DS.Chick.eye))
            context.fill(circle(0.39, 0.362, 0.012), with: .color(.white))
            context.fill(circle(0.63, 0.362, 0.012), with: .color(.white))
            for x in [0.3, 0.7] {
                context.fill(Path(ellipseIn: CGRect(x: ox + s * (x - 0.055), y: oy + s * 0.41, width: s * 0.11, height: s * 0.06)),
                             with: .color(DS.Chick.cheek.opacity(0.7)))
            }
            var beak = Path()
            beak.move(to: pt(0.455, 0.405))
            beak.addLine(to: pt(0.545, 0.405))
            beak.addLine(to: pt(0.5, 0.47))
            beak.closeSubpath()
            context.fill(beak, with: .color(DS.Chick.beak))
        }
    }
}

// MARK: - 生まれるチェック

/// progress 0 で卵、1 で殻から顔を出したひよこ。アニメーションで 0→1 に動かすと、
/// 揺れる → ひびが入る → 上の殻が飛ぶ → ひよこがぴょこっと出る。1→0 では逆に戻る。
struct ChickHatch: View, Animatable {
    var progress: Double

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let split = DS.Chick.splitAt
            let crack = Self.smoothstep(0.18, 0.38, progress)
            let fly = Self.smoothstep(split, split + 0.3, progress)
            let rise = Self.easeOutBack(Self.clamp((progress - split - 0.04) / 0.38))
            // 割れるまで、底を支点にゆらゆら揺れる
            let wobble = progress < split
                ? sin(progress / split * .pi * 5) * 13 * sin(progress / split * .pi)
                : 0

            ZStack {
                ChickBody()
                    .scaleEffect(0.35 + 0.65 * rise, anchor: .bottom)
                    .offset(y: size * 0.08 * (1 - rise))
                    .opacity(progress > split ? 1 : 0)
                if progress <= split {
                    // 割れるまでは、つなぎ目のない 1 つの卵
                    ShellView(shape: EggShape())
                        .overlay { EggShine() }
                } else {
                    ShellView(shape: EggHalfShape(isTop: false))
                    // 上の殻：くるっと回りながら飛んでいく
                    ShellView(shape: EggHalfShape(isTop: true))
                        .overlay { EggShine() }
                        .rotationEffect(.degrees(fly * 70), anchor: .center)
                        .offset(x: size * 0.45 * fly, y: -size * 0.6 * fly + size * 0.5 * fly * fly)
                        .opacity(1 - Self.smoothstep(0.55, 1, fly))
                }
                CrackShape()
                    .trim(from: 0, to: crack)
                    .stroke(DS.Chick.shellLine, style: StrokeStyle(lineWidth: max(0.8, size * 0.035), lineJoin: .round))
                    .opacity(progress > split ? 0 : 1)
                    .mask { EggShape() }
            }
            .rotationEffect(.degrees(wobble), anchor: .bottom)
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }

    private static func clamp(_ x: Double) -> Double { min(max(x, 0), 1) }

    private static func smoothstep(_ a: Double, _ b: Double, _ x: Double) -> Double {
        let t = clamp((x - a) / (b - a))
        return t * t * (3 - 2 * t)
    }

    private static func easeOutBack(_ t: Double) -> Double {
        guard t > 0 else { return 0 }
        let c1 = 2.2, c3 = c1 + 1
        let u = t - 1
        return 1 + c3 * u * u * u + c1 * u * u
    }
}

/// チェック（卵 → ひよこ）。生まれるときはゆっくり、戻すときは速く
struct ChickCheck: View {
    let isCompleted: Bool
    var isAnimated = true

    var body: some View {
        ChickHatch(progress: isCompleted ? 1 : 0)
            .animation(isAnimated
                       ? (isCompleted ? .linear(duration: DS.Chick.hatchDuration) : .easeInOut(duration: DS.Chick.unhatchDuration))
                       : nil,
                       value: isCompleted)
    }
}

// MARK: - 背景の光の粒（ふわふわ昇る）

struct ChickDust: View {
    let time: TimeInterval

    private static let dots = AmbientDot.make(count: 22, seed: 0xC41C)

    var body: some View {
        Canvas { context, size in
            let travel = size.height + 40
            for dot in Self.dots {
                let distance = (time * 9 * dot.speed + dot.y * travel).truncatingRemainder(dividingBy: travel)
                let y = size.height + 20 - distance
                let x = dot.x * size.width + sin(time * 0.6 + dot.phase) * 10
                let r = 1.2 + dot.size * 2.6
                let glow = 0.18 + 0.22 * (0.5 + 0.5 * sin(time * 1.3 * dot.speed + dot.phase))
                context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                             with: .radialGradient(Gradient(colors: [DS.Chick.dust.opacity(glow), DS.Chick.dust.opacity(0)]),
                                                   center: CGPoint(x: x, y: y), startRadius: 0, endRadius: r))
            }
        }
    }
}
