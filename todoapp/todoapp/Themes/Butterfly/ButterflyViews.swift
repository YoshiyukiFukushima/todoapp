//
//  ButterflyViews.swift
//  todoapp
//
//  ちょうちょのテーマの色・形：ちょうちょ、さなぎ、羽化するチェック、カードの右端にとまるちょうちょ、背景の花粉。
//  チェックすると、さなぎが揺れてひびが入り、割れてちょうちょが羽を広げる（ButterflyHatch）。
//  そのままひらひら飛んで、カードの右端にとまり、ゆっくり羽ばたき続ける（ButterflyPerch）。
//  終えたタスクの数だけちょうちょが並ぶ（完了したあとも何かが残るのは、このテーマだけ）。
//  チェックを外すと、ちょうちょは飛んでいく（ButterflyEffects）。
//  ウィジェットでも使う（チェックと背景。ウィジェットではちょうちょをチェックの中に描く）。
//

import SwiftUI

extension DS {
    enum Butterfly {
        // MARK: 背景（夕暮れの野原）
        static let deepTop = Color(fixed: 0x24264A)
        static let deepBottom = Color(fixed: 0x12201A)
        static let glows: [(Color, Double)] = [
            (Color(fixed: 0xB59CF0), 0.42), (Color(fixed: 0xF2D16B), 0.28), (Color(fixed: 0x7BC67E), 0.36),
        ]
        static let pollen = Color(fixed: 0xFFF1B0)

        // MARK: さなぎ
        static let pupaLight = Color(fixed: 0xD8F0BE)
        static let pupaMid = Color(fixed: 0x9CCB7A)
        static let pupaDeep = Color(fixed: 0x5E8F45)
        static let pupaGold = Color(fixed: 0xF2C94C)
        static let silk = Color(fixed: 0xEDEAE0)
        static let body = Color(fixed: 0x2A2230)

        static let glass = GlassTint(
            glassTop: Color(fixed: 0xC3B8E6).opacity(0.32), glassBottom: Color(fixed: 0x3A3A60).opacity(0.5),
            sphereTint: Color(fixed: 0xF5F2FF), sphereEdge: Color(fixed: 0x56568A),
            filledLight: Color(fixed: 0xD8CCFF), filledMid: Color(fixed: 0x9B87E0), filledDeep: Color(fixed: 0x6A55B8)
        )

        // MARK: 動き
        /// さなぎが揺れて、割れて、羽を広げるまで（チェックの中の動き）
        static let hatchDuration: TimeInterval = 1.35
        /// hatchDuration の中で、さなぎが割れるところ
        static let splitAt: Double = 0.44
        /// hatchDuration の中で、ちょうちょがチェックから飛び立つところ（ここから先は ButterflyPerch が描く）
        static let takeoffAt: Double = 0.93
        static var takeoffDelay: TimeInterval { hatchDuration * takeoffAt }
        /// チェックから、カードの右端にとまるまで
        static let flightDuration: TimeInterval = 1.4
        /// チェックを外したとき、飛んでいって見えなくなるまで
        static let leaveDuration: TimeInterval = 1.6
        /// とまっているちょうちょの大きさ
        static let perchSize: CGFloat = 28
        /// カードの右端から、とまる場所までの距離
        static let perchInset: CGFloat = 24
    }
}

// MARK: - 羽の色（タスクごとに決まる）

struct ButterflyPalette: Equatable {
    let light: Color
    let mid: Color
    let deep: Color
    /// 羽のふち
    let edge: Color

    static let all: [ButterflyPalette] = [
        // るり色
        ButterflyPalette(light: Color(fixed: 0x9EDCFF), mid: Color(fixed: 0x3592E6), deep: Color(fixed: 0x1A4590), edge: Color(fixed: 0x111A3A)),
        // だいだい色
        ButterflyPalette(light: Color(fixed: 0xFFD596), mid: Color(fixed: 0xF28C28), deep: Color(fixed: 0xB5541A), edge: Color(fixed: 0x2C1A10)),
        // 黄色
        ButterflyPalette(light: Color(fixed: 0xFFF6B8), mid: Color(fixed: 0xF5D33F), deep: Color(fixed: 0xC49A1C), edge: Color(fixed: 0x3A2E10)),
        // 桃色
        ButterflyPalette(light: Color(fixed: 0xFFD8EB), mid: Color(fixed: 0xF28BC2), deep: Color(fixed: 0xBD528C), edge: Color(fixed: 0x3A1630)),
        // 白
        ButterflyPalette(light: Color(fixed: 0xFFFFFF), mid: Color(fixed: 0xEDEFF8), deep: Color(fixed: 0xB9C0D6), edge: Color(fixed: 0x3A3F55)),
    ]

    static func pick(seed: UInt64) -> ButterflyPalette {
        var random = ThemeSeed(seed ^ 0xB077)
        return all[Int(random.next() * Double(all.count)) % all.count]
    }
}

// MARK: - ちょうちょを描く

enum ButterflyDrawing {
    /// 上から見たちょうちょ（頭が上）を、center を中心に side の大きさで描く。
    /// open は羽の開き具合（1 で広げきり、0 に近いほど閉じて細く見える）
    static func draw(in context: GraphicsContext, center: CGPoint, side: Double, open: Double,
                     palette: ButterflyPalette, angle: Double = 0) {
        var c = context
        c.translateBy(x: center.x, y: center.y)
        c.rotate(by: .radians(angle))
        let s = side
        let o = max(open, 0.08)

        for direction in [-1.0, 1.0] {
            var wing = c
            wing.scaleBy(x: direction * o, y: 1)
            // 前の羽（大きい）
            var fore = Path()
            fore.move(to: CGPoint(x: s * 0.02, y: -s * 0.06))
            fore.addCurve(to: CGPoint(x: s * 0.47, y: -s * 0.36),
                          control1: CGPoint(x: s * 0.12, y: -s * 0.3), control2: CGPoint(x: s * 0.34, y: -s * 0.44))
            fore.addCurve(to: CGPoint(x: s * 0.03, y: s * 0.03),
                          control1: CGPoint(x: s * 0.56, y: -s * 0.2), control2: CGPoint(x: s * 0.36, y: s * 0.02))
            fore.closeSubpath()
            // 後ろの羽（小さく、少し下へ垂れる）
            var hind = Path()
            hind.move(to: CGPoint(x: s * 0.02, y: s * 0.02))
            hind.addCurve(to: CGPoint(x: s * 0.36, y: s * 0.14),
                          control1: CGPoint(x: s * 0.16, y: -s * 0.02), control2: CGPoint(x: s * 0.36, y: s * 0.02))
            hind.addCurve(to: CGPoint(x: s * 0.03, y: s * 0.2),
                          control1: CGPoint(x: s * 0.36, y: s * 0.36), control2: CGPoint(x: s * 0.12, y: s * 0.4))
            hind.closeSubpath()
            let shading = GraphicsContext.Shading.radialGradient(
                Gradient(colors: [palette.light, palette.mid, palette.deep]),
                center: CGPoint(x: s * 0.06, y: 0), startRadius: 0, endRadius: s * 0.5)
            wing.fill(hind, with: shading)
            wing.fill(fore, with: shading)
            let line = max(0.6, s * 0.03)
            wing.stroke(hind, with: .color(palette.edge), lineWidth: line)
            wing.stroke(fore, with: .color(palette.edge), lineWidth: line)
            // 羽の先の白い点
            for (x, y, r) in [(0.4, -0.3, 0.035), (0.32, -0.36, 0.028), (0.3, 0.2, 0.03)] as [(Double, Double, Double)] {
                wing.fill(Path(ellipseIn: CGRect(x: s * (x - r), y: s * (y - r), width: s * r * 2, height: s * r * 2)),
                          with: .color(.white.opacity(0.85)))
            }
        }
        // 胴と触角
        c.fill(Path(roundedRect: CGRect(x: -s * 0.035, y: -s * 0.16, width: s * 0.07, height: s * 0.36), cornerRadius: s * 0.035),
               with: .color(DS.Butterfly.body))
        var antennae = Path()
        for direction in [-1.0, 1.0] {
            antennae.move(to: CGPoint(x: s * 0.01 * direction, y: -s * 0.15))
            antennae.addQuadCurve(to: CGPoint(x: s * 0.12 * direction, y: -s * 0.33),
                                  control: CGPoint(x: s * 0.02 * direction, y: -s * 0.3))
        }
        c.stroke(antennae, with: .color(DS.Butterfly.body), style: StrokeStyle(lineWidth: max(0.6, s * 0.022), lineCap: .round))
        for direction in [-1.0, 1.0] {
            let r = s * 0.025
            c.fill(Path(ellipseIn: CGRect(x: s * 0.12 * direction - r, y: -s * 0.33 - r, width: r * 2, height: r * 2)),
                   with: .color(DS.Butterfly.body))
        }
    }
}

/// ちょうちょ 1 匹（設定の見本・ウィジェットで使う、止まった絵）
struct ButterflyView: View {
    let palette: ButterflyPalette
    var open: Double = 1

    var body: some View {
        Canvas { context, size in
            ButterflyDrawing.draw(in: context, center: CGPoint(x: size.width / 2, y: size.height / 2),
                                  side: min(size.width, size.height), open: open, palette: palette)
        }
    }
}

// MARK: - 羽化するチェック

/// progress 0 でぶら下がったさなぎ、1 でちょうちょが飛び立ったあとの抜け殻。アニメーションで 0→1 に動かすと、
/// さなぎが揺れる → ひびが入る → 割れる → ちょうちょが羽を広げる → 飛び立つ（ここで消える）。
struct ButterflyHatch: View, Animatable {
    var progress: Double
    let palette: ButterflyPalette
    /// 飛び立たずに、チェックの中にとまったままにする（ウィジェット）
    var keepsButterfly = false

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        Canvas { context, size in
            Self.draw(progress: progress, palette: palette, keepsButterfly: keepsButterfly, in: context, size: size)
        }
    }

    static func draw(progress p: Double, palette: ButterflyPalette, keepsButterfly: Bool,
                     in context: GraphicsContext, size: CGSize) {
        let s = min(size.width, size.height)
        let ox = (size.width - s) / 2, oy = (size.height - s) / 2
        func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: ox + s * x, y: oy + s * y) }
        let b = DS.Butterfly.self
        let split = b.splitAt

        // まるい枠（タップできる場所の目印）
        let frame = Path(ellipseIn: CGRect(x: ox, y: oy, width: s, height: s))
        context.fill(frame, with: .radialGradient(Gradient(colors: [Color.white.opacity(0.14), Color.white.opacity(0.03)]),
                                                  center: pt(0.4, 0.3), startRadius: 0, endRadius: s * 0.7))
        context.stroke(frame, with: .color(.white.opacity(0.45)), lineWidth: max(0.8, s * 0.03))

        // 割れるまで、糸を支点にゆらゆら揺れる（だんだん強く）
        let wobble = p < split ? sin(p / split * .pi * 6) * 14 * Ease.smoothstep(0, split, p) * (p > 0 ? 1 : 0) : 0
        let anchor = pt(0.5, 0.1)
        var hang = context
        hang.translateBy(x: anchor.x, y: anchor.y)
        hang.rotate(by: .degrees(wobble))
        hang.translateBy(x: -anchor.x, y: -anchor.y)

        // 糸
        var silk = Path()
        silk.move(to: pt(0.5, 0.04))
        silk.addLine(to: pt(0.5, 0.18))
        context.stroke(silk, with: .color(b.silk.opacity(0.8)), lineWidth: max(0.6, s * 0.02))

        // さなぎ（割れたあとは左右に開いた抜け殻）
        let opened = Ease.smoothstep(split, split + 0.12, p)
        for direction in [-1.0, 1.0] {
            var half = Path()
            half.move(to: pt(0.5, 0.16))
            half.addCurve(to: pt(0.5 + 0.2 * direction, 0.5),
                          control1: pt(0.5 + 0.12 * direction, 0.18), control2: pt(0.5 + 0.22 * direction, 0.34))
            half.addCurve(to: pt(0.5, 0.88),
                          control1: pt(0.5 + 0.18 * direction, 0.68), control2: pt(0.5 + 0.06 * direction, 0.82))
            half.closeSubpath()
            var c = hang
            if opened > 0 {
                // 抜け殻：糸の付け根を支点に、左右へぱかっと開いて、少し透ける
                let top = pt(0.5, 0.16)
                c.translateBy(x: top.x + s * 0.05 * direction * opened, y: top.y)
                // 上を支点に時計回りに回すと下の端は左へ動くので、左の殻は時計回り、右の殻は反時計回り
                c.rotate(by: .degrees(-16 * direction * opened))
                c.translateBy(x: -top.x, y: -top.y)
                c.opacity = 1 - 0.55 * opened
            }
            c.fill(half, with: .linearGradient(Gradient(colors: [b.pupaLight, b.pupaMid, b.pupaDeep]),
                                               startPoint: pt(0.5 + 0.2 * direction, 0.3), endPoint: pt(0.5 - 0.05 * direction, 0.8)))
            c.stroke(half, with: .color(b.pupaDeep), lineWidth: max(0.6, s * 0.02))
        }
        if opened == 0 {
            // 金色の点
            for (x, y) in [(0.42, 0.34), (0.5, 0.31), (0.58, 0.34)] as [(Double, Double)] {
                let r = s * 0.025
                hang.fill(Path(ellipseIn: CGRect(x: ox + s * x - r, y: oy + s * y - r, width: r * 2, height: r * 2)),
                          with: .color(b.pupaGold))
            }
            // つや
            hang.fill(Path(ellipseIn: CGRect(x: ox + s * 0.4, y: oy + s * 0.42, width: s * 0.06, height: s * 0.16)),
                      with: .color(.white.opacity(0.5)))
            // ひび（上から下へ走る）
            let crack = Ease.smoothstep(0.26, split, p)
            if crack > 0 {
                var line = Path()
                let steps = 6
                line.move(to: pt(0.5, 0.2))
                for i in 1...steps {
                    let k = Double(i) / Double(steps)
                    guard k <= crack else { break }
                    line.addLine(to: pt(0.5 + (i % 2 == 0 ? -0.03 : 0.03), 0.2 + 0.6 * k))
                }
                hang.stroke(line, with: .color(b.pupaDeep), style: StrokeStyle(lineWidth: max(0.8, s * 0.03), lineJoin: .round))
            }
        }

        // ちょうちょ：割れめから出て、くしゃっとした羽を広げ、飛び立つ
        let emerge = Ease.smoothstep(split + 0.02, 0.82, p)
        let visible = keepsButterfly ? emerge > 0 : (emerge > 0 && p < b.takeoffAt)
        if visible {
            let lift = keepsButterfly ? 0 : Ease.smoothstep(0.82, b.takeoffAt, p)
            let open = 0.12 + 0.88 * Ease.smoothstep(0.3, 1, emerge)
            let flutter = lift > 0 ? 0.6 + 0.4 * abs(sin(p * 60)) : 1
            ButterflyDrawing.draw(in: context, center: pt(0.5, 0.52 - 0.12 * lift),
                                  side: s * (0.45 + 0.5 * Ease.outBack(emerge, overshoot: 1.2)),
                                  open: open * flutter, palette: palette)
        }
    }
}

struct ButterflyCheck: View {
    let isCompleted: Bool
    let palette: ButterflyPalette
    var isAnimated = true
    var keepsButterfly = false

    var body: some View {
        ButterflyHatch(progress: isCompleted ? 1 : 0, palette: palette, keepsButterfly: keepsButterfly)
            // 外すときは、ちょうちょはカードから飛んでいくので、さなぎにすっと戻す（逆再生でちょうちょを出さない）
            .animation(isAnimated && isCompleted ? .linear(duration: DS.Butterfly.hatchDuration) : nil, value: isCompleted)
    }
}

// MARK: - カードの右端にとまるちょうちょ

/// 終えたタスクのカードの右端にとまって、ゆっくり羽ばたき続ける。
/// flightStart があれば、チェックから飛んできてとまる（その前はさなぎから羽化している）。
struct ButterflyPerch: View {
    let palette: ButterflyPalette
    /// チェックした時刻（飛んでくる動きを見せるとき）。nil ならはじめからとまっている
    let flightStart: Date?
    /// チェックのまん中（カードの中の座標）
    let from: CGPoint
    /// 羽ばたきを見せるか（動きを減らす設定では止めた絵）
    let isAnimated: Bool
    /// タスクごとに羽ばたきの速さとタイミングをずらす
    let phase: Double

    /// 飛んでいるあいだはカードの上へはみ出すので、描く場所をカードより広くとる
    private static let margin: CGFloat = 60

    var body: some View {
        GeometryReader { proxy in
            let perch = CGPoint(x: proxy.size.width - DS.Butterfly.perchInset, y: proxy.size.height / 2)
            Group {
                if isAnimated {
                    TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
                        canvas(perch: perch, now: timeline.date)
                    }
                } else {
                    canvas(perch: perch, now: nil)
                }
            }
            .frame(width: proxy.size.width + Self.margin * 2, height: proxy.size.height + Self.margin * 2)
            .offset(x: -Self.margin, y: -Self.margin)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func canvas(perch: CGPoint, now: Date?) -> some View {
        Canvas { base, _ in
            var context = base
            context.translateBy(x: Self.margin, y: Self.margin)
            let side = Double(DS.Butterfly.perchSize)
            guard let now else {
                ButterflyDrawing.draw(in: context, center: perch, side: side, open: 0.85, palette: palette, angle: -0.2)
                return
            }
            let time = now.timeIntervalSinceReferenceDate
            let flying = flightStart.map { now.timeIntervalSince($0) - DS.Butterfly.takeoffDelay } ?? .infinity
            if flying < 0 { return }
            if flying < DS.Butterfly.flightDuration {
                // ひらひら：ふわっと上へ弧を描き、羽を速く打ちながら、上下に揺れて近づく
                let k = Ease.smoothstep(0, 1, flying / DS.Butterfly.flightDuration)
                let c1 = CGPoint(x: from.x + 50, y: from.y - 56)
                let c2 = CGPoint(x: perch.x - 40, y: perch.y - 60)
                let v = 1 - k
                let x = v * v * v * from.x + 3 * v * v * k * c1.x + 3 * v * k * k * c2.x + k * k * k * perch.x
                let y = v * v * v * from.y + 3 * v * v * k * c1.y + 3 * v * k * k * c2.y + k * k * k * perch.y
                let bob = sin(flying * 13) * 4 * (1 - k)
                let open = 0.25 + 0.75 * abs(sin(flying * 16))
                let tilt = 0.5 * (1 - k) - 0.2 * k + sin(flying * 7) * 0.15 * (1 - k)
                ButterflyDrawing.draw(in: context, center: CGPoint(x: x, y: y + bob), side: side * (0.8 + 0.2 * k),
                                      open: open, palette: palette, angle: tilt)
            } else {
                // とまって、ゆっくり羽を開いたり閉じたり
                let breathe = 0.5 + 0.5 * cos(time * 2.1 * (0.85 + 0.3 * phase) + phase * 6)
                ButterflyDrawing.draw(in: context, center: perch, side: side, open: 0.35 + 0.6 * breathe,
                                      palette: palette, angle: -0.2)
            }
        }
    }
}

// MARK: - 背景の花粉（ふわふわ漂う）

struct ButterflyPollen: View {
    let time: TimeInterval

    private static let dots = AmbientDot.make(count: 20, seed: 0xB0770)

    var body: some View {
        Canvas { context, size in
            for dot in Self.dots {
                let x = (dot.x + 0.04 * sin(time * 0.23 * dot.speed + dot.phase)) * size.width
                let y = (dot.y + 0.03 * cos(time * 0.31 * dot.speed + dot.phase * 2)) * size.height
                let r = 1.2 + dot.size * 2.4
                let glow = 0.15 + 0.25 * (0.5 + 0.5 * sin(time * 1.1 * dot.speed + dot.phase))
                context.fill(Path(ellipseIn: CGRect(x: x - r * 2, y: y - r * 2, width: r * 4, height: r * 4)),
                             with: .radialGradient(Gradient(colors: [DS.Butterfly.pollen.opacity(glow), DS.Butterfly.pollen.opacity(0)]),
                                                   center: CGPoint(x: x, y: y), startRadius: 0, endRadius: r * 2))
            }
        }
    }
}
