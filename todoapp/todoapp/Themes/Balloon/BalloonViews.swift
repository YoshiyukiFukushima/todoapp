//
//  BalloonViews.swift
//  todoapp
//
//  風船のテーマの色・形：風船、ふくらんで割れるチェック、背景の小さな風船。
//  チェックすると、しぼんだ風船がぐらぐら揺れながらふくらみ、パンッと割れて、チェックが残る（BalloonInflate）。
//  割れたときに飛び散るゴムの破片・紙吹雪・落ちていくひもは BalloonEffects が描く。
//  ウィジェットでも使う（チェックと背景）。
//

import SwiftUI

extension DS {
    enum Balloon {
        // MARK: 背景（夕暮れの空）
        static let deepTop = Color(fixed: 0x23264A)
        static let deepBottom = Color(fixed: 0x2B1730)
        static let glows: [(Color, Double)] = [
            (Color(fixed: 0xF0997B), 0.5), (Color(fixed: 0x5DCAA5), 0.3), (Color(fixed: 0xD4537E), 0.45),
        ]
        static let string = Color(fixed: 0xE8E2F0)

        static let glass = GlassTint(
            glassTop: Color(fixed: 0xB8B4D8).opacity(0.34), glassBottom: Color(fixed: 0x3F3560).opacity(0.5),
            sphereTint: Color(fixed: 0xF4F0FF), sphereEdge: Color(fixed: 0x5A5080),
            filledLight: Color(fixed: 0xFFB3AA), filledMid: Color(fixed: 0xF0524A), filledDeep: Color(fixed: 0xC23A33)
        )

        // MARK: 動き
        /// ふくらみはじめてから、チェックが落ち着くまで
        static let duration: TimeInterval = 1.0
        /// duration の中で、パンッと割れるところ
        static let popAt: Double = 0.62
        /// タップしてから割れるまで
        static var popDelay: TimeInterval { duration * popAt }
    }
}

// MARK: - 風船の色（タスクごとに決まる）

struct BalloonColor: Equatable {
    let light: Color
    let mid: Color
    let deep: Color

    static let all: [BalloonColor] = [
        BalloonColor(light: Color(fixed: 0xFFA49D), mid: Color(fixed: 0xF0524A), deep: Color(fixed: 0xB8322C)),
        BalloonColor(light: Color(fixed: 0xFFE69A), mid: Color(fixed: 0xF7C33C), deep: Color(fixed: 0xC9921A)),
        BalloonColor(light: Color(fixed: 0xA9C8FF), mid: Color(fixed: 0x4F8EF7), deep: Color(fixed: 0x2C5FC0)),
        BalloonColor(light: Color(fixed: 0xA8E8BC), mid: Color(fixed: 0x45B86A), deep: Color(fixed: 0x2A8A4A)),
        BalloonColor(light: Color(fixed: 0xFFC2DD), mid: Color(fixed: 0xF27BB0), deep: Color(fixed: 0xC04C82)),
    ]

    static func pick(seed: UInt64) -> BalloonColor {
        var random = ThemeSeed(seed ^ 0xBA11)
        return all[Int(random.next() * Double(all.count)) % all.count]
    }
}

// MARK: - 形

/// 風船（上がまるく、下が少しすぼまって結び目へ）。rect いっぱいに描く。結び目は下のまん中
struct BalloonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let knot = CGPoint(x: rect.midX, y: rect.maxY)
        var p = Path()
        p.move(to: knot)
        p.addCurve(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.42),
                   control1: CGPoint(x: rect.midX - w * 0.22, y: rect.maxY - h * 0.08),
                   control2: CGPoint(x: rect.minX, y: rect.minY + h * 0.7))
        p.addCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                   control1: CGPoint(x: rect.minX, y: rect.minY + h * 0.16),
                   control2: CGPoint(x: rect.midX - w * 0.3, y: rect.minY))
        p.addCurve(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.42),
                   control1: CGPoint(x: rect.midX + w * 0.3, y: rect.minY),
                   control2: CGPoint(x: rect.maxX, y: rect.minY + h * 0.16))
        p.addCurve(to: knot,
                   control1: CGPoint(x: rect.maxX, y: rect.minY + h * 0.7),
                   control2: CGPoint(x: rect.midX + w * 0.22, y: rect.maxY - h * 0.08))
        p.closeSubpath()
        return p
    }
}

/// 風船の絵（つやと結び目つき）
struct BalloonBody: View {
    let color: BalloonColor

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width, h = proxy.size.height
            let bodyRect = CGRect(x: 0, y: 0, width: w, height: h * 0.9)
            ZStack(alignment: .topLeading) {
                BalloonShape()
                    .fill(RadialGradient(colors: [color.light, color.mid, color.deep],
                                         center: UnitPoint(x: 0.36, y: 0.3), startRadius: 0, endRadius: max(w, h) * 0.75))
                    .frame(width: bodyRect.width, height: bodyRect.height)
                // つや
                Ellipse()
                    .fill(.white.opacity(0.75))
                    .frame(width: w * 0.2, height: h * 0.16)
                    .rotationEffect(.degrees(-30))
                    .position(x: w * 0.32, y: h * 0.24)
                // 結び目
                Path { p in
                    p.move(to: CGPoint(x: w * 0.5, y: h * 0.88))
                    p.addLine(to: CGPoint(x: w * 0.42, y: h))
                    p.addLine(to: CGPoint(x: w * 0.58, y: h))
                    p.closeSubpath()
                }
                .fill(color.deep)
            }
        }
    }
}

// MARK: - ふくらんで割れるチェック

/// progress 0 でしぼんだ風船、1 で割れたあとのチェック。アニメーションで 0→1 に動かすと、
/// ぐらぐら揺れながらふくらむ → パンッと消える → チェックがぽんと出る。
struct BalloonInflate: View, Animatable {
    var progress: Double
    let color: BalloonColor

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let popAt = DS.Balloon.popAt
            let grow = Ease.clamp(progress / popAt)
            // ふくらむほど揺れが大きく、速くなる
            let shake = sin(grow * .pi * 9) * (4 + 12 * grow) * (progress > 0 ? 1 : 0)
            let breathe = 1 + 0.05 * sin(grow * .pi * 12) * grow
            let scale = 0.58 + 0.62 * Ease.outCubic(grow)
            let check = Ease.outBack((progress - popAt) / (1 - popAt), overshoot: 2.2)

            ZStack {
                if progress < popAt {
                    BubbleSphere(isFilled: false, tint: DS.Balloon.glass)
                        .opacity(1 - grow)
                    // ひも（結び目から下へ）
                    Path { p in
                        p.move(to: CGPoint(x: size * 0.5, y: size * 0.86))
                        p.addQuadCurve(to: CGPoint(x: size * 0.5, y: size * 1.05),
                                       control: CGPoint(x: size * 0.56, y: size * 0.96))
                    }
                    .stroke(DS.Balloon.string.opacity(0.8), lineWidth: max(0.8, size * 0.03))
                    BalloonBody(color: color)
                        .frame(width: size * 0.62, height: size * 0.76)
                        .scaleEffect(x: scale * breathe, y: scale / breathe, anchor: .bottom)
                        .rotationEffect(.degrees(shake), anchor: .bottom)
                        .position(x: size * 0.5, y: size * 0.86 - size * 0.38)
                } else {
                    Circle()
                        .fill(RadialGradient(colors: [color.light, color.mid, color.deep],
                                             center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: size * 0.75))
                        .scaleEffect(check)
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.46, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(check)
                }
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }
}

struct BalloonCheck: View {
    let isCompleted: Bool
    let color: BalloonColor
    var isAnimated = true

    var body: some View {
        BalloonInflate(progress: isCompleted ? 1 : 0, color: color)
            .animation(isAnimated ? (isCompleted ? .linear(duration: DS.Balloon.duration) : .easeOut(duration: 0.25)) : nil,
                       value: isCompleted)
    }
}

// MARK: - 背景の小さな風船（ゆっくり昇る）

struct BalloonSky: View {
    let time: TimeInterval

    private static let dots = AmbientDot.make(count: 9, seed: 0xBA1100)

    var body: some View {
        Canvas { context, size in
            let travel = size.height + 80
            for (index, dot) in Self.dots.enumerated() {
                let distance = (time * 7 * dot.speed + dot.y * travel).truncatingRemainder(dividingBy: travel)
                let y = size.height + 40 - distance
                let x = dot.x * size.width + sin(time * 0.4 + dot.phase) * 14
                let w = 10 + dot.size * 10, h = w * 1.22
                let color = BalloonColor.all[index % BalloonColor.all.count]
                let rect = CGRect(x: x - w / 2, y: y - h, width: w, height: h)
                context.fill(BalloonShape().path(in: rect), with: .color(color.mid.opacity(0.16)))
                var string = Path()
                string.move(to: CGPoint(x: x, y: y))
                string.addQuadCurve(to: CGPoint(x: x, y: y + h * 0.9), control: CGPoint(x: x + 4 * sin(time + dot.phase), y: y + h * 0.45))
                context.stroke(string, with: .color(DS.Balloon.string.opacity(0.1)), lineWidth: 0.8)
            }
        }
    }
}
